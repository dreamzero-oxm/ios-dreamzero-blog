//
//  Article.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import Foundation

/// 文章状态枚举
public enum ArticleStatus: String {
    case draft       // 草稿
    case published   // 已发布
    case `private`   // 私有
}

/// 文章领域模型
public struct Article: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let content: String
    public let summary: String
    public let status: ArticleStatus
    public let viewCount: Int
    public let likeCount: Int
    public let userId: String
//    public let user: User
    public let tags: [String]
    public let coverImage: String?
    
    public let publishedAt: String?
    public let createdAt: String
    public let updatedAt: String

    public init(
        id: String,
        title: String,
        summary: String,
        content: String,
        coverImage: String? = nil,
        status: ArticleStatus = .published,
        tags: [String] = [],
        likeCount: Int = 0,
        viewCount: Int = 0,
        publishedAt: String? = nil,
        createdAt: String,
        updatedAt: String,
//        user: User,
        userId: String
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.summary = summary
        self.status = status
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.userId = userId
//        self.user = user
        self.tags = tags
        
        self.coverImage = coverImage
        self.publishedAt = publishedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// 从 DTO 转换
    public init(from dto: ArticleDto) {
        self.id = dto.id
        self.title = dto.title
        self.summary = dto.summary
        self.content = dto.content
        self.coverImage = dto.coverImage
        self.status = ArticleStatus(rawValue: dto.status) ?? .published
        self.tags = dto.tags
        self.likeCount = dto.likeCount
        self.viewCount = dto.viewCount
        self.publishedAt = dto.publishedAt
        self.createdAt = dto.createdAt
        self.updatedAt = dto.updatedAt
//        self.user = User(from: dto.user)
        self.userId = dto.userId
    }
}

/// 文章列表分页数据
public struct ArticleListPage {
    public let articles: [Article]
    public let total: Int
    public let page: Int
    public let pageSize: Int
    public let hasMore: Bool

    public init(articles: [Article], total: Int, page: Int, pageSize: Int) {
        self.articles = articles
        self.total = total
        self.page = page
        self.pageSize = pageSize
        self.hasMore = page * pageSize < total
    }
}
