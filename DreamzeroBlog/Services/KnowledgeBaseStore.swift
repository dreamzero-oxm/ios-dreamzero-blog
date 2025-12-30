//
//  KnowledgeBaseStore.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftData
import Foundation

/// 知识库存储协议
@MainActor
protocol KnowledgeBaseStoreType {
    func fetchAllDocuments() async throws -> [KBDocument]
    func fetchDocument(byId id: String) async throws -> KBDocument?
    func saveDocument(_ document: KBDocument) async throws
    func deleteDocument(_ document: KBDocument) async throws
    func fetchAllChunks() async throws -> [KBChunk]
    func fetchChunks(forDocumentId documentId: String) async throws -> [KBChunk]
    func updateChunk(_ chunk: KBChunk) async throws
}

/// 知识库存储 - SwiftData 包装
final class KnowledgeBaseStore: KnowledgeBaseStoreType {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllDocuments() async throws -> [KBDocument] {
        let descriptor = FetchDescriptor<KBDocumentModel>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let documentModels = try modelContext.fetch(descriptor)
        return documentModels.map { $0.toDomainModel() }
    }

    func fetchDocument(byId id: String) async throws -> KBDocument? {
        let descriptor = FetchDescriptor<KBDocumentModel>(
            predicate: #Predicate<KBDocumentModel> { $0.id == id }
        )
        guard let model = try modelContext.fetch(descriptor).first else { return nil }
        return model.toDomainModel()
    }

    func saveDocument(_ document: KBDocument) async throws {
        let docId = document.id
        let descriptor = FetchDescriptor<KBDocumentModel>(
            predicate: #Predicate<KBDocumentModel> { $0.id == docId }
        )
        let existing = try modelContext.fetch(descriptor).first

        if let existing = existing {
            // 更新现有文档
            existing.title = document.title
            existing.content = document.content
            existing.sourceType = document.sourceType
            existing.sourcePath = document.sourcePath
            existing.isDefault = document.isDefault
            existing.updatedAt = Date()

            // 删除旧的分块
            for oldChunk in existing.chunks {
                modelContext.delete(oldChunk)
            }

            // 添加新分块
            existing.chunks = document.chunks.map { chunkModel in
                chunkModel.toPersistenceModel(document: existing)
            }
        } else {
            // 创建新文档
            let model = KBDocumentModel(
                id: document.id,
                title: document.title,
                content: document.content,
                sourceType: document.sourceType,
                sourcePath: document.sourcePath,
                isDefault: document.isDefault,
                createdAt: document.createdAt,
                updatedAt: document.updatedAt
            )
            model.chunks = document.chunks.map { chunk in
                chunk.toPersistenceModel(document: model)
            }
            modelContext.insert(model)
        }

        try modelContext.save()
        LogTool.shared.info("Document saved: \(document.title)")
    }

    func deleteDocument(_ document: KBDocument) async throws {
        let docId = document.id
        let descriptor = FetchDescriptor<KBDocumentModel>(
            predicate: #Predicate<KBDocumentModel> { $0.id == docId }
        )
        guard let model = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(model)
        try modelContext.save()
        LogTool.shared.info("Document deleted: \(document.title)")
    }

    func fetchAllChunks() async throws -> [KBChunk] {
        let descriptor = FetchDescriptor<KBChunkModel>(
            sortBy: [SortDescriptor(\.documentId), SortDescriptor(\.chunkIndex)]
        )
        let chunkModels = try modelContext.fetch(descriptor)
        return chunkModels.map { $0.toDomainModel() }
    }

    func fetchChunks(forDocumentId documentId: String) async throws -> [KBChunk] {
        let docId = documentId
        let descriptor = FetchDescriptor<KBChunkModel>(
            predicate: #Predicate<KBChunkModel> { $0.documentId == docId },
            sortBy: [SortDescriptor(\.chunkIndex)]
        )
        let chunkModels = try modelContext.fetch(descriptor)
        return chunkModels.map { $0.toDomainModel() }
    }

    func updateChunk(_ chunk: KBChunk) async throws {
        let chunkId = chunk.id
        let descriptor = FetchDescriptor<KBChunkModel>(
            predicate: #Predicate<KBChunkModel> { $0.id == chunkId }
        )
        guard let model = try modelContext.fetch(descriptor).first else { return }

        model.content = chunk.content
        model.embedding = chunk.embedding?.toData()

        try modelContext.save()
        LogTool.shared.info("Chunk updated: \(chunk.id)")
    }
}

// MARK: - Model Conversions

extension KBDocumentModel {
    func toDomainModel() -> KBDocument {
        KBDocument(
            id: id,
            title: title,
            content: content,
            sourceType: sourceType,
            sourcePath: sourcePath,
            isDefault: isDefault,
            createdAt: createdAt,
            updatedAt: updatedAt,
            chunks: chunks.map { $0.toDomainModel() }
        )
    }
}

extension KBChunkModel {
    func toDomainModel() -> KBChunk {
        KBChunk(
            id: id,
            documentId: documentId,
            chunkIndex: chunkIndex,
            content: content,
            embedding: vector,
            createdAt: createdAt
        )
    }
}

extension KBChunk {
    func toPersistenceModel(document: KBDocumentModel) -> KBChunkModel {
        let model = KBChunkModel(
            id: id,
            documentId: documentId,
            chunkIndex: chunkIndex,
            content: content,
            embedding: embedding?.toData(),
            createdAt: createdAt
        )
        model.document = document
        return model
    }
}

extension Array where Element == Double {
    /// 将 Double 数组转换为 Data
    func toData() -> Data {
        return self.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }
}
