//
//  LoginViewModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/30.
//

import SwiftUI

/// Login view model - handles login business logic
@Observable
final class LoginViewModel {
    // MARK: - Input

    var account = "" {
        didSet { validateInput() }
    }
    var password = "" {
        didSet { validateInput() }
    }

    // MARK: - UI State

    var isLoading = false
    var showPassword = false
    var errorMessage: String?
    var showError = false
    var loginSuccess = false

    // MARK: - Validation State

    private(set) var isAccountValid = false
    private(set) var isPasswordValid = false

    var isValid: Bool {
        isAccountValid && isPasswordValid
    }

    // MARK: - Dependencies

    private let authSession: AuthSessionManager

    // MARK: - Init

    init(authSession: AuthSessionManager = .shared) {
        self.authSession = authSession
    }

    // MARK: - Validation

    private func validateInput() {
        // Account validation (username, email, or phone)
        isAccountValid = !account.isEmpty && account.count >= 3

        // Password validation
        isPasswordValid = !password.isEmpty && password.count >= 8
    }

    // MARK: - Actions

    func login() async {
        guard isValid else {
            showError(message: "请输入有效的账号和密码")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authSession.login(account: account, password: password)
            await MainActor.run {
                isLoading = false
                loginSuccess = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                showError(message: error.localizedDescription)
            }
        }
    }

    // MARK: - Error Handling

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
