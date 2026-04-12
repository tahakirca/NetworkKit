import Testing
import Foundation
@testable import NetworkKit

@Suite("AuthInterceptor")
struct AuthInterceptorTests {

    private func makeInterceptor(token: String? = nil) async -> (AuthInterceptor, MockTokenStore) {
        let store = MockTokenStore()
        if let token { await store.save(token: token) }
        let provider = MockRefreshTokenProvider()
        let manager = TokenManager(provider: provider, store: store)
        return (AuthInterceptor(tokenManager: manager), store)
    }

    @Test("adds Bearer token when available")
    func addsToken() async throws {
        let (interceptor, _) = await makeInterceptor(token: "abc123")
        var request = URLRequest(url: URL(string: "https://test.com")!)
        request = try await interceptor.adapt(request)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")
    }

    @Test("skips header when no token")
    func noToken() async throws {
        let (interceptor, _) = await makeInterceptor()
        var request = URLRequest(url: URL(string: "https://test.com")!)
        request = try await interceptor.adapt(request)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("retries on 401 at attempt 0")
    func retryOn401() async {
        let (interceptor, _) = await makeInterceptor(token: "old")
        let request = URLRequest(url: URL(string: "https://test.com")!)
        let decision = await interceptor.retry(request, dueTo: .unauthorized, response: nil, attempt: 0)
        if case .retry = decision { } else {
            Issue.record("Expected .retry")
        }
    }

    @Test("does not retry on 401 at attempt 1")
    func noRetrySecondAttempt() async {
        let (interceptor, _) = await makeInterceptor(token: "old")
        let request = URLRequest(url: URL(string: "https://test.com")!)
        let decision = await interceptor.retry(request, dueTo: .unauthorized, response: nil, attempt: 1)
        if case .doNotRetry = decision { } else {
            Issue.record("Expected .doNotRetry")
        }
    }

    @Test("does not retry on 403")
    func noRetryOnForbidden() async {
        let (interceptor, _) = await makeInterceptor(token: "old")
        let request = URLRequest(url: URL(string: "https://test.com")!)
        let decision = await interceptor.retry(request, dueTo: .forbidden, response: nil, attempt: 0)
        if case .doNotRetry = decision { } else {
            Issue.record("Expected .doNotRetry")
        }
    }
}
