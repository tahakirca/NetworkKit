//
//  TokenStore.swift
//  NetworkKit
//
//  Created by Taha Kırca on 9.04.2026.
//

import Foundation

public protocol TokenStore: Sendable {
    func save(token: String) async
    func get() async -> String?
    func clear() async
}
