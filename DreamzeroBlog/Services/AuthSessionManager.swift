//
//  AuthSessionManager.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/30.
//

import Foundation
import SwiftUI
import Factory

/// Authentication session manager
/// Manages user authentication state and coordinates between auth components
@Observable
final class AuthSessionManager {
    static let shared = AuthSessionManager()

    // MARK: - State

    private(set) var isAuthenticated = false
    private(set) var currentUser: User?

    // MARK: - Dependencies

    private let tokenStore: TokenStore
    private let userRepository: UserRepositoryType

    // MARK: - Init

    init(
        tokenStore: TokenStore? = nil,
        userRepository: UserRepositoryType? = nil
    ) {
        // Use provided dependencies or get from container
        if let tokenStore = tokenStore {
            self.tokenStore = tokenStore
        } else {
            self.tokenStore = Container.shared.tokenStore()
        }

        if let userRepository = userRepository {
            self.userRepository = userRepository
        } else {
            // Use injected apiClient which has AuthInterceptor
            self.userRepository = Container.shared.userRepository()
        }
    }

    // MARK: - Login

    func login(account: String, password: String) async throws {
        let (user, tokens) = try await userRepository.login(account: account, password: password)

        // Save tokens
        try tokenStore.save(tokens)

        // Update state
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }

    // MARK: - Logout

    func logout() {
        // Clear tokens
        try? tokenStore.clear()

        // Clear state
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Check Authentication Status

    func checkAuthStatus() async -> Bool {
        // Check if tokens exist
        guard let tokens = try? tokenStore.currentTokens(),
              !tokens.accessToken.isEmpty else {
            isAuthenticated = false
            currentUser = nil
            return false
        }

        // Optionally validate token with API
        do {
            let user = try await userRepository.getProfile()
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            return true
        } catch {
            // Token invalid, clear state
            logout()
            return false
        }
    }

    // MARK: - Refresh User Data

    func refreshUserData() async throws {
        let user = try await userRepository.getProfile()
        await MainActor.run {
            self.currentUser = user
        }
    }
}
