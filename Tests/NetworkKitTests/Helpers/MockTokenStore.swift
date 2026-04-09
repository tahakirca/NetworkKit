import NetworkKit

actor MockTokenStore: TokenStore {
    var token: String?

    func save(token: String) async { self.token = token }
    func get() async -> String? { token }
    func clear() async { token = nil }
}
