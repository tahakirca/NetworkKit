import Testing
import Foundation
@testable import NetworkKit

@Suite("RetryInterceptor")
struct RetryInterceptorTests {

    private let interceptor = RetryInterceptor(maxRetries: 3, baseDelay: 1.0)
    private let request = URLRequest(url: URL(string: "https://test.com")!)

    @Test("retries on timeout")
    func retryOnTimeout() async {
        let decision = await interceptor.retry(request, dueTo: .timeout, response: nil, attempt: 0)
        if case .retryAfter = decision { } else {
            Issue.record("Expected .retryAfter")
        }
    }

    @Test("retries on noConnection")
    func retryOnNoConnection() async {
        let decision = await interceptor.retry(request, dueTo: .noConnection, response: nil, attempt: 0)
        if case .retryAfter = decision { } else {
            Issue.record("Expected .retryAfter")
        }
    }

    @Test("retries on server error")
    func retryOnServerError() async {
        let decision = await interceptor.retry(request, dueTo: .serverError(statusCode: 500), response: nil, attempt: 0)
        if case .retryAfter = decision { } else {
            Issue.record("Expected .retryAfter")
        }
    }

    @Test("does not retry on notFound")
    func noRetryOnNotFound() async {
        let decision = await interceptor.retry(request, dueTo: .notFound, response: nil, attempt: 0)
        if case .doNotRetry = decision { } else {
            Issue.record("Expected .doNotRetry")
        }
    }

    @Test("stops after max retries")
    func stopsAtMax() async {
        let decision = await interceptor.retry(request, dueTo: .timeout, response: nil, attempt: 3)
        if case .doNotRetry = decision { } else {
            Issue.record("Expected .doNotRetry")
        }
    }

    @Test("exponential backoff delays")
    func backoffDelays() async {
        for attempt in 0..<3 {
            let decision = await interceptor.retry(request, dueTo: .timeout, response: nil, attempt: attempt)
            if case .retryAfter(let delay) = decision {
                let expected = 1.0 * pow(2.0, Double(attempt))
                #expect(delay == expected)
            } else {
                Issue.record("Expected .retryAfter at attempt \(attempt)")
            }
        }
    }

    @Test("respects Retry-After header in seconds")
    func retryAfterSeconds() async {
        let response = NetworkResponse(
            data: Data(),
            statusCode: 429,
            headers: HTTPHeaders(["Retry-After": "30"])
        )
        let decision = await interceptor.retry(request, dueTo: .tooManyRequests(retryAfter: 30), response: response, attempt: 0)
        if case .retryAfter(let delay) = decision {
            #expect(delay == 30)
        } else {
            Issue.record("Expected .retryAfter(30)")
        }
    }
}
