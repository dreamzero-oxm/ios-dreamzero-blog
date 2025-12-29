//
//  ZhipuAIEndpoint.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import Foundation
import Alamofire

/// 智谱AI API基础URL
public let ZHIPU_AI_BASE_URL = "https://open.bigmodel.cn/api/coding/paas/v4"

// MARK: - 聊天补全接口

/// 智谱AI聊天补全接口
/// 支持流式输出
public struct ChatCompletionEndpoint: APIEndpoint {
    public init(
        model: String = "glm-4.7",
        messages: [ChatMessageDto],
        stream: Bool = false,
        temperature: Double? = nil,
        apiKey: String? = nil,
        useJWT: Bool = true
    ) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.temperature = temperature
        self.apiKey = apiKey
        self.useJWT = useJWT
    }

    public let model: String
    public let messages: [ChatMessageDto]
    public let stream: Bool
    public let temperature: Double?
    private let apiKey: String?
    private let useJWT: Bool

    public var path: String { "/chat/completions" }
    public var method: HTTPMethod { .post }
    public var encoder: ParameterEncoder { JSONParameterEncoder.default }
    public var requiresAuth: Bool { false }  // 使用自定义Authorization header

    public var parameters: Encodable? {
        ChatCompletionRequest(
            model: model,
            messages: messages,
            stream: stream,
            temperature: temperature
        )
    }

    /// 智谱AI需要Bearer Token格式的Authorization header
    /// API Key 可以根据配置选择是否转换为 JWT Token
    public var headers: HTTPHeaders? {
        var headers = HTTPHeaders()
        headers.add(.contentType("application/json"))

        // 如果提供了API Key，添加Authorization header
        if let apiKey = apiKey, !apiKey.isEmpty {
            if useJWT {
                // 使用JWT Token
                do {
                    let token = try ZhipuAIJWT.generateToken(from: apiKey)
                    headers.add(.authorization(bearerToken: token))
                    LogTool.shared.debug("🔐 已生成智谱AI JWT Token")
                } catch {
                    LogTool.shared.error("生成智谱AI Token失败: \(error)")
                    // 失败时仍尝试使用原始 API Key
                    headers.add(.authorization(bearerToken: apiKey))
                }
            } else {
                // 直接使用API Key
                headers.add(.authorization(bearerToken: apiKey))
                LogTool.shared.debug("🔑 直接使用API Key")
            }
        }

        return headers
    }
}
