//
//  ChunkBrowserView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct ChunkBrowserView: View {
    @Bindable var viewModel: ChunkBrowserViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedChunk: KBChunk?
    @FocusState private var focusedField: Bool

    var body: some View {
        NavigationStack {
            List {
                // 搜索栏
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("搜索分块", text: $viewModel.searchText)
                            .focused($focusedField)
                            .onSubmit {
                                Task {
                                    await viewModel.searchChunks()
                                }
                            }

                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.clearSearch()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        if viewModel.isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }

                // 搜索结果
                if !viewModel.searchResults.isEmpty {
                    Section {
                        ForEach(viewModel.searchResults) { result in
                            SearchResultRowView(result: result)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedChunk = result.chunk
                                }
                        }
                    } header: {
                        Text("搜索结果 (\(viewModel.searchResults.count))")
                    }
                }

                // 所有分块列表（当没有搜索时显示）
                if viewModel.searchText.isEmpty && !viewModel.chunks.isEmpty {
                    Section {
                        ForEach(viewModel.chunks) { chunk in
                            ChunkRowView(chunk: chunk)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedChunk = chunk
                                }
                        }
                    } header: {
                        Text("所有分块 (\(viewModel.chunks.count))")
                    }
                }

                // 空状态
                if viewModel.chunks.isEmpty && !viewModel.isSearching {
                    Section {
                        ContentUnavailableView(
                            "暂无分块",
                            systemImage: "rectangle.split.2x1.slash.fill"
                        )
                    }
                }
            }
            .navigationTitle("分块浏览器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedChunk) { chunk in
                ChunkPreviewSheet(chunk: chunk)
            }
            .onAppear {
                Task {
                    await viewModel.loadChunks()
                }
            }
        }
    }
}

/// 搜索结果行视图
struct SearchResultRowView: View {
    let result: KBSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(result.documentTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                Text(String(format: "%.1f%%", result.similarity * 100))
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(result.chunk.content)
                .font(.body)
                .lineLimit(4)
        }
        .padding(.vertical, 4)
    }
}

/// 分块行视图
struct ChunkRowView: View {
    let chunk: KBChunk

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Chunk \(chunk.chunkIndex)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if chunk.embedding != nil {
                    Label("已嵌入", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Label("未嵌入", systemImage: "xmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Text(chunk.content)
                .font(.body)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

/// 分块预览弹窗
struct ChunkPreviewSheet: View {
    let chunk: KBChunk
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 分块信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text("分块 #\(chunk.chunkIndex)")
                            .font(.headline)

                        HStack(spacing: 12) {
                            // 嵌入状态
                            if chunk.embedding != nil {
                                Label("已嵌入向量", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Label("未嵌入向量", systemImage: "xmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }

                            // 向量维度
                            if let embedding = chunk.embedding {
                                Text("维度: \(embedding.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // 创建时间
                        Text(formatDate(chunk.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)

                    Divider()

                    // 分块内容
                    VStack(alignment: .leading, spacing: 8) {
                        Text("内容")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(chunk.content)
                            .font(.body)
                            .lineSpacing(6)
                    }
                }
                .padding()
            }
            .navigationTitle("分块详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

#Preview {
    let schema = Schema([
        KBDocumentModel.self,
        KBChunkModel.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = ModelContext(container)

    let store = KnowledgeBaseStore(modelContext: context)
    let embeddingService = EmbeddingService()
    let chunkingService = ChunkingService()
    let kbViewModel = KnowledgeBaseViewModel(
        store: store,
        embeddingService: embeddingService,
        chunkingService: chunkingService
    )
    return ChunkBrowserView(viewModel: ChunkBrowserViewModel(knowledgeBaseVM: kbViewModel))
        .modelContainer(container)
}
