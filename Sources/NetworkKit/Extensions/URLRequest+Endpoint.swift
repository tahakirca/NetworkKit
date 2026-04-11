//
//  URLRequest+Endpoint.swift
//  NetworkKit
//
//  Created by Taha Kırca on 8.04.2026.
//

import Foundation


extension URLRequest {
    init(_ endPoint: Endpoint, baseURL: URL, encoder: JSONEncoder) throws {
        guard var components = URLComponents(url: baseURL.appending(path: endPoint.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        if let queryItems = endPoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        self.init(url: url)
        self.httpMethod = endPoint.method.rawValue

        if let headers = endPoint.headers {
            for (key, value) in headers {
                self.setValue(value, forHTTPHeaderField: key)
            }
        }

        if let body = endPoint.body {
            switch body {
            case .data(let data, let contentType):
                self.httpBody = data
                self.setValue(contentType, forHTTPHeaderField: "Content-Type")

            case .jsonBody(let json):
                do {
                    self.httpBody = try encoder.encode(json)
                } catch {
                    throw NetworkError.encodingFailed(underlying: error)
                }
                self.setValue("application/json", forHTTPHeaderField: "Content-Type")

            case .formURLEncoded(let params):
                var comps = URLComponents()
                comps.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
                self.httpBody = comps.query?.data(using: .utf8)
                self.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            }
        }
    }
}
