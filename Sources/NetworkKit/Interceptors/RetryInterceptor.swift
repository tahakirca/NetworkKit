//
//  RetryInterceptor.swift
//  NetworkKit
//
//  Created by Taha Kırca on 9.04.2026.
//

import Foundation

public struct RetryInterceptor: Interceptor {
    private let maxRetries: Int
    private let baseDelay: TimeInterval
    private let exponentialBackoff: Bool
    private let retryableStatusCodes: Set<Int>

    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        exponentialBackoff: Bool = true,
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.exponentialBackoff = exponentialBackoff
        self.retryableStatusCodes = retryableStatusCodes
    }

    public func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        response: NetworkResponse?,
        attempt: Int
    ) async -> RetryDecision {
        guard attempt < maxRetries else { return .doNotRetry }
        guard isRetryable(error) else { return .doNotRetry }

        if let retryAfter = response?.headers["Retry-After"],
           let seconds = Self.parseRetryAfter(retryAfter) {
            return .retryAfter(seconds)
        }

        if exponentialBackoff {
            let delay = baseDelay * pow(2.0, Double(attempt))
            return .retryAfter(delay)
        }

        return .retryAfter(baseDelay)
    }

    private static func parseRetryAfter(_ value: String) -> TimeInterval? {
        if let seconds = TimeInterval(value) {
            return seconds
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")

        // RFC 7231 HTTP-date formats
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss zzz",  // IMF-fixdate
            "EEEE, dd-MMM-yy HH:mm:ss zzz",   // obsolete RFC 850
            "EEE MMM d HH:mm:ss yyyy"           // asctime
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                let delay = date.timeIntervalSinceNow
                return delay > 0 ? delay : 0
            }
        }

        return nil
    }

    private func isRetryable(_ error: NetworkError) -> Bool {
        switch error {
        case .timeout, .noConnection:
            return true
        case .tooManyRequests:
            return true
        case .serverError:
            return true
        case .httpError(let code, _):
            return retryableStatusCodes.contains(code)
        default:
            return false
        }
    }
}
