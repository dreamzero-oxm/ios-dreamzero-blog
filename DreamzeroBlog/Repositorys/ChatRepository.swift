//
//  ChatRepository.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import Foundation

// MARK: - 聊天仓库协议

/// 聊天仓库协议
protocol ChatRepositoryType {
    /// 发送聊天消息并获取流式响应
    /// - Parameters:
    ///   - messages: 聊天消息列表
    ///   - model: 模型名称（默认：glm-4.7）
    ///   - temperature: 温度参数（可选）
    /// - Returns: AsyncThrowingStream，用于流式接收响应
    func streamChat(
        messages: [ChatMessageDto],
        model: String,
        temperature: Double?
    ) async throws -> AsyncThrowingStream<String, Error>
}

// MARK: - 聊天仓库实现

/// 聊天仓库实现
final class ChatRepository: ChatRepositoryType {
    private let client: APIClient
    private let configuration: APIConfiguration

    init(client: APIClient, configuration: APIConfiguration) {
        self.client = client
        self.configuration = configuration
    }

    // 向后兼容：使用旧的apiKey参数初始化
    convenience init(client: APIClient, apiKey: String) {
        // 使用默认配置，只替换apiKey
        var config = APIConfiguration.default
        config.apiKey = apiKey
        self.init(client: client, configuration: config)
    }

    func streamChat(
        messages: [ChatMessageDto],
        model: String = "glm-4.7",
        temperature: Double? = nil
    ) async throws -> AsyncThrowingStream<String, Error> {
        // 使用配置中的模型名称（如果未指定）
        let actualModel = model.isEmpty || model == "glm-4.7" ? configuration.model : model

        // 调试日志：检查 API 配置
        LogTool.shared.debug("🔑 使用 API 配置: \(configuration.provider.rawValue)")
        LogTool.shared.debug("📡 API URL: \(configuration.apiURL)")
        LogTool.shared.debug("🤖 模型: \(actualModel)")
        LogTool.shared.debug("🔑 API Key: \(configuration.apiKey.isEmpty ? "空" : configuration.apiKey.prefix(20) + "...")")
        LogTool.shared.debug("🔐 使用JWT: \(configuration.useJWT)")
        // 打印消息
        LogTool.shared.debug("消息: \(messages)")

        // 创建Endpoint（包含API配置）
        let endpoint = ChatCompletionEndpoint(
            model: actualModel,
            messages: messages,
            stream: true,
            temperature: temperature,
            apiKey: configuration.apiKey,
            useJWT: configuration.useJWT
        )

        // 获取配置中的API URL
        guard let apiURL = URL(string: configuration.apiURL) else {
            LogTool.shared.error("无效的API URL: \(configuration.apiURL)")
            throw APIError.invalidResponse
        }

        // 使用APIClient的流式请求方法
        let jsonStream = try await client.streamRequest(endpoint, customBaseURL: apiURL)

        // 创建新的流来处理JSON解析和内容提取
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await jsonString in jsonStream {
                        // 解析SSE返回的JSON
                        if let data = jsonString.data(using: .utf8) {
                            do {
                                let streamResponse = try JSONDecoder().decode(ChatStreamResponse.self, from: data)

                                // 提取内容
                                if let choice = streamResponse.choices.first,
                                   let content = choice.delta.content {
                                    continuation.yield(content)
                                }

                                // 检查是否完成
                                if let choice = streamResponse.choices.first,
                                   choice.finishReason != nil {
                                    continuation.finish()
                                    return
                                }
                            } catch {
                                LogTool.shared.error("解析SSE数据失败: \(error), JSON: \(jsonString)")
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    LogTool.shared.error("流式聊天失败: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
