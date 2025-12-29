//
//  DocumentUploadView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct DocumentUploadView: View {
    @Bindable var viewModel: DocumentUploadViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingFilePicker = false
    @State private var inputMode: InputMode = .manual
    @FocusState private var focusedField: Field?

    enum InputMode {
        case manual
        case file
    }

    enum Field {
        case title, content
    }

    var body: some View {
        NavigationStack {
            Form {
                // 模式选择
                Section {
                    Picker("输入方式", selection: $inputMode) {
                        Text("手动输入").tag(InputMode.manual)
                        Text("文件导入").tag(InputMode.file)
                    }
                    .pickerStyle(.segmented)
                }

                if inputMode == .manual {
                    // 手动输入
                    Section {
                        TextField("文档标题", text: $viewModel.documentTitle)
                            .focused($focusedField, equals: .title)

                        TextEditor(text: $viewModel.fileContent)
                            .frame(minHeight: 200)
                            .focused($focusedField, equals: .content)
                    } header: {
                        Text("手动输入")
                    }
                } else {
                    // 文件导入
                    Section {
                        Button {
                            showingFilePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading) {
                                    Text("选择文件")
                                        .font(.body)
                                    if let filename = viewModel.selectedFileURL?.lastPathComponent {
                                        Text(filename)
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    } else {
                                        Text("支持 .txt, .md 文件")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        if !viewModel.fileContent.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("预览:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(viewModel.fileContent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(5)
                            }
                        }
                    } header: {
                        Text("文件导入")
                    }
                }

                // 状态
                if viewModel.isProcessing {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在处理文档...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("添加文档")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            if inputMode == .file {
                                await viewModel.saveImportedDocument()
                            } else {
                                await viewModel.saveManualDocument(
                                    title: viewModel.documentTitle,
                                    content: viewModel.fileContent
                                )
                            }
                            if case .completed = viewModel.state {
                                dismiss()
                            }
                        }
                    }
                    .disabled(
                        viewModel.fileContent.isEmpty ||
                        viewModel.documentTitle.isEmpty ||
                        viewModel.isProcessing
                    )
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.plainText, .text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            await viewModel.importDocument(from: url)
                        }
                    }
                case .failure(let error):
                    LogTool.shared.error("File import failed: \(error)")
                }
            }
            .alert("错误", isPresented: .constant(viewModel.state.isError)) {
                Button("确定", role: .cancel) {}
            } message: {
                if case .failed(let message) = viewModel.state {
                    Text(message)
                }
            }
        }
    }
}

extension DocumentUploadViewModel.State {
    var isError: Bool {
        if case .failed = self { return true }
        return false
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
    return DocumentUploadView(viewModel: DocumentUploadViewModel(knowledgeBaseVM: kbViewModel))
        .modelContainer(container)
}
