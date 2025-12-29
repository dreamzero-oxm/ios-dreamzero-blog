//
//  WebSearchService.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation

// MARK: - 百度搜索 API 模型

/// 百度搜索请求模型
private struct BaiduSearchRequest: Codable {
    let messages: [SearchMessage]
    let search_source: String
    let resource_type_filter: [ResourceTypeFilter]
    let search_recency_filter: String

    struct SearchMessage: Codable {
        let content: String
        let role: String
    }

    struct ResourceTypeFilter: Codable {
        let type: String
        let top_k: Int
    }
}

/// 百度搜索响应模型
private struct BaiduSearchResponse: Codable {
    let references: [SearchReference]?

    struct SearchReference: Codable {
        let content: String
        let title: String
        let url: String
    }
}

// MARK: - 联网搜索结果

/// 联网搜索结果
public struct WebSearchResult: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let url: String
    public let content: String
    public let source: String

    public init(id: String = UUID().uuidString, title: String, url: String, content: String, source: String = "web") {
        self.id = id
        self.title = title
        self.url = url
        self.content = content
        self.source = source
    }
}

// MARK: - 联网搜索服务协议

public protocol WebSearchServiceType {
    func search(query: String) async throws -> [WebSearchResult]
}

// MARK: - WebSearchService 实现

/// 联网搜索服务实现
///
/// 调用百度千帆 AI 搜索 API 进行联网搜索
/// API 文档: https://cloud.baidu.com/doc/qianfan-api/s/Wmbq4z7e5
final class WebSearchService: WebSearchServiceType {
    private let ragConfig: RAGConfigurationStore

    init(ragConfig: RAGConfigurationStore = .shared) {
        self.ragConfig = ragConfig
    }

    func search(query: String) async throws -> [WebSearchResult] {
        // 检查是否启用
        guard ragConfig.webSearchEnabled else {
            LogTool.shared.debug("Web search is disabled")
            return []
        }

        // 检查 Authorization 是否配置
        let auth = ragConfig.baiduSearchAuthorization
        guard !auth.isEmpty else {
            LogTool.shared.warning("Baidu search authorization not configured")
            throw WebSearchError.notConfigured
        }

        // 构建 API URL
        guard let url = URL(string: "https://qianfan.baidubce.com/v2/ai_search/chat/completions") else {
            throw WebSearchError.invalidURL
        }

        // 构建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = BaiduSearchRequest(
            messages: [BaiduSearchRequest.SearchMessage(content: query, role: "user")],
            search_source: "baidu_search_v2",
            resource_type_filter: [BaiduSearchRequest.ResourceTypeFilter(type: "web", top_k: 20)],
            search_recency_filter: "year"
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebSearchError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            LogTool.shared.error("Baidu search failed with status: \(httpResponse.statusCode)")
            throw WebSearchError.apiError(statusCode: httpResponse.statusCode)
        }

        // 解码响应
        let searchResponse = try JSONDecoder().decode(BaiduSearchResponse.self, from: data)

        // 转换结果
        let results = searchResponse.references?.map { ref in
            WebSearchResult(
                title: ref.title,
                url: ref.url,
                content: ref.content,
                source: "baidu"
            )
        } ?? []

        LogTool.shared.info("Baidu search returned \(results.count) results")
        return results
    }
}

// MARK: - Errors

public enum WebSearchError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case notConfigured
    case apiError(statusCode: Int)
    case decodingError

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的搜索 API 地址"
        case .invalidResponse:
            return "搜索响应格式错误"
        case .notConfigured:
            return "百度搜索 Authorization 未配置，请在 RAG 设置中配置"
        case .apiError(let code):
            return "搜索 API 错误 (状态码: \(code))"
        case .decodingError:
            return "搜索结果解析失败"
        }
    }
}
