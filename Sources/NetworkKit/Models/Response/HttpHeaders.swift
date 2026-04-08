//
//  HTTPHeaders.swift
//  NetworkKit
//
//  Created by Taha Kırca on 8.04.2026.
//

import Foundation

public struct HTTPHeaders: Sendable {
    private let storage: [String: [String]]

    public init(_ headerFields: [AnyHashable: Any]) {
        var result: [String: [String]] = [:]
        for (key, value) in headerFields {
            let name = (key as? String)?.lowercased() ?? String(describing: key).lowercased()
            let val = value as? String ?? String(describing: value)
            result[name, default: []].append(val)
        }
        self.storage = result
    }

    public subscript(_ key: String) -> String? {
        storage[key.lowercased()]?.first
    }

    public func values(for key: String) -> [String] {
        storage[key.lowercased()] ?? []
    }
}
