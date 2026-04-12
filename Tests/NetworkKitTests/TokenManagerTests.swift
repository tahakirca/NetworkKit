import Testing
import Foundation
@testable import NetworkKit

@Suite("TokenManager")
struct TokenManagerTests {

    @Test("returns stored token")
    func validToken() async {
        let store = MockTokenStore()
        await store.save(token: "existing")
        let manager = TokenManager(provider: MockRefreshTokenProvider(), store: store)
        let token = await manager.validToken()
        #expect(token == "existing")
    }

    @Test("returns nil when no token")
    func noToken() async {
        let manager = TokenManager(provider: MockRefreshTokenProvider(), store: MockTokenStore())
        let token = await manager.validToken()
        #expect(token == nil)
    }

    @Test("refreshes and stores new token")
    func refreshToken() async throws {
        let store = MockTokenStore()
        let manager = TokenManager(provider: MockRefreshTokenProvider(), store: store)
        let token = try await manager.refreshToken()
        #expect(token == "token-1")
        let stored = await store.get()
        #expect(stored == "token-1")
    }

    @Test("single-flight: concurrent refreshes call provider only once")
    func singleFlight() async throws {
        let provider = MockRefreshTokenProvider()
        let manager = TokenManager(provider: provider, store: MockTokenStore())

        let tokens = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<5 {
                group.addTask { try await manager.refreshToken() }
            }
            var results: [String] = []
            for try await token in group {
                results.append(token)
            }
            return results
        }

        let callCount = await provider.callCount
        #expect(callCount == 1)
        #expect(tokens.allSatisfy { $0 == "token-1" })
    }

    @Test("clearToken cancels and clears")
    func clearToken() async {
        let store = MockTokenStore()
        await store.save(token: "abc")
        let manager = TokenManager(provider: MockRefreshTokenProvider(), store: store)
        await manager.clearToken()
        let token = await store.get()
        #expect(token == nil)
    }
}
