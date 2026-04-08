//
//  TokenProvider.swift
//  NetworkKit
//
//  Created by Taha Kırca on 9.04.2026.
//

import Foundation

public protocol TokenProvider: Sendable {
    func refreshToken() async throws -> String
}
