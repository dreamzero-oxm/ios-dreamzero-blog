//
//  UserRepository.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/30.
//

import Foundation

// MARK: - Protocol

/// User repository protocol defining user-related operations
protocol UserRepositoryType {
    /// Login with account and password
    /// - Parameters:
    ///   - account: Username, email, or phone number
    ///   - password: User password
    /// - Returns: Tuple of user and tokens
    func login(account: String, password: String) async throws -> (user: User, tokens: AuthTokens)

    /// Get current user profile
    /// - Returns: Current user
    func getProfile() async throws -> User

    /// Update user profile
    /// - Parameters:
    ///   - nickname: Nickname
    ///   - email: Email address
    ///   - phone: Phone number
    ///   - bio: User biography
    ///   - website: Personal website
    ///   - location: User location
    ///   - birthday: Birthday in YYYY-MM-DD format
    ///   - gender: Gender
    /// - Returns: Success flag
    func updateProfile(
        nickname: String?,
        email: String?,
        phone: String?,
        bio: String?,
        website: String?,
        location: String?,
        birthday: String?,
        gender: String?
    ) async throws -> Bool

    /// Upload user avatar
    /// - Parameters:
    ///   - imageData: Image data
    ///   - fileName: File name
    /// - Returns: Avatar URL
    func uploadAvatar(imageData: Data, fileName: String) async throws -> String
}

// MARK: - Implementation

/// User repository implementation
/// Implements both UserRepositoryType and TokenRefresher protocol
final class UserRepository: UserRepositoryType, TokenRefresher {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    // MARK: - Login

    func login(account: String, password: String) async throws -> (user: User, tokens: AuthTokens) {
        let endpoint = LoginEndpoint(account: account, password: password)
        let response: SingleResponse<LoginResponseData> = try await client.request(
            endpoint,
            as: SingleResponse<LoginResponseData>.self
        )
        
        guard response.code == 0 else {
            throw APIError.server(code: response.code, message: response.msg)
        }

        // 再检查 data
        guard let data = response.data else {
            throw APIError.invalidResponse
        }

        let user = User(from: data.user)
        let tokens = AuthTokens(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            tokenType: "Bearer",
            expiresAt: nil // Could parse JWT to get expiration
        )

        return (user, tokens)
    }

    // MARK: - TokenRefresher Protocol

    func refreshToken(oldRefreshToken: String) async throws -> AuthTokens {
        let endpoint = RefreshTokenEndpoint(refreshToken: oldRefreshToken)
        let response: SingleResponse<RefreshTokenResponseData> = try await client.request(
            endpoint,
            as: SingleResponse<RefreshTokenResponseData>.self
        )

        guard response.code == 200 else {
            throw APIError.server(code: response.code, message: response.msg)
        }

        guard let data = response.data else {
            throw APIError.invalidResponse
        }

        return AuthTokens(
            accessToken: data.accessToken,
            refreshToken: oldRefreshToken,
            tokenType: "Bearer",
            expiresAt: nil
        )
    }

    // MARK: - Profile

    func getProfile() async throws -> User {
        let endpoint = GetProfileEndpoint()
        let response: SingleResponse<UserProfileResponseData> = try await client.request(
            endpoint,
            as: SingleResponse<UserProfileResponseData>.self
        )

        guard response.code == 200 else {
            throw APIError.server(code: response.code, message: response.msg)
        }

        guard let data = response.data else {
            throw APIError.invalidResponse
        }

        return User(from: data.user)
    }

    func updateProfile(
        nickname: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        bio: String? = nil,
        website: String? = nil,
        location: String? = nil,
        birthday: String? = nil,
        gender: String? = nil
    ) async throws -> Bool {
        let endpoint = UpdateProfileEndpoint(
            nickname: nickname,
            email: email,
            phone: phone,
            bio: bio,
            website: website,
            location: location,
            birthday: birthday,
            gender: gender
        )
        let response: SingleResponse<UpdateProfileResponseData> = try await client.request(
            endpoint,
            as: SingleResponse<UpdateProfileResponseData>.self
        )

        guard response.code == 200 else {
            throw APIError.server(code: response.code, message: response.msg)
        }

        guard let data = response.data else {
            throw APIError.invalidResponse
        }

        return data.success
    }

    func uploadAvatar(imageData: Data, fileName: String) async throws -> String {
        let endpoint = UploadAvatarEndpoint(imageData: imageData, fileName: fileName)
        let response: SingleResponse<AvatarUploadResponseData> = try await client.request(
            endpoint,
            as: SingleResponse<AvatarUploadResponseData>.self
        )

        guard response.code == 200 else {
            throw APIError.server(code: response.code, message: response.msg)
        }

        guard let data = response.data else {
            throw APIError.invalidResponse
        }

        return data.avatarURL ?? ""
    }
}
