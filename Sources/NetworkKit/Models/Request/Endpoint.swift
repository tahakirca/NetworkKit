//
//  Endpoint.swift
//  NetworkKit
//
//  Created by Taha Kırca on 8.04.2026.
//

import Foundation
                                                          
public protocol Endpoint {
    var path: String { get }
    var baseURL: URL? { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: RequestBody? { get }
    var queryItems: [URLQueryItem]? { get }
}

public extension Endpoint {
    var baseURL: URL? { nil }
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: RequestBody? { nil }
}

public enum RequestBody: Sendable {
    case jsonBody(any Encodable & Sendable)
    case data(Data, contentType: String)
    case formURLEncoded([String: String])

    public static func json<T: Encodable & Sendable>(_ value: T) -> RequestBody {
        .jsonBody(value)
    }
}

public enum HTTPMethod: String, Sendable {
    case GET
    case POST
    case PATCH
    case PUT
    case DELETE
}
