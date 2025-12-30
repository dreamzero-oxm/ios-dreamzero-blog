//
//  UserEndpoint.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/30.
//

import Foundation
import Alamofire

// MARK: - Login Endpoint

/// User login endpoint
/// POST /api/v1/user/login
/// Content-Type: multipart/form-data
public struct LoginEndpoint: APIEndpoint {
    public let account: String
    public let password: String

    public init(account: String, password: String) {
        self.account = account
        self.password = password
    }

    public var path: String { "/api/v1/user/login" }
    public var method: HTTPMethod { .post }
    public var encoder: ParameterEncoder { URLEncodedFormParameterEncoder.default }
    public var requiresAuth: Bool { false }

    public var parameters: Encodable? {
        LoginParameters(account: account, password: password)
    }

    private struct LoginParameters: Encodable {
        let account: String
        let password: String
    }
}

// MARK: - Refresh Token Endpoint

/// Refresh access token endpoint
/// POST /api/v1/user/refreshToken
/// Content-Type: application/json
public struct RefreshTokenEndpoint: APIEndpoint {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }

    public var path: String { "/api/v1/user/refreshToken" }
    public var method: HTTPMethod { .post }
    public var encoder: ParameterEncoder { JSONParameterEncoder.default }
    public var requiresAuth: Bool { false }

    public var parameters: Encodable? {
        RefreshTokenParameters(refreshToken: refreshToken)
    }

    private struct RefreshTokenParameters: Encodable {
        let refreshToken: String
        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }
}

// MARK: - Get Profile Endpoint

/// Get current user profile endpoint
/// GET /api/v1/user/profile
public struct GetProfileEndpoint: APIEndpoint {
    public var path: String { "/api/v1/user/profile" }
    public var method: HTTPMethod { .get }
    public var encoder: ParameterEncoder { URLEncodedFormParameterEncoder.default }
    public var requiresAuth: Bool { true }
}

// MARK: - Update Profile Endpoint

/// Update user profile endpoint
/// PUT /api/v1/user/profile
/// Content-Type: application/json
public struct UpdateProfileEndpoint: APIEndpoint {
    public let nickname: String?
    public let email: String?
    public let phone: String?
    public let bio: String?
    public let website: String?
    public let location: String?
    public let birthday: String?
    public let gender: String?

    public init(
        nickname: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        bio: String? = nil,
        website: String? = nil,
        location: String? = nil,
        birthday: String? = nil,
        gender: String? = nil
    ) {
        self.nickname = nickname
        self.email = email
        self.phone = phone
        self.bio = bio
        self.website = website
        self.location = location
        self.birthday = birthday
        self.gender = gender
    }

    public var path: String { "/api/v1/user/profile" }
    public var method: HTTPMethod { .put }
    public var encoder: ParameterEncoder { JSONParameterEncoder.default }
    public var requiresAuth: Bool { true }

    public var parameters: Encodable? {
        UpdateProfileRequest(
            nickname: nickname,
            email: email,
            phone: phone,
            bio: bio,
            website: website,
            location: location,
            birthday: birthday,
            gender: gender
        )
    }
}

// MARK: - Upload Avatar Endpoint

/// Upload user avatar endpoint
/// POST /api/v1/user/avatar
/// Content-Type: multipart/form-data
public struct UploadAvatarEndpoint: APIEndpoint {
    public let imageData: Data
    public let fileName: String

    public init(imageData: Data, fileName: String = "avatar.jpg") {
        self.imageData = imageData
        self.fileName = fileName
    }

    public var path: String { "/api/v1/user/avatar" }
    public var method: HTTPMethod { .post }
    public var encoder: ParameterEncoder {
        CustomMultipartEncoder(imageData: imageData, fileName: fileName)
    }
    public var requiresAuth: Bool { true }
}

// MARK: - Validate Access Token Endpoint

/// Validate access token endpoint
/// GET /api/v1/user/validateAccessToken
public struct ValidateAccessTokenEndpoint: APIEndpoint {
    public var path: String { "/api/v1/user/validateAccessToken" }
    public var method: HTTPMethod { .get }
    public var encoder: ParameterEncoder { URLEncodedFormParameterEncoder.default }
    public var requiresAuth: Bool { true }
}
