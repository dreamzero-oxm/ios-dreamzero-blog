//
//  ChatMessage.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import Foundation

/// 聊天消息角色
public enum MessageRole: String, Sendable {
    case system
    case user
    case assistant
}

/// 聊天消息领域模型
public struct ChatMessage: Identifiable, Sendable {
    public let id: String
    public let role: MessageRole
    public var content: String
    public let timestamp: Date
    public var isStreaming: Bool  // 是否正在流式生成中

    public init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }

    /// 从DTO创建用户消息
    public init(from dto: ChatMessageDto) {
        self.id = UUID().uuidString
        self.role = MessageRole(rawValue: dto.role.rawValue) ?? .user
        self.content = dto.content
        self.timestamp = Date()
        self.isStreaming = false
    }
}

/// 聊天会话领域模型
public struct ChatSession: Identifiable, Sendable {
    public let id: String
    public var title: String
    public var messages: [ChatMessage]
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String = "新对话",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
