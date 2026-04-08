//
//  Interceptor.swift
//  NetworkKit
//
//  Created by Taha Kırca on 9.04.2026.
//

import Foundation

public enum RetryDecision: Sendable {
    case doNotRetry
    case retry
    case retryAfter(TimeInterval)
}

public protocol Interceptor: Sendable {
    func adapt(_ request: URLRequest) async throws -> URLRequest
    func response(_ response: NetworkResponse, for request: URLRequest) async
    func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        response: NetworkResponse?,
        attempt: Int
    ) async -> RetryDecision
}

public extension Interceptor {
    func adapt(_ request: URLRequest) async throws -> URLRequest { request }
    func response(_ response: NetworkResponse, for request: URLRequest) async {}
    func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        response: NetworkResponse?,
        attempt: Int
    ) async -> RetryDecision { .doNotRetry }
}
