import Foundation
import NetworkKit

// JSONPlaceholder is a free fake REST API — perfect for demos
// https://jsonplaceholder.typicode.com

enum JSONPlaceholderEndpoint: Endpoint {
    case users
    case user(id: Int)
    case posts(userId: Int)
    case createPost(title: String, body: String, userId: Int)
    case deletePost(id: Int)

    var baseURL: URL { URL(string: "https://jsonplaceholder.typicode.com")! }

    var path: String {
        switch self {
        case .users: "/users"
        case .user(let id): "/users/\(id)"
        case .posts: "/posts"
        case .createPost: "/posts"
        case .deletePost(let id): "/posts/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .users, .user, .posts: .GET
        case .createPost: .POST
        case .deletePost: .DELETE
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .posts(let userId):
            [URLQueryItem(name: "userId", value: "\(userId)")]
        default:
            nil
        }
    }

    var body: RequestBody? {
        switch self {
        case .createPost(let title, let body, let userId):
            .json(CreatePostRequest(title: title, body: body, userId: userId))
        default:
            nil
        }
    }
}
