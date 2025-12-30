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

/// 消息引用的来源
public struct MessageSource: Identifiable, Sendable, Equatable, Codable {
    public let id: String
    public let type: SourceType
    public let title: String
    public let url: String?  // 用于联网搜索
    public let similarity: Double?  // 用于知识库（相似度）

    public enum SourceType: String, Sendable, Codable {
        case knowledgeBase  // 知识库
        case webSearch      // 联网搜索
    }

    public init(id: String = UUID().uuidString, type: SourceType, title: String, url: String? = nil, similarity: Double? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.url = url
        self.similarity = similarity
    }

    public static func == (lhs: MessageSource, rhs: MessageSource) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.title == rhs.title &&
        lhs.url == rhs.url &&
        lhs.similarity == rhs.similarity
    }
}

/// 聊天消息领域模型
public struct ChatMessage: Identifiable, Sendable, Equatable {
    public let id: String
    public let role: MessageRole
    public var content: String
    public let timestamp: Date
    public var isStreaming: Bool  // 是否正在流式生成中
    public var sources: [MessageSource]  // 消息引用的来源列表

    public init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        sources: [MessageSource] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.sources = sources
    }

    public static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.role == rhs.role &&
        lhs.content == rhs.content &&
        lhs.isStreaming == rhs.isStreaming &&
        lhs.sources == rhs.sources
    }

    /// 从DTO创建用户消息
    public init(from dto: ChatMessageDto) {
        self.id = UUID().uuidString
        self.role = MessageRole(rawValue: dto.role.rawValue) ?? .user
        self.content = dto.content
        self.timestamp = Date()
        self.isStreaming = false
        self.sources = []
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
            isStreaming: isStreaming,
            sources: sources
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
        msgModel.setSources(sources)
        return msgModel
    }
}
