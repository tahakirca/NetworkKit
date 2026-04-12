//
//  TokenManager.swift
//  NetworkKit
//
//  Created by Taha Kirca on 9.04.2026.
//

import Foundation

public actor TokenManager {
    private let provider: (any RefreshTokenProvider)?
    private let store: any TokenStore
    private var refreshTask: Task<String, any Error>?

    public init(provider: (any RefreshTokenProvider)? = nil, store: any TokenStore) {
        self.provider = provider
        self.store = store
    }

    public func validToken() async -> String? {
        await store.get()
    }

    public func refreshToken() async throws -> String {
        guard let provider else {
            throw NetworkError.unauthorized
        }

        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        let task = Task {
            let newToken = try await provider.refreshToken()
            await store.save(token: newToken)
            return newToken
        }

        refreshTask = task

        let result: Result<String, any Error>
        do {
            let token = try await task.value
            result = .success(token)
        } catch {
            result = .failure(error)
        }

        // Only clear if no new refresh was started while we were awaiting
        if !task.isCancelled {
            refreshTask = nil
        }

        return try result.get()
    }

    public func clearToken() async {
        refreshTask?.cancel()
        refreshTask = nil
        await store.clear()
    }
}
