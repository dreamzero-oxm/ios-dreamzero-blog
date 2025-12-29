//
//  KnowledgeBaseModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftData
import Foundation

/// SwiftData 持久化模型 - 知识库文档
@Model
final class KBDocumentModel {
    var id: String
    var title: String
    var content: String
    var sourceTypeRawValue: String
    var sourcePath: String?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \KBChunkModel.document) var chunks: [KBChunkModel]

    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        sourceType: SourceType = .manual,
        sourcePath: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceTypeRawValue = sourceType.rawValue
        self.sourcePath = sourcePath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.chunks = []
    }

    /// 计算属性：将 rawValue 转换为 SourceType
    var sourceType: SourceType {
        get { SourceType(rawValue: sourceTypeRawValue) ?? .manual }
        set { sourceTypeRawValue = newValue.rawValue }
    }
}

/// SwiftData 持久化模型 - 知识库分块
@Model
final class KBChunkModel {
    var id: String
    var documentId: String
    var chunkIndex: Int
    var content: String
    var embedding: Data?
    var createdAt: Date
    var document: KBDocumentModel?

    init(
        id: String = UUID().uuidString,
        documentId: String,
        chunkIndex: Int,
        content: String,
        embedding: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.documentId = documentId
        self.chunkIndex = chunkIndex
        self.content = content
        self.embedding = embedding
        self.createdAt = createdAt
    }

    /// 将 Data 转换为 [Double] 向量
    var vector: [Double]? {
        guard let embedding = embedding else { return nil }
        return embedding.withUnsafeBytes {
            Array($0.bindMemory(to: Double.self))
        }
    }
}

/// 文档来源类型
enum SourceType: String, Codable {
    case file = "file"
    case manual = "manual"
}
