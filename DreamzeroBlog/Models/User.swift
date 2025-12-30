//
//  User.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import Foundation

/// 用户领域模型
public struct User: Identifiable, Hashable {
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
    public let lockUntil: String?
    public let createdAt: String
    public let updatedAt: String

    public init(
        id: String,
        userName: String,
        nickname: String,
        email: String? = nil,
        phone: String? = nil,
        avatar: String? = nil,
        bio: String? = nil,
        website: String? = nil,
        location: String? = nil,
        birthday: String? = nil,
        gender: String? = nil,
        isLocked: Bool = false,
        lockUntil: String? = nil,
        createdAt: String = "",
        updatedAt: String = ""
    ) {
        self.id = id
        self.userName = userName
        self.nickname = nickname
        self.email = email
        self.phone = phone
        self.avatar = avatar
        self.bio = bio
        self.website = website
        self.location = location
        self.birthday = birthday
        self.gender = gender
        self.isLocked = isLocked
        self.lockUntil = lockUntil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 从 DTO 转换
    public init(from dto: UserDto) {
        self.id = dto.id
        self.userName = dto.userName
        self.nickname = dto.nickname
        self.email = dto.email
        self.phone = dto.phone
        self.avatar = dto.avatar
        self.bio = dto.bio
        self.website = dto.website
        self.location = dto.location
        self.birthday = dto.birthday
        self.gender = dto.gender
        self.isLocked = dto.isLocked
        self.lockUntil = dto.lockUntil
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
    }

    // MARK: - Hashable Conformance

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}
