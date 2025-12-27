//
//  ChatDto.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import Foundation

// MARK: - 智谱AI聊天请求DTO

/// 聊天消息角色
public enum ChatRole: String, Encodable {
    case system
    case user
    case assistant
}

/// 聊天消息
public struct ChatMessageDto: Encodable {
    public let role: ChatRole
    public let content: String

    public init(role: ChatRole, content: String) {
        self.role = role
        self.content = content
    }

    enum CodingKeys: String, CodingKey {
        case role
        case content
    }
}

/// 聊天完成请求
public struct ChatCompletionRequest: Encodable {
    public let model: String
    public let messages: [ChatMessageDto]
    public let stream: Bool
    public let temperature: Double?

    public init(
        model: String,
        messages: [ChatMessageDto],
        stream: Bool = false,
        temperature: Double? = nil
    ) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.temperature = temperature
    }

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case stream
        case temperature
    }
}

// MARK: - 智谱AI聊天流式响应DTO

/// 聊天流式响应的Delta部分
public struct ChatStreamDelta: Decodable {
    public let content: String?

    enum CodingKeys: String, CodingKey {
        case content
    }
}

/// 聊天流式响应的Choice部分
public struct ChatStreamChoice: Decodable {
    public let delta: ChatStreamDelta
    public let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case delta
        case finishReason = "finish_reason"
    }
}

/// 聊天流式响应
public struct ChatStreamResponse: Decodable {
    public let id: String
    public let choices: [ChatStreamChoice]
    public let created: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case choices
        case created
    }
}
