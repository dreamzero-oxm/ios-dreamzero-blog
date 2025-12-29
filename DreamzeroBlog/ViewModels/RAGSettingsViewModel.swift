//
//  RAGSettingsViewModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// RAG 设置 ViewModel
@MainActor
@Observable
final class RAGSettingsViewModel {
    var isEnabled: Bool
    var topK: Int
    var chunkDelimiter: String
    var chunkSize: Int
    var useCustomPrompt: Bool
    var customPromptTemplate: String

    private let store: RAGConfigurationStore

    init(store: RAGConfigurationStore = .shared) {
        self.store = store
        self.isEnabled = store.isEnabled
        self.topK = store.topK
        self.chunkDelimiter = store.chunkDelimiter
        self.chunkSize = store.chunkSize
        self.useCustomPrompt = store.useCustomPrompt
        self.customPromptTemplate = store.customPromptTemplate
    }

    func saveSettings() {
        store.isEnabled = isEnabled
        store.topK = topK
        store.chunkDelimiter = chunkDelimiter
        store.chunkSize = chunkSize
        store.useCustomPrompt = useCustomPrompt
        store.customPromptTemplate = customPromptTemplate
        LogTool.shared.info("RAG settings saved")
    }

    func resetToDefaults() {
        store.resetToDefaults()
        loadSettings()
        LogTool.shared.info("RAG settings reset to defaults")
    }

    func loadSettings() {
        isEnabled = store.isEnabled
        topK = store.topK
        chunkDelimiter = store.chunkDelimiter
        chunkSize = store.chunkSize
        useCustomPrompt = store.useCustomPrompt
        customPromptTemplate = store.customPromptTemplate
    }
}
