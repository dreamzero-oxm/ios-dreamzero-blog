//
//  MessageSourcesView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI

struct MessageSourcesView: View {
    let sources: [MessageSource]

    @State private var showAll: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 来源列表标题/折叠按钮（仅超过3条时显示）
            if sources.count > 3 {
                Button(action: { showAll.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)

                        Text(sourceSummary)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Image(systemName: showAll ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            // 来源列表（默认显示前三条，点击后显示全部）
            VStack(alignment: .leading, spacing: 4) {
                ForEach(displayedSources) { source in
                    SourceRow(source: source)
                }
            }
            .padding(.leading, 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }

    /// 计算要显示的来源列表
    private var displayedSources: [MessageSource] {
        if sources.count <= 3 || showAll {
            return sources
        }
        return Array(sources.prefix(3))
    }

    private var sourceSummary: String {
        let webCount = sources.filter { $0.type == .webSearch }.count
        let kbCount = sources.filter { $0.type == .knowledgeBase }.count

        if webCount > 0 && kbCount > 0 {
            return "引用 \(webCount) 个网络来源 · \(kbCount) 个知识库文件"
        } else if webCount > 0 {
            return "引用 \(webCount) 个网络来源"
        } else if kbCount > 0 {
            return "引用 \(kbCount) 个知识库文件"
        }
        return "来源引用"
    }
}

struct SourceRow: View {
    let source: MessageSource

    var body: some View {
        Group {
            if source.type == .webSearch, let url = source.url {
                // 联网搜索结果 - 可点击
                if let validUrl = URL(string: url) {
                    Link(destination: validUrl) {
                        HStack(spacing: 4) {
                            Image(systemName: "safari")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(source.title)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                } else {
                    // URL 无效时的降级显示
                    HStack(spacing: 4) {
                        Image(systemName: "safari")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(source.title)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            } else {
                // 知识库文件 - 仅展示
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text(source.title)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if let similarity = source.similarity {
                        Text(String(format: "%.1f%%", similarity * 100))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }
}
