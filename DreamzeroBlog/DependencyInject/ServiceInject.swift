//
//  ServiceInject.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Factory
import SwiftData

extension Container {
    /// 共享的 ModelContainer - 由 DreamzeroBlogApp 设置
    var sharedModelContainer: Factory<ModelContainer?> {
        self { nil }.cached
    }

    /// 设置共享的 ModelContainer
    func registerSharedModelContainer(_ container: ModelContainer) {
        self.sharedModelContainer.register { container }
    }

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

    /// 联网搜索服务
    var webSearchService: Factory<WebSearchServiceType> {
        self { WebSearchService() }
    }

    /// 知识库存储 - 使用共享的 ModelContainer
    var knowledgeBaseStore: Factory<KnowledgeBaseStoreType> {
        self { @MainActor in
            guard let container = self.sharedModelContainer() else {
                fatalError("ModelContainer not registered. Call registerSharedModelContainer first.")
            }
            let context = ModelContext(container)
            return KnowledgeBaseStore(modelContext: context)
        }
    }

    /// 默认知识同步服务
    var defaultKnowledgeService: Factory<DefaultKnowledgeServiceType> {
        self { @MainActor in DefaultKnowledgeService(
            articleRepository: self.articleRepository(),
            photoRepository: self.photoRepository(),
            knowledgeBaseStore: self.knowledgeBaseStore(),
            chunkingService: self.chunkingService(),
            embeddingService: self.embeddingService(),
            ragConfig: RAGConfigurationStore.shared
        )}
    }
}
