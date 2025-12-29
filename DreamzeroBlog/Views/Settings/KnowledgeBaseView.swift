//
//  KnowledgeBaseView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

struct KnowledgeBaseView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: KnowledgeBaseViewModel
    @State private var showAddDocument = false
    @State private var showChunkBrowser = false
    @State private var uploadViewModel: DocumentUploadViewModel?
    @State private var browserViewModel: ChunkBrowserViewModel?

    init() {
        // 创建服务和存储
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
        let vectorSearchService = VectorSearchService()

        let kbViewModel = KnowledgeBaseViewModel(
            store: store,
            embeddingService: embeddingService,
            chunkingService: chunkingService,
            vectorSearchService: vectorSearchService
        )

        _viewModel = State(initialValue: kbViewModel)
        _uploadViewModel = State(initialValue: DocumentUploadViewModel(knowledgeBaseVM: kbViewModel))
        _browserViewModel = State(initialValue: ChunkBrowserViewModel(knowledgeBaseVM: kbViewModel))
    }

    var body: some View {
        NavigationStack {
            Group {
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
                if let uploadViewModel = uploadViewModel {
                    DocumentUploadView(viewModel: uploadViewModel)
                }
            }
            .sheet(isPresented: $showChunkBrowser) {
                if let browserViewModel = browserViewModel {
                    ChunkBrowserView(viewModel: browserViewModel)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadDocuments()
                }
            }
        }
    }

    private func deleteDocuments(offsets: IndexSet) {
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
