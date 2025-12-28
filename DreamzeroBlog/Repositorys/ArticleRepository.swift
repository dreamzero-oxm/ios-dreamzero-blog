//
//  ArticleRepository.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import Foundation

/// 文章仓库协议
/// 这个就类似于后端service 的 interface概念
protocol ArticleRepositoryType {
    /// 获取文章列表
    /// - Parameters:
    ///   - page: 页码
    ///   - pageSize: 每页数量
    ///   - status: 文章状态（可选）
    ///   - userId: 用户ID（可选）
    ///   - tag: 单个标签（可选）
    ///   - tags: 多个标签（可选）
    /// - Returns: 文章列表分页数据
    func fetchList(
        page: Int,
        pageSize: Int,
        nickName: String?,
        tags: [String]?,
        title: String?,
        sortBy: String?,
        sortOrder: String?
    ) async throws -> ArticleListPage

    /// 获取文章详情
    /// - Parameter articleId: 文章ID
    /// - Returns: 文章详情
    func getDetail(articleId: String) async throws -> Article
}

/// 文章仓库实现
final class ArticleRepository: ArticleRepositoryType {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchList(
        page: Int = 1,
        pageSize: Int = 10,
        nickName: String? = nil,
        tags: [String]? = nil,
        title: String? = nil,
        sortBy: String? = nil,
        sortOrder: String? = nil,
    ) async throws -> ArticleListPage {
        // 创建对应的 Endpoint
        let endpoint = GetArticleListEndpoint(
            page: page,
            pageSize: pageSize,
            nickName: nickName,
            tags: tags,
            title: title,
            sortBy: sortBy,
            sortOrder: sortOrder
        )

        // 发起请求并解析响应
        let response: SingleResponse<ArticleListResponseData> = try await client.request(
            endpoint,
            as: SingleResponse<ArticleListResponseData>.self
        )
        

        // 检查业务状态码
        guard response.code == 0 else {
            throw APIError.server(code: response.code, message: response.msg)
        }

        // 转换 DTO 为领域模型
        let articles = response.data.articles.map { Article(from: $0) }

        // 打印日志
        LogTool.shared.debug("Fetched \(articles.count) articles, total: \(response.data.total)")

        // 构造分页数据
        return ArticleListPage(
            articles: articles,
            total: response.data.total,
            page: response.data.page,
            pageSize: response.data.pageSize
        )
    }

    func getDetail(articleId: String) async throws -> Article {
        // 创建对应的 Endpoint
        let endpoint = GetArticleDetailEndpoint(articleId: articleId)

        // 发起请求并解析响应
        let response: SingleResponse<ArticleDto> = try await client.request(
            endpoint,
            as: SingleResponse<ArticleDto>.self
        )

        // 检查业务状态码
        guard response.code == 0 else {
            throw APIError.server(code: response.code, message: response.msg)
        }

        // 转换 DTO 为领域模型
        let article = Article(from: response.data)

        // 打印日志
        LogTool.shared.debug("Fetched article detail: \(article.title)")

        return article
    }
}
