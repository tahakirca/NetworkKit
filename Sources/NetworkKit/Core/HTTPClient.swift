//
//  HTTPClient.swift
//  NetworkKit
//
//  Created by Taha Kırca on 9.04.2026.
//

import Foundation

public final class HTTPClient: Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let interceptors: [any Interceptor]
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        interceptors: [any Interceptor] = [],
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
    ) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors
        self.decoder = decoder
        self.encoder = encoder
    }
    
    // MARK: - Decoded Response
    
    public func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint
    ) async throws -> T {
        let response = try await performRequest(endpoint: endpoint)
        do {
            return try decoder.decode(T.self, from: response.data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error, data: response.data)
        }
    }
    
    // MARK: - Raw Response
    
    public func requestRaw(
        _ endpoint: Endpoint
    ) async throws -> NetworkResponse {
        try await performRequest(endpoint: endpoint)
    }
    
    // MARK: - Void Response
    
    public func send(
        _ endpoint: Endpoint
    ) async throws {
        _ = try await performRequest(endpoint: endpoint)
    }
    
    private func performRequest(
        endpoint: Endpoint,
        attempt: Int = 0
    ) async throws -> NetworkResponse {
        let resolvedBaseURL = endpoint.baseURL ?? baseURL
        var urlRequest = try URLRequest(endpoint, baseURL: resolvedBaseURL, encoder: encoder)

        for interceptor in interceptors {
            urlRequest = try await interceptor.adapt(urlRequest)
        }

        let data: Data
        let urlResponse: URLResponse

        do {
            (data, urlResponse) = try await session.data(for: urlRequest)
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch let error as URLError {
            let networkError = mapURLError(error)
            return try await handleRetry(
                endpoint: endpoint,
                request: urlRequest,
                error: networkError,
                response: nil,
                attempt: attempt
            )
        }
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NetworkError.unknown(underlying: URLError(.badServerResponse))
        }
        
        let response = NetworkResponse(
            data: data,
            statusCode: httpResponse.statusCode,
            headers: HTTPHeaders(httpResponse.allHeaderFields)
        )
        
        for interceptor in interceptors {
            await interceptor.response(response, for: urlRequest)
        }
        
        if (200..<300).contains(httpResponse.statusCode) {
            return response
        }
        
        let error = mapHTTPError(
            statusCode: httpResponse.statusCode,
            data: data,
            headers: response.headers
        )
        
        return try await handleRetry(
            endpoint: endpoint,
            request: urlRequest,
            error: error,
            response: response,
            attempt: attempt
        )
    }
    
    private func handleRetry(
        endpoint: Endpoint,
        request: URLRequest,
        error: NetworkError,
        response: NetworkResponse?,
        attempt: Int
    ) async throws -> NetworkResponse {
        for interceptor in interceptors {
            let decision = await interceptor.retry(
                request,
                dueTo: error,
                response: response,
                attempt: attempt
            )
            
            switch decision {
            case .retry:
                return try await performRequest(endpoint: endpoint, attempt: attempt + 1)
            case .retryAfter(let delay):
                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch is CancellationError {
                    throw NetworkError.cancelled
                }
                return try await performRequest(endpoint: endpoint, attempt: attempt + 1)
            case .doNotRetry:
                continue
            }
        }
        
        throw error
    }
    
    
    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .unknown(underlying: error)
        }
    }
    
    private func mapHTTPError(statusCode: Int, data: Data, headers: HTTPHeaders) -> NetworkError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            let retryAfter = headers["Retry-After"].flatMap { TimeInterval($0) }
            return .tooManyRequests(retryAfter: retryAfter)
        case 500...599:
            return .serverError(statusCode: statusCode)
        default:
            return .httpError(statusCode: statusCode, data: data)
        }
    }
    
}
