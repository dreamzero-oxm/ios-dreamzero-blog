//
//  ChatSessionStore.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftData
import Foundation

/// 聊天会话存储服务协议
@MainActor
protocol ChatSessionStoreType {
    /// 获取所有会话（按更新时间倒序）
    func fetchAllSessions() async throws -> [ChatSession]
    /// 根据 ID 获取会话
    func fetchSession(byId id: String) async throws -> ChatSession?
    /// 保存会话
    func saveSession(_ session: ChatSession) async throws
    /// 删除会话
    func deleteSession(_ session: ChatSession) async throws
}

/// 聊天会话存储服务实现
@MainActor
final class ChatSessionStore: ChatSessionStoreType {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllSessions() async throws -> [ChatSession] {
        let descriptor = FetchDescriptor<ChatSessionModel>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let sessionModels = try modelContext.fetch(descriptor)
        return sessionModels.map { $0.toDomainModel() }
    }

    func fetchSession(byId id: String) async throws -> ChatSession? {
        let sessionId = id
        let descriptor = FetchDescriptor<ChatSessionModel>(
            predicate: #Predicate { $0.id == sessionId }
        )
        let sessionModels = try modelContext.fetch(descriptor)
        return sessionModels.first?.toDomainModel()
    }

    func saveSession(_ session: ChatSession) async throws {
        let sessionId = session.id
        let descriptor = FetchDescriptor<ChatSessionModel>(
            predicate: #Predicate { $0.id == sessionId }
        )
        let existing = try modelContext.fetch(descriptor).first

        if let existing = existing {
            // 更新现有会话
            existing.title = session.title
            existing.updatedAt = session.updatedAt
            // 删除旧消息并重新添加
            for oldMessage in existing.messages {
                modelContext.delete(oldMessage)
            }
            existing.messages = session.messages.map { msg in
                let msgModel = ChatMessageModel(
                    id: msg.id,
                    role: msg.role,
                    content: msg.content,
                    timestamp: msg.timestamp,
                    isStreaming: msg.isStreaming
                )
                msgModel.session = existing
                msgModel.setSources(msg.sources)
                return msgModel
            }
        } else {
            // 插入新会话
            let sessionModel = session.toPersistenceModel()
            modelContext.insert(sessionModel)
        }

        try modelContext.save()
    }

    func deleteSession(_ session: ChatSession) async throws {
        let sessionId = session.id
        let descriptor = FetchDescriptor<ChatSessionModel>(
            predicate: #Predicate { $0.id == sessionId }
        )
        guard let sessionModel = try modelContext.fetch(descriptor).first else {
            return
        }
        modelContext.delete(sessionModel)
        try modelContext.save()
    }
}
