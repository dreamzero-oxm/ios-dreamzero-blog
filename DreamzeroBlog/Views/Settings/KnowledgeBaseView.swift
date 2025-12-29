//
//  KnowledgeBaseView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData
import Factory

struct KnowledgeBaseView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddDocument = false
    @State private var showChunkBrowser = false

    // 使用依赖注入容器获取服务
    private var knowledgeBaseStore: KnowledgeBaseStoreType {
        KnowledgeBaseStore(modelContext: modelContext)
    }

    private var embeddingService: EmbeddingServiceType {
        Container.shared.embeddingService()
    }

    private var chunkingService: ChunkingServiceType {
        Container.shared.chunkingService()
    }

    private var vectorSearchService: VectorSearchServiceType {
        Container.shared.vectorSearchService()
    }

    // ViewModel 在 onAppear 中初始化
    @State private var viewModel: KnowledgeBaseViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    contentView(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("知识库")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showChunkBrowser = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddDocument = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddDocument) {
                if let viewModel = viewModel {
                    DocumentUploadView(viewModel: DocumentUploadViewModel(knowledgeBaseVM: viewModel))
                }
            }
            .sheet(isPresented: $showChunkBrowser) {
                if let viewModel = viewModel {
                    ChunkBrowserView(viewModel: ChunkBrowserViewModel(knowledgeBaseVM: viewModel))
                }
            }
            .onAppear {
                initializeViewModel()
            }
        }
    }

    @ViewBuilder
    private func contentView(viewModel: KnowledgeBaseViewModel) -> some View {
        if viewModel.documents.isEmpty && (viewModel.state == .idle || viewModel.state == .loaded) {
            ContentUnavailableView(
                "暂无知识库文档",
                systemImage: "doc.text",
                description: Text("点击 + 添加文档")
            )
        } else {
            List {
                ForEach(viewModel.documents) { document in
                    DocumentRowView(document: document)
                        .contentShape(Rectangle())
                }
                .onDelete(perform: deleteDocuments)
            }
        }
    }

    private func initializeViewModel() {
        guard viewModel == nil else { return }

        let kbViewModel = KnowledgeBaseViewModel(
            store: knowledgeBaseStore,
            embeddingService: embeddingService,
            chunkingService: chunkingService,
            vectorSearchService: vectorSearchService
        )
        self.viewModel = kbViewModel

        Task {
            await kbViewModel.loadDocuments()
        }
    }

    private func deleteDocuments(offsets: IndexSet) {
        guard let viewModel = viewModel else { return }
        Task {
            for index in offsets {
                await viewModel.deleteDocument(viewModel.documents[index])
            }
        }
    }
}

/// 文档行视图
struct DocumentRowView: View {
    let document: KBDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(document.title)
                .font(.headline)
                .lineLimit(1)

            HStack {
                Label("\(document.chunks.count) 个分块", systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(document.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    KnowledgeBaseView()
}
