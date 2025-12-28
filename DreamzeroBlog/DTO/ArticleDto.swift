//
//  ArticleDto.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import Foundation

/// 文章数据传输对象
public struct ArticleDto: Decodable, Hashable {
    public let id: String
    public let title: String
    public let content: String
    public let summary: String
    public let status: String
    public let viewCount: Int
    public let likeCount: Int
    public let userId: String
//    public let user: UserDto
    public let tags: [String]
    public let coverImage: String?
    
    public let publishedAt: String?
    public let createdAt: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case summary
        case status
        case viewCount    = "view_count"
        case likeCount    = "like_count"
        case userId       = "user_id"
//        case user
        case tags
        case coverImage   = "cover_image"
        
        case publishedAt  = "published_at"
        case createdAt    = "created_at"
        case updatedAt    = "updated_at"
    }
}

/// 文章列表响应数据结构
public struct ArticleListResponseData: Decodable, Hashable {
    public let articles: [ArticleDto]
    public let total: Int
    public let page: Int
    public let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case articles
        case total
        case page
        case pageSize     = "page_size"
    }
}
