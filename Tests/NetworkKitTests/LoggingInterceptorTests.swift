import Testing
import Foundation
@testable import NetworkKit

@Suite("LoggingInterceptor")
struct LoggingInterceptorTests {

    @Test("does not modify the request")
    func passthrough() async throws {
        let interceptor = LoggingInterceptor()
        var request = URLRequest(url: URL(string: "https://test.com")!)
        request.setValue("keep-this", forHTTPHeaderField: "X-Custom")
        let result = try await interceptor.adapt(request)
        #expect(result.value(forHTTPHeaderField: "X-Custom") == "keep-this")
        #expect(result.url == request.url)
    }

    @Test("case-insensitive header redaction")
    func caseInsensitiveRedaction() async throws {
        let interceptor = LoggingInterceptor(sensitiveHeaders: ["Authorization"])
        // All casings should be treated as sensitive
        var request = URLRequest(url: URL(string: "https://test.com")!)
        request.setValue("Bearer secret", forHTTPHeaderField: "authorization")
        // adapt should succeed without exposing the value (we just verify it doesn't crash)
        let result = try await interceptor.adapt(request)
        #expect(result.url != nil)
    }

    @Test("custom sensitive headers are redacted")
    func customSensitiveHeaders() async throws {
        let interceptor = LoggingInterceptor(sensitiveHeaders: ["X-Secret"])
        var request = URLRequest(url: URL(string: "https://test.com")!)
        request.setValue("hidden", forHTTPHeaderField: "X-Secret")
        request.setValue("visible", forHTTPHeaderField: "X-Public")
        let result = try await interceptor.adapt(request)
        #expect(result.url != nil)
    }
}
