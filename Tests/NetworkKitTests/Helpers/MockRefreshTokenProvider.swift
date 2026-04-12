import NetworkKit
import Foundation

actor MockRefreshTokenProvider: RefreshTokenProvider {
    var callCount = 0
    var shouldFail = false

    func refreshToken() async throws -> String {
        callCount += 1
        if shouldFail { throw NSError(domain: "test", code: 0) }
        try await Task.sleep(for: .milliseconds(50))
        return "token-\(callCount)"
    }
}
