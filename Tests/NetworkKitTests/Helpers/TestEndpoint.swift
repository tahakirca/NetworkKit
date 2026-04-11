import Foundation
import NetworkKit

enum TestEndpoint: Endpoint {
    case simple
    case withQuery(page: Int)
    case withHeaders
    case withJSON(TestBody)
    case withForm([String: String])
    case withData(Data)
    case invalidPath

    var path: String {
        switch self {
        case .simple, .withQuery, .withHeaders, .withJSON, .withForm, .withData:
            "/test"
        case .invalidPath:
            ""
        }
    }

    var method: HTTPMethod {
        switch self {
        case .simple, .withQuery, .withHeaders: .GET
        case .withJSON, .withForm, .withData: .POST
        case .invalidPath: .GET
        }
    }

    var headers: [String: String]? {
        switch self {
        case .withHeaders: ["X-Custom": "value", "Accept": "application/json"]
        default: nil
        }
    }

    var body: RequestBody? {
        switch self {
        case .withJSON(let body): .json(body)
        case .withForm(let params): .formURLEncoded(params)
        case .withData(let data): .data(data, contentType: "image/png")
        default: nil
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .withQuery(let page): [URLQueryItem(name: "page", value: "\(page)")]
        default: nil
        }
    }
}

struct TestBody: Codable, Sendable {
    let name: String
    let age: Int
}

struct TestUser: Codable, Sendable {
    let id: Int
    let name: String
}
