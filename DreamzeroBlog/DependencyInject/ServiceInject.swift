//
//  ServiceInject.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Factory
import SwiftData

extension Container {
    /// 嵌入服务
    var embeddingService: Factory<EmbeddingServiceType> {
        self { EmbeddingService() }
    }

    /// 分块服务
    var chunkingService: Factory<ChunkingServiceType> {
        self { ChunkingService() }
    }

    /// 向量搜索服务
    var vectorSearchService: Factory<VectorSearchServiceType> {
        self { VectorSearchService() }
    }

    /// 知识库存储 - 需要在运行时提供 ModelContext
    var knowledgeBaseStore: Factory<KnowledgeBaseStoreType> {
        self { @MainActor in
            // 获取当前 ModelContainer 中的 ModelContext
            // 注意：这需要在 SwiftUI 视图中通过 @Environment(\.modelContext) 传入
            // 这里使用一个临时的解决方案
            let container = Self.sharedModelContainer()
            let context = ModelContext(container)
            return KnowledgeBaseStore(modelContext: context)
        }
    }

    /// 辅助方法：获取共享的 ModelContainer
    private static func sharedModelContainer() -> ModelContainer {
        let schema = Schema([
            ChatSessionModel.self,
            ChatMessageModel.self,
            KBDocumentModel.self,
            KBChunkModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
