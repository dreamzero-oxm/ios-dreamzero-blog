//
//  KnowledgeBase.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// 知识库文档领域模型
struct KBDocument: Identifiable, Sendable {
    let id: String
    var title: String
    var content: String
    var sourceType: SourceType
    var sourcePath: String?
    var isDefault: Bool  // 标识是否为默认知识（文章/图片同步）
    let createdAt: Date
    var updatedAt: Date
    var chunks: [KBChunk]

    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        sourceType: SourceType = .manual,
        sourcePath: String? = nil,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        chunks: [KBChunk] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceType = sourceType
        self.sourcePath = sourcePath
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.chunks = chunks
    }
}

/// 知识库分块领域模型
struct KBChunk: Identifiable, Sendable {
    let id: String
    let documentId: String
    let chunkIndex: Int
    var content: String
    var embedding: [Double]?
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        documentId: String,
        chunkIndex: Int,
        content: String,
        embedding: [Double]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.documentId = documentId
        self.chunkIndex = chunkIndex
        self.content = content
        self.embedding = embedding
        self.createdAt = createdAt
    }
}

/// 知识库搜索结果
struct KBSearchResult: Identifiable, Sendable {
    let id: String
    let chunk: KBChunk
    var documentTitle: String
    let similarity: Double

    init(
        id: String = UUID().uuidString,
        chunk: KBChunk,
        documentTitle: String,
        similarity: Double
    ) {
        self.id = id
        self.chunk = chunk
        self.documentTitle = documentTitle
        self.similarity = similarity
    }
}
