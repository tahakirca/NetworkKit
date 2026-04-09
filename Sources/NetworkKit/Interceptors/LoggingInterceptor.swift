//
//  LoggingInterceptor.swift
//  NetworkKit
//
//  Created by Taha Kırca on 9.04.2026.
//

import Foundation

public struct LoggingInterceptor: Interceptor {

    public enum LogLevel: Sendable {
        case none        // logging disabled
        case minimal     // just method + url + status
        case headers     // + request headers (redacted)
        case body        // + response body (pretty printed)
    }

    private let level: LogLevel
    private let sensitiveHeaders: Set<String>

    public init(
        level: LogLevel = .headers,
        sensitiveHeaders: Set<String> = ["Authorization", "Cookie", "Set-Cookie"]
    ) {
        #if DEBUG
        self.level = level
        #else
        self.level = .none
        #endif
        self.sensitiveHeaders = Set(sensitiveHeaders.map { $0.lowercased() })
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard level != .none else { return request }

        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"

        if level >= .headers,
           let headers = request.allHTTPHeaderFields, !headers.isEmpty {
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
        guard level != .none else { return }

        let url = request.url?.absoluteString ?? "?"
        print("← \(response.statusCode) \(url) (\(response.data.count) bytes)")

        if level >= .body {
            if let json = try? JSONSerialization.jsonObject(with: response.data),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let string = String(data: pretty, encoding: .utf8) {
                print("📦 Response:\n\(string)")
            } else if let string = String(data: response.data, encoding: .utf8) {
                print("📦 Response:\n\(string)")
            }
        }
    }
}

extension LoggingInterceptor.LogLevel: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        order(lhs) < order(rhs)
    }

    private static func order(_ level: Self) -> Int {
        switch level {
        case .none: 0
        case .minimal: 1
        case .headers: 2
        case .body: 3
        }
    }
}
