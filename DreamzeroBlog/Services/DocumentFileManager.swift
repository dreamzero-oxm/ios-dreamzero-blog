//
//  DocumentFileManager.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// 文档文件管理器 - 负责文档文件的存储和管理
final class DocumentFileManager {
    static let shared = DocumentFileManager()

    private let documentsDirectory: URL

    private init() {
        let fileManager = FileManager.default

        // 获取 Application Support 目录
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("无法获取 Application Support 目录")
        }

        // 创建 DreamzeroBlog 子目录
        let dreamzeroDirectory = appSupportURL.appendingPathComponent("DreamzeroBlog", isDirectory: true)

        // 创建 Documents 子目录
        self.documentsDirectory = dreamzeroDirectory.appendingPathComponent("Documents", isDirectory: true)

        // 创建目录（如果不存在）
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            do {
                try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
                LogTool.shared.info("Created documents directory: \(documentsDirectory.path)")
            } catch {
                LogTool.shared.error("Failed to create documents directory: \(error)")
            }
        }
    }

    /// 保存文档内容到文件
    func saveDocument(_ content: String, filename: String) throws -> URL {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        LogTool.shared.info("Document saved: \(fileURL.path)")
        return fileURL
    }

    /// 从文件加载文档内容
    func loadDocument(from url: URL) throws -> String {
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// 删除文档文件
    func deleteDocument(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
        LogTool.shared.info("Document deleted: \(url.path)")
    }

    /// 获取文档目录
    func getDocumentsDirectory() -> URL {
        return documentsDirectory
    }

    /// 检查文件是否存在
    func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
