//
//  VectorSearchService.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// 向量搜索服务协议
protocol VectorSearchServiceType {
    func search(queryEmbedding: [Double], chunks: [KBChunk], topK: Int) -> [KBSearchResult]
}

/// 向量搜索服务 - 使用余弦相似度
final class VectorSearchService: VectorSearchServiceType {
    func search(queryEmbedding: [Double], chunks: [KBChunk], topK: Int) -> [KBSearchResult] {
        // 过滤出有嵌入向量的分块
        let chunksWithEmbeddings = chunks.filter { $0.embedding != nil }

        guard !chunksWithEmbeddings.isEmpty else {
            return []
        }

        // 计算每个分块的余弦相似度
        var results: [(chunk: KBChunk, similarity: Double)] = []

        for chunk in chunksWithEmbeddings {
            guard let embedding = chunk.embedding else { continue }
            guard embedding.count == queryEmbedding.count else { continue }
            let similarity = cosineSimilarity(queryEmbedding, embedding)
            results.append((chunk: chunk, similarity: similarity))
        }

        // 按相似度降序排序并取前 K 个
        results.sort { $0.similarity > $1.similarity }
        let topResults = Array(results.prefix(topK).filter { $0.similarity > 0 } )

        // 转换为搜索结果
        return topResults.map { result in
            KBSearchResult(
                id: UUID().uuidString,
                chunk: result.chunk,
                documentTitle: "", // 将由调用者填充
                similarity: result.similarity
            )
        }
    }

    // MARK: - Similarity Calculation

    /// 计算余弦相似度
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0.0 }

        var dotProduct = 0.0
        var normA = 0.0
        var normB = 0.0

        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }

        let denominator = sqrt(normA) * sqrt(normB)
        guard denominator != 0 else { return 0.0 }

        return dotProduct / denominator
    }
}
