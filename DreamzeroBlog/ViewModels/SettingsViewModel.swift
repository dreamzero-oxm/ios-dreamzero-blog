//
//  SettingsViewModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// 设置页面ViewModel
@Observable
final class SettingsViewModel {
    /// API配置
    var apiConfiguration: APIConfiguration {
        didSet {
            configurationChanged = true
        }
    }

    /// 配置是否已更改
    private(set) var configurationChanged: Bool = false

    /// 保存中状态
    private(set) var isSaving: Bool = false

    /// 测试连接中状态
    private(set) var isTesting: Bool = false

    /// 测试结果消息
    private(set) var testResult: String?

    private let store = APIConfigurationStore.shared

    init() {
        self.apiConfiguration = store.currentConfiguration
    }

    // MARK: - Save Configuration

    /// 保存API配置
    func saveConfiguration() {
        isSaving = true

        // 保存到Store
        store.saveConfiguration(apiConfiguration)

        configurationChanged = false
        isSaving = false

        LogTool.shared.debug("✅ API配置已保存")
    }

    /// 重置配置
    func resetConfiguration() {
        apiConfiguration = store.currentConfiguration
        configurationChanged = false
    }

    /// 重置为默认值
    func resetToDefaults() {
        apiConfiguration = APIConfiguration.default
        configurationChanged = true
    }

    /// 重置为Bundle配置
    func resetToBundle() {
        if let bundleConfig = loadBundleConfiguration() {
            apiConfiguration = bundleConfig
            configurationChanged = true
        }
    }

    // MARK: - Test Connection

    /// 测试API连接
    func testConnection() async -> Bool {
        isTesting = true
        testResult = nil

        defer {
            isTesting = false
        }

        // 简单验证配置有效性
        guard !apiConfiguration.apiURL.isEmpty else {
            testResult = "请输入API URL"
            return false
        }

        guard !apiConfiguration.apiKey.isEmpty else {
            testResult = "请输入API Key"
            return false
        }

        guard !apiConfiguration.model.isEmpty else {
            testResult = "请输入模型名称"
            return false
        }

        // 验证URL格式
        guard let _ = URL(string: apiConfiguration.apiURL) else {
            testResult = "API URL格式不正确"
            return false
        }

        // 如果是智谱AI且开启了JWT，验证API Key格式
        if apiConfiguration.provider == .zhipuAI && apiConfiguration.useJWT {
            let parts = apiConfiguration.apiKey.split(separator: ".")
            if parts.count != 2 {
                testResult = "智谱AI API Key格式应为 id.secret"
                return false
            }
        }

        testResult = "配置验证通过"
        return true
    }

    // MARK: - Preset Selection

    /// 应用预设配置
    func applyPreset(_ preset: APIProviderPreset) {
        let newConfig = APIConfiguration(
            provider: preset.provider,
            apiURL: preset.apiURL,
            apiKey: apiConfiguration.apiKey, // 保留用户输入的API Key
            model: preset.defaultModel,
            useJWT: preset.provider.supportsJWT
        )
        apiConfiguration = newConfig
    }

    // MARK: - Private Helpers

    private func loadBundleConfiguration() -> APIConfiguration? {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "ZHIPU_API_KEY") as? String,
              !apiKey.isEmpty else {
            return nil
        }

        return APIConfiguration(
            provider: .zhipuAI,
            apiURL: "https://open.bigmodel.cn/api/paas/v4",
            apiKey: apiKey,
            model: "glm-4.7",
            useJWT: true
        )
    }
}
