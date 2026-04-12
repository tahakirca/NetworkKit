import Foundation
import NetworkKit

// Single shared client for the whole app.
// Set up once, use everywhere.

@MainActor
final class NetworkManager {
    static let shared = NetworkManager()

    let client: HTTPClient
    let tokenManager: TokenManager

    private init() {
        let tokenStore = AppTokenStore()
        let tokenProvider = AppTokenProvider()

        tokenManager = TokenManager(provider: tokenProvider, store: tokenStore)

        // Interceptor order matters:
        // 1. Auth — attaches Bearer token
        // 2. Logging — logs request WITH token (redacted)
        // 3. Retry — retries failed requests with backoff
        client = HTTPClient(
            baseURL: URL(string: "https://jsonplaceholder.typicode.com")!,
            interceptors: [
                AuthInterceptor(tokenManager: tokenManager),
                LoggingInterceptor(level: .body),
                RetryInterceptor(maxRetries: 2, baseDelay: 0.5)
            ]
        )
    }
}
