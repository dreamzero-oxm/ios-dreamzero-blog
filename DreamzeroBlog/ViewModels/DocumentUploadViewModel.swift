//
//  DocumentUploadViewModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation
import UniformTypeIdentifiers

/// 文档上传 ViewModel
@MainActor
@Observable
final class DocumentUploadViewModel {
    enum State: Equatable {
        case idle
        case importing
        case processing
        case completed
        case failed(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.importing, .importing), (.processing, .processing), (.completed, .completed):
                return true
            case (.failed(let lhsMsg), .failed(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }

    var state: State = .idle
    var selectedFileURL: URL?
    var fileContent: String = ""
    var documentTitle: String = ""
    var isProcessing = false

    private let knowledgeBaseVM: KnowledgeBaseViewModel

    init(knowledgeBaseVM: KnowledgeBaseViewModel) {
        self.knowledgeBaseVM = knowledgeBaseVM
    }

    func importDocument(from url: URL) async {
        state = .importing
        selectedFileURL = url

        do {
            // 检查安全范围的资源
            guard url.startAccessingSecurityScopedResource() else {
                state = .failed("无法访问文件")
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            // 读取文件内容
            let data = try Data(contentsOf: url)
            guard let content = String(data: data, encoding: .utf8) else {
                state = .failed("文件编码不支持")
                return
            }

            fileContent = content
            documentTitle = url.lastPathComponent
            state = .idle

            LogTool.shared.info("Document imported: \(url.lastPathComponent)")

        } catch {
            state = .failed(error.localizedDescription)
            LogTool.shared.error("Failed to import file: \(error)")
        }
    }

    func saveManualDocument(title: String, content: String) async {
        guard !title.isEmpty, !content.isEmpty else {
            state = .failed("请输入标题和内容")
            return
        }

        state = .processing
        await knowledgeBaseVM.addDocument(title: title, content: content)
        state = .completed
        fileContent = ""
        documentTitle = ""
    }

    func saveImportedDocument() async {
        guard !documentTitle.isEmpty, !fileContent.isEmpty else {
            state = .failed("请先导入文件")
            return
        }
        await saveManualDocument(title: documentTitle, content: fileContent)
    }

    func clearForm() {
        fileContent = ""
        documentTitle = ""
        selectedFileURL = nil
        state = .idle
    }
}
