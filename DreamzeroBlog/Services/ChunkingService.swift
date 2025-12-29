//
//  ChunkingService.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// 分块服务协议
protocol ChunkingServiceType {
    func chunkText(_ text: String, delimiter: String, chunkSize: Int) -> [String]
}

/// 文本分块服务
final class ChunkingService: ChunkingServiceType {
    func chunkText(_ text: String, delimiter: String, chunkSize: Int) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""
        var currentLength = 0

        // 按分隔符切分
        let segments = text.components(separatedBy: delimiter)

        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)
            let segmentLength = trimmed.count

            // 跳过空片段
            if segmentLength == 0 { continue }

            // 如果单个片段超过分块大小，强制拆分
            if segmentLength > chunkSize {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                    currentChunk = ""
                    currentLength = 0
                }
                chunks.append(contentsOf: forceSplit(trimmed, maxSize: chunkSize))
                continue
            }

            // 如果添加此片段会超过分块大小
            if currentLength + segmentLength > chunkSize && !currentChunk.isEmpty {
                chunks.append(currentChunk)
                currentChunk = ""
                currentLength = 0
            }

            // 将片段添加到当前分块
            if currentChunk.isEmpty {
                currentChunk = trimmed
            } else {
                currentChunk += delimiter + trimmed
            }
            currentLength = currentChunk.count
        }

        // 添加最后一个分块
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        // 为每个分块添加索引标记
        return chunks.enumerated().map { index, chunk in
            "[Chunk \(index + 1)] \(chunk)"
        }
    }

    // MARK: - Private Methods

    /// 强制拆分过长的文本
    private func forceSplit(_ text: String, maxSize: Int) -> [String] {
        var chunks: [String] = []
        var start = text.startIndex

        while start < text.endIndex {
            let end = text.index(
                start,
                offsetBy: min(maxSize, text.distance(from: start, to: text.endIndex))
            )
            let chunk = String(text[start..<end])
            chunks.append(chunk)
            start = end
        }

        return chunks
    }
}
