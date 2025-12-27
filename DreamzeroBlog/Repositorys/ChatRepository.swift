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
    ///   - model: 模型名称（默认：glm-4）
    ///   - onChunk: 接收流式数据的回调
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
    private let apiKey: String
    private let baseURL = "https://open.bigmodel.cn/api/paas/v4"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func streamChat(
        messages: [ChatMessageDto],
        model: String = "glm-4.7",
        temperature: Double? = nil
    ) async throws -> AsyncThrowingStream<String, Error> {
        // 构建请求体
        let request = ChatCompletionRequest(
            model: model,
            messages: messages,
            stream: true,
            temperature: temperature
        )

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 编码请求体
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        // 创建流式响应
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        if let data = try? await Data(collecting: bytes upTo: 1000),
                           let errorMessage = String(data: data, encoding: .utf8) {
                            LogTool.shared.error("智谱AI API错误: \(errorMessage)")
                        }
                        continuation.finish(throwing: APIError.server(code: httpResponse.statusCode, message: "请求失败"))
                        return
                    }

                    // 逐行读取SSE响应
                    for try await line in bytes.lines {
                        // SSE格式：data: {json}
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))

                            // 检查结束标记
                            if jsonString == "[DONE]" {
                                continuation.finish()
                                return
                            }

                            // 解析JSON数据
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
                                    LogTool.shared.error("解析SSE数据失败: \(error)")
                                }
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    LogTool.shared.error("流式请求失败: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
