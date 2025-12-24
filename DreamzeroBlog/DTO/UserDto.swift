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
    public let avatar: String?
    public let bio: String?
    public let website: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userName     = "user_name"
        case nickname
        case avatar
        case bio
        case website
    }
}
