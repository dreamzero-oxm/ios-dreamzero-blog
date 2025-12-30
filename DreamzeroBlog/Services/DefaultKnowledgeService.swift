//
//  DefaultKnowledgeService.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/30.
//

import Foundation

/// 默认知识同步服务协议
@MainActor
protocol DefaultKnowledgeServiceType {
    func syncDefaultKnowledge() async throws
    var needsSync: Bool { get }
}

/// 默认知识同步服务 - 将文章和图片同步到知识库
final class DefaultKnowledgeService: DefaultKnowledgeServiceType {
    private let articleRepository: ArticleRepositoryType
    private let photoRepository: PhotoRepositoryType
    private let knowledgeBaseStore: KnowledgeBaseStoreType
    private let chunkingService: ChunkingServiceType
    private let embeddingService: EmbeddingServiceType
    private let ragConfig: RAGConfigurationStore

    init(
        articleRepository: ArticleRepositoryType,
        photoRepository: PhotoRepositoryType,
        knowledgeBaseStore: KnowledgeBaseStoreType,
        chunkingService: ChunkingServiceType,
        embeddingService: EmbeddingServiceType,
        ragConfig: RAGConfigurationStore = .shared
    ) {
        self.articleRepository = articleRepository
        self.photoRepository = photoRepository
        self.knowledgeBaseStore = knowledgeBaseStore
        self.chunkingService = chunkingService
        self.embeddingService = embeddingService
        self.ragConfig = ragConfig
    }

    /// 同步默认知识到知识库
    func syncDefaultKnowledge() async throws {
        LogTool.shared.info("开始同步默认知识...")

        // 1. 获取现有默认文档，建立 ID 映射
        let existingDocs = try await knowledgeBaseStore.fetchAllDocuments()
        let existingDefaultDocs = existingDocs.filter { $0.isDefault }
        var existingArticleIds = Set<String>()
        var existingPhotoIds = Set<String>()

        for doc in existingDefaultDocs {
            if doc.id.hasPrefix("article-") {
                existingArticleIds.insert(String(doc.id.dropFirst(8))) // 去掉 "article-" 前缀
            } else if doc.id.hasPrefix("photo-") {
                existingPhotoIds.insert(String(doc.id.dropFirst(6))) // 去掉 "photo-" 前缀
            }
        }

        // 2. 同步文章（新增、更新）
        let (addedArticles, updatedArticles, currentArticleIds) = try await syncArticles(
            existingArticleIds: existingArticleIds
        )

        // 3. 同步图片（新增、更新）
        let (addedPhotos, updatedPhotos, currentPhotoIds) = try await syncPhotos(
            existingPhotoIds: existingPhotoIds
        )

        // 4. 清理已删除的文档
        let deletedArticles = existingArticleIds.subtracting(currentArticleIds)
        let deletedPhotos = existingPhotoIds.subtracting(currentPhotoIds)

        try await cleanupDeletedDocuments(
            deletedArticleIds: deletedArticles,
            deletedPhotoIds: deletedPhotos
        )

        LogTool.shared.info("""
            默认知识同步完成:
            - 新增文章: \(addedArticles), 更新文章: \(updatedArticles), 删除文章: \(deletedArticles.count)
            - 新增图片: \(addedPhotos), 更新图片: \(updatedPhotos), 删除图片: \(deletedPhotos.count)
            """)
    }

    /// 检查是否需要同步 - 每次启动都检查
    var needsSync: Bool {
        return true
    }

    // MARK: - Private

    /// 同步文章到知识库
    private func syncArticles(existingArticleIds: Set<String>) async throws
    -> (added: Int, updated: Int, currentIds: Set<String>) {

        // 分页获取所有文章
        var page = 1
        let pageSize = 100
        var allArticles: [Article] = []

        while true {
            let listPage = try await articleRepository.fetchList(
                page: page,
                pageSize: pageSize,
                nickName: nil,
                tags: nil,
                title: nil,
                sortBy: nil,
                sortOrder: nil
            )

            allArticles.append(contentsOf: listPage.articles)

            if listPage.articles.count < pageSize {
                break
            }
            page += 1
        }

        LogTool.shared.info("获取到 \(allArticles.count) 篇文章")

        var addedCount = 0
        var updatedCount = 0
        var currentIds = Set<String>()

        for article in allArticles {
            currentIds.insert(article.id)
            let documentId = "article-\(article.id)"

            // 检查是否已存在
            if existingArticleIds.contains(article.id) {
                // 已存在，跳过
                continue
            }

            // 新增文章，添加到知识库
            let content = buildArticleContent(article)
            let document = KBDocument(
                id: documentId,
                title: article.title,
                content: content,
                sourceType: .manual,
                sourcePath: nil,
                isDefault: true,
                chunks: []
            )

            try await processDocument(document)
            addedCount += 1
        }

        return (addedCount, updatedCount, currentIds)
    }

    /// 构建文章文档内容
    private func buildArticleContent(_ article: Article) -> String {
        var contentParts: [String] = []
        contentParts.append("# \(article.title)")
        if !article.summary.isEmpty {
            contentParts.append("## 摘要\n\(article.summary)")
        }
        if !article.tags.isEmpty {
            contentParts.append("## 标签\n\(article.tags.joined(separator: ", "))")
        }
        contentParts.append("## 正文\n\(article.content)")
        return contentParts.joined(separator: "\n\n")
    }

    /// 同步图片到知识库
    private func syncPhotos(existingPhotoIds: Set<String>) async throws
    -> (added: Int, updated: Int, currentIds: Set<String>) {

        let photos = try await photoRepository.fetchAll()
        LogTool.shared.info("获取到 \(photos.count) 张图片")

        var addedCount = 0
        var updatedCount = 0
        var currentIds = Set<String>()

        for photo in photos {
            currentIds.insert(photo.id)
            let documentId = "photo-\(photo.id)"

            // 检查是否已存在
            if existingPhotoIds.contains(photo.id) {
                continue
            }

            // 新增图片，添加到知识库
            let content = buildPhotoContent(photo)
            let document = KBDocument(
                id: documentId,
                title: photo.title,
                content: content,
                sourceType: .manual,
                sourcePath: nil,
                isDefault: true,
                chunks: []
            )

            try await processDocument(document)
            addedCount += 1
        }

        return (addedCount, updatedCount, currentIds)
    }

    /// 构建图片文档内容
    private func buildPhotoContent(_ photo: Photo) -> String {
        var contentParts: [String] = []
        contentParts.append("# \(photo.title)")

        if !photo.description.isEmpty {
            contentParts.append("## 描述\n\(photo.description)")
        }
        if !photo.tags.isEmpty {
            contentParts.append("## 标签\n\(photo.tags)")
        }

        // EXIF 信息
        var exifInfo: [String] = []
        if !photo.location.isEmpty {
            exifInfo.append("拍摄地点: \(photo.location)")
        }
        if !photo.camera.isEmpty {
            exifInfo.append("相机: \(photo.camera)")
        }
        if !photo.lens.isEmpty {
            exifInfo.append("镜头: \(photo.lens)")
        }
        exifInfo.append("ISO: \(photo.iso)")
        exifInfo.append("光圈: f/\(photo.aperture)")
        exifInfo.append("快门: \(photo.shutterSpeed)s")
        exifInfo.append("焦距: \(photo.focalLength)mm")

        if !exifInfo.isEmpty {
            contentParts.append("## 拍摄参数\n\(exifInfo.joined(separator: " | "))")
        }

        return contentParts.joined(separator: "\n\n")
    }

    /// 处理文档：分块并生成嵌入
    private func processDocument(_ document: KBDocument) async throws {
        // 分块
        let chunkTexts = chunkingService.chunkText(
            document.content,
            delimiter: ragConfig.chunkDelimiter,
            chunkSize: ragConfig.chunkSize
        )

        var chunks: [KBChunk] = []

        for (index, chunkText) in chunkTexts.enumerated() {
            // 生成嵌入
            let embedding = try await embeddingService.generateEmbedding(for: chunkText)

            let chunk = KBChunk(
                documentId: document.id,
                chunkIndex: index,
                content: chunkText,
                embedding: embedding
            )
            chunks.append(chunk)
        }

        // 创建新的文档实例（因为 document 是 let 常量）
        var updatedDocument = document
        updatedDocument.chunks = chunks

        // 保存
        try await knowledgeBaseStore.saveDocument(updatedDocument)
        LogTool.shared.debug("已添加默认知识: \(updatedDocument.title)")
    }

    /// 清理已删除的文档
    private func cleanupDeletedDocuments(
        deletedArticleIds: Set<String>,
        deletedPhotoIds: Set<String>
    ) async throws {

        // 获取所有默认文档
        let existingDocs = try await knowledgeBaseStore.fetchAllDocuments()
        let toDelete = existingDocs.filter { doc in
            if doc.id.hasPrefix("article-") {
                let articleId = String(doc.id.dropFirst(8))
                return deletedArticleIds.contains(articleId)
            } else if doc.id.hasPrefix("photo-") {
                let photoId = String(doc.id.dropFirst(6))
                return deletedPhotoIds.contains(photoId)
            }
            return false
        }

        // 删除已不存在的文档
        for doc in toDelete {
            try await knowledgeBaseStore.deleteDocument(doc)
            LogTool.shared.debug("已删除过期的默认知识: \(doc.title)")
        }
    }
}
