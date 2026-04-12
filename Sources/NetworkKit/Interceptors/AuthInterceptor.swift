//
//  AuthInterceptor.swift
//  NetworkKit
//
//  Created by Taha Kırca on 9.04.2026.
//

import Foundation

public final class AuthInterceptor: Interceptor, Sendable {
    private let tokenManager: TokenManager
    private let onUnauthorized: (@Sendable () async -> Void)?

    public init(
        tokenManager: TokenManager,
        onUnauthorized: (@Sendable () async -> Void)? = nil
    ) {
        self.tokenManager = tokenManager
        self.onUnauthorized = onUnauthorized
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let token = await tokenManager.validToken() else {
            return request
        }
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    public func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        response: NetworkResponse?,
        attempt: Int
    ) async -> RetryDecision {
        guard case .unauthorized = error, attempt == 0 else {
            return .doNotRetry
        }

        do {
            _ = try await tokenManager.refreshToken()
            return .retry
        } catch {
            await onUnauthorized?()
            return .doNotRetry
        }
    }
}
