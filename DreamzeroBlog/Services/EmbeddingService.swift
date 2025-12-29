//
//  EmbeddingService.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import NaturalLanguage
import os.log

/// 嵌入服务协议
protocol EmbeddingServiceType {
    func generateEmbedding(for text: String) async throws -> [Double]
    func generateEmbeddings(for texts: [String]) async throws -> [[Double]]
}

/// 嵌入服务 - 使用 Apple NaturalLanguage 框架
final class EmbeddingService: EmbeddingServiceType {
    private let logger = Logger(subsystem: "com.dreamzero.rag", category: "Embedding")

    func generateEmbedding(for text: String) async throws -> [Double] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let embedding = try self.computeEmbedding(for: text)
                    continuation.resume(returning: embedding)
                } catch {
                    self.logger.error("Failed to generate embedding: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func generateEmbeddings(for texts: [String]) async throws -> [[Double]] {
        return try await withThrowingTaskGroup(of: (Int, [Double]).self) { group in
            for (index, text) in texts.enumerated() {
                group.addTask {
                    let embedding = try await self.generateEmbedding(for: text)
                    return (index, embedding)
                }
            }

            var results: [(Int, [Double])] = []
            for try await result in group {
                results.append(result)
            }

            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    // MARK: - Private Methods

    private func computeEmbedding(for text: String) throws -> [Double] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw EmbeddingError.emptyText
        }

        // 获取词嵌入模型（尝试多种语言）
        let embedding = NLEmbedding.wordEmbedding(for: .simplifiedChinese)

        guard let embedding = embedding else {
            logger.error("NLEmbedding unavailable")
            throw EmbeddingError.embeddingUnavailable
        }

        // 分词并获取句子嵌入（词向量平均）
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var vectors: [[Double]] = []

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let word = String(text[tokenRange])
            if let vector = embedding.vector(for: word) {
                var doubleVector: [Double] = []
                for i in 0..<vector.count {
                    doubleVector.append(Double(vector[i]))
                }
                vectors.append(doubleVector)
            }
            return true
        }

        guard !vectors.isEmpty else {
            logger.error("No vectors generated for text")
            throw EmbeddingError.noTokens
        }

        // 平均池化（Average Pooling）
        let dimension = vectors[0].count
        var averaged = [Double](repeating: 0.0, count: dimension)

        for vector in vectors {
            for i in 0..<dimension {
                averaged[i] += vector[i]
            }
        }

        for i in 0..<dimension {
            averaged[i] /= Double(vectors.count)
        }

        logger.info("Generated embedding with dimension: \(dimension)")
        return averaged
    }
}

/// 嵌入错误
enum EmbeddingError: LocalizedError {
    case emptyText
    case embeddingUnavailable
    case noTokens

    var errorDescription: String? {
        switch self {
        case .emptyText:
            return "文本为空"
        case .embeddingUnavailable:
            return "嵌入模型不可用"
        case .noTokens:
            return "无法从文本中提取词汇"
        }
    }
}
