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
    private let apiKey: String
    private let zhipuBaseURL = "https://open.bigmodel.cn/api/paas/v4"

    init(client: APIClient, apiKey: String) {
        self.client = client
        self.apiKey = apiKey
    }

    func streamChat(
        messages: [ChatMessageDto],
        model: String = "glm-4.7",
        temperature: Double? = nil
    ) async throws -> AsyncThrowingStream<String, Error> {
        // 创建Endpoint（包含API Key）
        let endpoint = ChatCompletionEndpoint(
            model: model,
            messages: messages,
            stream: true,
            temperature: temperature,
            apiKey: apiKey
        )

        // 获取智谱AI的baseURL
        guard let zhipuURL = URL(string: zhipuBaseURL) else {
            throw APIError.invalidResponse
        }

        // 使用APIClient的流式请求方法
        let jsonStream = try await client.streamRequest(endpoint, customBaseURL: zhipuURL)

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
