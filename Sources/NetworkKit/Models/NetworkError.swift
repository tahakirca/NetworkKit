//
//  NetworkError.swift
//  NetworkKit
//
//  Created by Taha Kırca on 8.04.2026.
//

import Foundation
                                                                                                            
public enum NetworkError: Error, Sendable {
    case invalidURL
    case encodingFailed(underlying: any Error)
    case decodingFailed(underlying: any Error, data: Data)
    case unauthorized
    case forbidden
    case notFound
    case tooManyRequests(retryAfter: TimeInterval?)
    case serverError(statusCode: Int)
    case httpError(statusCode: Int, data: Data)
    case noConnection
    case timeout
    case cancelled
    case unknown(underlying: any Error)
}
