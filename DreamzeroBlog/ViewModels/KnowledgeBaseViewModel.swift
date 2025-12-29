//
//  KnowledgeBaseViewModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// 知识库 ViewModel
@MainActor
@Observable
final class KnowledgeBaseViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
                return true
            case (.failed(let lhsMsg), .failed(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }

    var state: State = .idle
    var documents: [KBDocument] = []
    var chunks: [KBChunk] = []
    var isProcessing = false

    private let store: KnowledgeBaseStoreType
    private let embeddingService: EmbeddingServiceType
    private let chunkingService: ChunkingServiceType
    private let config: RAGConfigurationStore
    private let vectorSearchService: VectorSearchServiceType

    init(
        store: KnowledgeBaseStoreType,
        embeddingService: EmbeddingServiceType,
        chunkingService: ChunkingServiceType,
        vectorSearchService: VectorSearchServiceType = VectorSearchService(),
        config: RAGConfigurationStore = .shared
    ) {
        self.store = store
        self.embeddingService = embeddingService
        self.chunkingService = chunkingService
        self.vectorSearchService = vectorSearchService
        self.config = config
    }

    func loadDocuments() async {
        state = .loading
        do {
            documents = try await store.fetchAllDocuments()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
            LogTool.shared.error("Failed to load documents: \(error)")
        }
    }

    func loadChunks() async {
        state = .loading
        do {
            chunks = try await store.fetchAllChunks()
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
            LogTool.shared.error("Failed to load chunks: \(error)")
        }
    }

    func addDocument(title: String, content: String) async {
        isProcessing = true
        defer { isProcessing = false }

        // 分块处理
        let chunkTexts = chunkingService.chunkText(
            content,
            delimiter: config.chunkDelimiter,
            chunkSize: config.chunkSize
        )

        LogTool.shared.info("Chunked document into \(chunkTexts.count) chunks")

        // 为每个分块生成嵌入向量
        var chunks: [KBChunk] = []
        for (index, chunkText) in chunkTexts.enumerated() {
            do {
                let embedding = try await embeddingService.generateEmbedding(for: chunkText)
                let chunk = KBChunk(
                    id: UUID().uuidString,
                    documentId: "", // 将在保存时设置
                    chunkIndex: index,
                    content: chunkText,
                    embedding: embedding,
                    createdAt: Date()
                )
                chunks.append(chunk)
            } catch {
                LogTool.shared.error("Failed to generate embedding for chunk \(index): \(error)")
                // 即使嵌入失败，也保存分块（没有嵌入向量）
                let chunk = KBChunk(
                    id: UUID().uuidString,
                    documentId: "",
                    chunkIndex: index,
                    content: chunkText,
                    embedding: nil,
                    createdAt: Date()
                )
                chunks.append(chunk)
            }
        }

        // 创建文档
        let document = KBDocument(
            title: title,
            content: content,
            sourceType: .manual,
            chunks: chunks
        )

        // 保存到存储
        do {
            try await store.saveDocument(document)
            await loadDocuments()
            LogTool.shared.info("Document added successfully: \(title)")
        } catch {
            LogTool.shared.error("Failed to add document: \(error)")
        }
    }

    func deleteDocument(_ document: KBDocument) async {
        do {
            try await store.deleteDocument(document)
            await loadDocuments()
            LogTool.shared.info("Document deleted: \(document.title)")
        } catch {
            LogTool.shared.error("Failed to delete document: \(error)")
        }
    }

    func updateDocument(_ document: KBDocument) async {
        isProcessing = true
        defer { isProcessing = false }

        // 重新分块处理
        let chunkTexts = chunkingService.chunkText(
            document.content,
            delimiter: config.chunkDelimiter,
            chunkSize: config.chunkSize
        )

        LogTool.shared.info("Re-chunked document into \(chunkTexts.count) chunks")

        // 为每个分块生成嵌入向量
        var chunks: [KBChunk] = []
        for (index, chunkText) in chunkTexts.enumerated() {
            do {
                let embedding = try await embeddingService.generateEmbedding(for: chunkText)
                let chunk = KBChunk(
                    id: UUID().uuidString,
                    documentId: document.id,
                    chunkIndex: index,
                    content: chunkText,
                    embedding: embedding,
                    createdAt: Date()
                )
                chunks.append(chunk)
            } catch {
                LogTool.shared.error("Failed to generate embedding for chunk \(index): \(error)")
                let chunk = KBChunk(
                    id: UUID().uuidString,
                    documentId: document.id,
                    chunkIndex: index,
                    content: chunkText,
                    embedding: nil,
                    createdAt: Date()
                )
                chunks.append(chunk)
            }
        }

        // 更新文档（包含新的分块）
        var updatedDocument = document
        updatedDocument.chunks = chunks
        updatedDocument.updatedAt = Date()

        do {
            try await store.saveDocument(updatedDocument)
            await loadDocuments()
            LogTool.shared.info("Document updated successfully: \(document.title)")
        } catch {
            LogTool.shared.error("Failed to update document: \(error)")
        }
    }

    func searchChunks(query: String) async -> [KBSearchResult] {
        guard !query.isEmpty else { return [] }

        // 生成查询嵌入
        guard let queryEmbedding = try? await embeddingService.generateEmbedding(for: query) else {
            LogTool.shared.error("Failed to generate query embedding")
            return []
        }

        // 加载所有分块（如果尚未加载）
        if chunks.isEmpty {
            do {
                chunks = try await store.fetchAllChunks()
            } catch {
                LogTool.shared.error("Failed to load chunks: \(error)")
                return []
            }
        }

        // 执行向量搜索
        var results = vectorSearchService.search(
            queryEmbedding: queryEmbedding,
            chunks: chunks,
            topK: config.topK
        )

        // 填充文档标题
        results = results.map { result in
            var mutableResult = result
            if let document = documents.first(where: { $0.id == result.chunk.documentId }) {
                mutableResult = KBSearchResult(
                    id: result.id,
                    chunk: result.chunk,
                    documentTitle: document.title,
                    similarity: result.similarity
                )
            }
            return mutableResult
        }

        return results
    }
}
