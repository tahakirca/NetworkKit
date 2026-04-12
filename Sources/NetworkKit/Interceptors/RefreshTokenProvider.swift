//
//  RefreshTokenProvider.swift
//  NetworkKit
//
//  Created by Taha Kırca on 9.04.2026.
//

import Foundation

public protocol RefreshTokenProvider: Sendable {
    func refreshToken() async throws -> String
}
