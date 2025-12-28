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
    public let avatar: String?
    public let bio: String?
    public let website: String?

    public init(
        id: String,
        userName: String,
        nickname: String,
        avatar: String? = nil,
        bio: String? = nil,
        website: String? = nil
    ) {
        self.id = id
        self.userName = userName
        self.nickname = nickname
        self.avatar = avatar
        self.bio = bio
        self.website = website
    }

    /// 从 DTO 转换
    public init(from dto: UserDto) {
        self.id = dto.id
        self.userName = dto.userName
        self.nickname = dto.nickname
        self.avatar = dto.avatar
        self.bio = dto.bio
        self.website = dto.website
    }
}
