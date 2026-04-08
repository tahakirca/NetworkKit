//
//  NetworkResponse.swift
//  NetworkKit
//
//  Created by Taha Kırca on 8.04.2026.
//

import Foundation

public struct NetworkResponse: Sendable {
    public let data: Data
    public let statusCode: Int
    public let headers: HTTPHeaders
}
