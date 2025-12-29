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
public struct ChatMessage: Identifiable, Sendable, Equatable {
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

    public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.role == rhs.role &&
        lhs.content == rhs.content &&
        lhs.isStreaming == rhs.isStreaming
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

// MARK: - SwiftData Model 转换

extension ChatSessionModel {
    /// 将 SwiftData 模型转换为领域模型
    func toDomainModel() -> ChatSession {
        return ChatSession(
            id: id,
            title: title,
            messages: messages
                .sorted { lhs, rhs in
                    // 主排序：按时间戳升序（旧消息在前）
                    if lhs.timestamp != rhs.timestamp {
                        return lhs.timestamp < rhs.timestamp
                    }
                    // 次排序：按 ID 确保稳定性（处理时间戳相同的情况）
                    return lhs.id < rhs.id
                }
                .map { $0.toDomainModel() },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension ChatMessageModel {
    /// 将 SwiftData 模型转换为领域模型
    func toDomainModel() -> ChatMessage {
        return ChatMessage(
            id: id,
            role: role,
            content: content,
            timestamp: timestamp,
            isStreaming: isStreaming
        )
    }
}

extension ChatSession {
    /// 将领域模型转换为 SwiftData 持久化模型
    func toPersistenceModel() -> ChatSessionModel {
        let sessionModel = ChatSessionModel(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        sessionModel.messages = messages.map { $0.toPersistenceModel(session: sessionModel) }
        return sessionModel
    }
}

extension ChatMessage {
    /// 将领域模型转换为 SwiftData 持久化模型
    func toPersistenceModel(session: ChatSessionModel) -> ChatMessageModel {
        let msgModel = ChatMessageModel(
            id: id,
            role: role,
            content: content,
            timestamp: timestamp,
            isStreaming: isStreaming
        )
        msgModel.session = session
        return msgModel
    }
}
