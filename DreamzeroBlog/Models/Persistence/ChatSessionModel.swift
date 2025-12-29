//
//  ChatSessionModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftData
import Foundation

/// SwiftData 持久化模型 - 聊天会话
@Model
final class ChatSessionModel {
    var id: String
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var messages: [ChatMessageModel]

    init(
        id: String = UUID().uuidString,
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = []
    }
}

/// SwiftData 持久化模型 - 聊天消息
@Model
final class ChatMessageModel {
    var id: String
    var roleRawValue: String
    var content: String
    var timestamp: Date
    var isStreaming: Bool
    var session: ChatSessionModel?

    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.roleRawValue = role.rawValue
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }

    /// 计算属性：将 rawValue 转换为 MessageRole
    var role: MessageRole {
        get { MessageRole(rawValue: roleRawValue) ?? .user }
        set { roleRawValue = newValue.rawValue }
    }
}
