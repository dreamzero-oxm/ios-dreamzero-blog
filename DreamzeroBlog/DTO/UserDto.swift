//
//  UserDto.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import Foundation

/// 用户数据传输对象
public struct UserDto: Decodable, Hashable {
    public let id: String
    public let userName: String
    public let nickname: String
    public let email: String?
    public let phone: String?
    public let avatar: String?
    public let bio: String?
    public let website: String?
    public let location: String?
    public let birthday: String?
    public let gender: String?
    public let isLocked: Bool
    public let lockUntil: String
    public let createdAt: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userName     = "user_name"
        case nickname
        case email
        case phone
        case avatar
        case bio
        case website
        case location
        case birthday
        case gender
        case isLocked     = "is_locked"
        case lockUntil    = "lock_until"
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
    }
}

// MARK: - Authentication Response DTOs

/// Login/Refresh token response data structure
public struct LoginResponseData: Decodable {
    public let success: Bool
    public let user: UserDto
    public let accessToken: String
    public let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case success
        case user
        case accessToken   = "access_token"
        case refreshToken  = "refresh_token"
    }
}

/// Refresh token response (no refresh_token returned)
public struct RefreshTokenResponseData: Decodable {
    public let success: Bool
    public let user: UserDto
    public let accessToken: String

    enum CodingKeys: String, CodingKey {
        case success
        case user
        case accessToken   = "access_token"
    }
}

/// User profile response
public struct UserProfileResponseData: Decodable {
    public let success: Bool
    public let user: UserDto
}

/// Avatar upload response
public struct AvatarUploadResponseData: Decodable {
    public let success: Bool
    public let message: String
    public let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case avatarURL    = "avatar_url"
    }
}

/// Update profile request
public struct UpdateProfileRequest: Encodable {
    public let nickname: String?
    public let email: String?
    public let phone: String?
    public let bio: String?
    public let website: String?
    public let location: String?
    public let birthday: String?
    public let gender: String?
}

/// Update profile response
public struct UpdateProfileResponseData: Decodable {
    public let success: Bool
    public let message: String
}
