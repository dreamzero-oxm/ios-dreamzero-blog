//
//  RAGConfigurationStore.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// RAG 配置管理
@Observable
final class RAGConfigurationStore {
    static let shared = RAGConfigurationStore()

    // MARK: - Settings

    /// 是否启用 RAG
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.ragEnabled) }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.ragEnabled)
            LogTool.shared.info("RAG enabled: \(newValue)")
        }
    }

    /// Top-K 检索数量
    var topK: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: Keys.topK)
            return value > 0 ? value : 3
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.topK)
            LogTool.shared.info("RAG topK: \(newValue)")
        }
    }

    /// 分块分隔符
    var chunkDelimiter: String {
        get { UserDefaults.standard.string(forKey: Keys.chunkDelimiter) ?? "\n" }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.chunkDelimiter)
            LogTool.shared.info("RAG chunk delimiter: \(newValue)")
        }
    }

    /// 分块大小
    var chunkSize: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: Keys.chunkSize)
            return value > 0 ? value : 500
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.chunkSize)
            LogTool.shared.info("RAG chunk size: \(newValue)")
        }
    }

    /// 是否使用自定义 Prompt
    var useCustomPrompt: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.useCustomPrompt) }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.useCustomPrompt)
            LogTool.shared.info("RAG use custom prompt: \(newValue)")
        }
    }

    /// 自定义 Prompt 模板
    var customPromptTemplate: String {
        get {
            UserDefaults.standard.string(forKey: Keys.customPromptTemplate) ?? defaultPromptTemplate
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.customPromptTemplate)
            LogTool.shared.info("RAG custom prompt template updated")
        }
    }

    // MARK: - Default Values

    /// 默认 Prompt 模板
    let defaultPromptTemplate = """
    基于以下知识库内容回答问题。如果知识库中没有相关信息，请忽略知识库的内容。

    知识库内容：
    {context}

    用户问题：
    {query}
    """

    // MARK: - Initialization

    private init() {
        // 设置默认值（如果不存在）
        if !UserDefaults.standard.bool(forKey: "RAG_INITIALIZED") {
            resetToDefaults()
            UserDefaults.standard.set(true, forKey: "RAG_INITIALIZED")
        }
    }

    // MARK: - Methods

    /// 重置为默认值
    func resetToDefaults() {
        isEnabled = true
        topK = 3
        chunkDelimiter = "\n"
        chunkSize = 500
        useCustomPrompt = false
        customPromptTemplate = defaultPromptTemplate
        LogTool.shared.info("RAG settings reset to defaults")
    }

    /// 获取当前 Prompt 模板
    func getCurrentPromptTemplate() -> String {
        return useCustomPrompt ? customPromptTemplate : defaultPromptTemplate
    }

    /// 构建带上下文的 Prompt
    func buildPrompt(context: String, query: String) -> String {
        let template = getCurrentPromptTemplate()
        return template
            .replacingOccurrences(of: "{context}", with: context)
            .replacingOccurrences(of: "{query}", with: query)
    }

    // MARK: - Keys

    enum Keys {
        static let ragEnabled = "RAG_ENABLED"
        static let topK = "RAG_TOP_K"
        static let chunkDelimiter = "RAG_CHUNK_DELIMITER"
        static let chunkSize = "RAG_CHUNK_SIZE"
        static let useCustomPrompt = "RAG_USE_CUSTOM_PROMPT"
        static let customPromptTemplate = "RAG_CUSTOM_PROMPT_TEMPLATE"
    }
}
