import Foundation

struct User: Codable, Sendable, Identifiable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let phone: String

    struct Address: Codable, Sendable {
        let street: String
        let suite: String
        let city: String
        let zipcode: String
    }

    let address: Address?
}

struct Post: Codable, Sendable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

struct CreatePostRequest: Codable, Sendable {
    let title: String
    let body: String
    let userId: Int
}
