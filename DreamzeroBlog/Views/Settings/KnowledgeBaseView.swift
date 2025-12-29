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
    @State private var editingDocument: KBDocument?

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
            .sheet(item: $editingDocument) { document in
                if let viewModel = viewModel {
                    DocumentEditView(
                        document: document,
                        viewModel: viewModel,
                        isPresented: Binding(
                            get: { editingDocument != nil },
                            set: { if !$0 { editingDocument = nil } }
                        )
                    )
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
                    Button {
                        editingDocument = document
                    } label: {
                        DocumentRowView(document: document)
                    }
                    .buttonStyle(.plain)
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

    // 在初始化时捕获时间快照
    private let timeSnapshot: Date

    init(document: KBDocument) {
        self.document = document
        self.timeSnapshot = Date()
    }

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

                Text(relativeTimeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var relativeTimeString: String {
        let interval = timeSnapshot.timeIntervalSince(document.updatedAt)
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else {
            return "\(Int(interval / 86400))天前"
        }
    }
}

/// 文档编辑视图
struct DocumentEditView: View {
    let document: KBDocument
    let viewModel: KnowledgeBaseViewModel
    @Binding var isPresented: Bool

    @State private var title: String
    @State private var content: String
    @State private var isSaving = false

    init(document: KBDocument, viewModel: KnowledgeBaseViewModel, isPresented: Binding<Bool>) {
        self.document = document
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._title = State(initialValue: document.title)
        self._content = State(initialValue: document.content)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("标题", text: $title)
                        .textFieldStyle(.plain)

                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                } header: {
                    Text("文档信息")
                } footer: {
                    Text("编辑后将重新生成分块和向量嵌入")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("编辑文档")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveDocument()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             isSaving)
                }
            }
        }
    }

    private func saveDocument() {
        isSaving = true

        var updatedDocument = document
        updatedDocument.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedDocument.content = content.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            await viewModel.updateDocument(updatedDocument)
            await MainActor.run {
                isSaving = false
                isPresented = false
            }
        }
    }
}

#Preview {
    KnowledgeBaseView()
}
