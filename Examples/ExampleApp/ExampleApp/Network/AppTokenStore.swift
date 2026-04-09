import Foundation
import NetworkKit

// In production, use Keychain instead of UserDefaults.
// This is simplified for the demo.

actor AppTokenStore: TokenStore {
    private let key = "access_token"

    func save(token: String) async {
        UserDefaults.standard.set(token, forKey: key)
    }

    func get() async -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    func clear() async {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
