//
//  ArticleEndpoint.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import Foundation
import Alamofire

// MARK: - 获取文章列表

/// 获取文章列表接口
/// 支持分页、状态筛选、用户筛选、标签筛选
public struct GetArticleListEndpoint: APIEndpoint {
    public init(
        page: Int = 1,
        pageSize: Int = 10,
        nickName: String? = nil,
        tags: [String]? = nil,
        title: String? = nil,
        sortBy: String? = nil,
        sortOrder: String? = nil
    ) {
        self.page = page
        self.pageSize = pageSize
        self.nickName = nickName
        self.tags = tags
        self.title = title
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }

    public let page: Int
    public let pageSize: Int
    public let nickName: String?
    public let tags: [String]?
    public let title: String?
    public let sortBy: String?
    public let sortOrder: String?
    
    public var path: String { "/api/v1/articles" }
    public var method: HTTPMethod { .get }
    public var encoder: ParameterEncoder { URLEncodedFormParameterEncoder.default }
    public var requiresAuth: Bool { false }  // 可选认证

    public var parameters: Encodable? {
        ArticleListParameters(
            page: page,
            pageSize: pageSize,
            nickName: nickName,
            tags: tags,
            title: title,
            sortBy: sortBy,
            sortOrder: sortOrder
        )
    }

    /// 请求参数结构
    private struct ArticleListParameters: Encodable {
        let page: Int
        let pageSize: Int
        let nickName: String?
        let tags: [String]?
        let title: String?
        let sortBy: String?
        let sortOrder: String?
        

        enum CodingKeys: String, CodingKey {
            case page
            case pageSize     = "page_size"
            case nickName     = "nickname"
            case tags         = "tags"
            case title
            case sortBy       = "sort_by"
            case sortOrder    = "sort_order"
        }
    }
}

// MARK: - 获取文章详情

/// 获取文章详情接口
public struct GetArticleDetailEndpoint: APIEndpoint {
    public init(articleId: String) {
        self.articleId = articleId
    }

    public let articleId: String

    public var path: String { "/api/v1/articles/\(articleId)" }
    public var method: HTTPMethod { .get }
    public var encoder: ParameterEncoder { URLEncodedFormParameterEncoder.default }
    public var requiresAuth: Bool { false }  // 可选认证
}
