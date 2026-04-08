//
//  LoggingInterceptor.swift
//  NetworkKit
//
//  Created by Taha Kırca on 9.04.2026.
//

import Foundation

public struct LoggingInterceptor: Interceptor {
    private let sensitiveHeaders: Set<String>

    public init(sensitiveHeaders: Set<String> = ["Authorization", "Cookie", "Set-Cookie"]) {
        self.sensitiveHeaders = Set(sensitiveHeaders.map { $0.lowercased() })
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            let redacted = headers.map { key, value in
                sensitiveHeaders.contains(key.lowercased()) ? "\(key): ████████" : "\(key): \(value)"
            }.joined(separator: ", ")
            print("→ \(method) \(url) [\(redacted)]")
        } else {
            print("→ \(method) \(url)")
        }

        return request
    }

    public func response(_ response: NetworkResponse, for request: URLRequest) async {
        let url = request.url?.absoluteString ?? "?"
        print("← \(response.statusCode) \(url) (\(response.data.count) bytes)")
    }
}
