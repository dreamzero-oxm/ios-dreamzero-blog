//
//  APIConfigViewModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// API配置表单ViewModel
@Observable
final class APIConfigViewModel {
    /// 当前选中的服务商
    var selectedProvider: APIProvider {
        didSet {
            onProviderChanged()
        }
    }

    /// API URL
    var apiURL: String

    /// API Key
    var apiKey: String

    /// 模型名称
    var model: String

    /// 是否使用JWT
    var useJWT: Bool

    /// 表单验证错误
    var validationError: String?

    private var configuration: APIConfiguration

    init(configuration: APIConfiguration) {
        self.configuration = configuration
        self.selectedProvider = configuration.provider
        self.apiURL = configuration.apiURL
        self.apiKey = configuration.apiKey
        self.model = configuration.model
        self.useJWT = configuration.useJWT
    }

    // MARK: - Provider Change

    private func onProviderChanged() {
        let preset = APIProviderPreset.preset(for: selectedProvider)

        // 更新URL和模型，但保留API Key（用户可能已经输入）
        apiURL = preset.apiURL
        model = preset.defaultModel

        // 如果服务商不支持JWT，关闭JWT开关
        if !selectedProvider.supportsJWT {
            useJWT = false
        } else if selectedProvider.supportsJWT && useJWT == false {
            // 如果服务商支持JWT且当前关闭，可以选择自动开启
            useJWT = true
        }
    }

    // MARK: - Validation

    /// 验证表单
    func validate() -> Bool {
        // 验证API URL
        guard !apiURL.isEmpty else {
            validationError = "请输入API URL"
            return false
        }

        guard let _ = URL(string: apiURL) else {
            validationError = "API URL格式不正确"
            return false
        }

        // 验证API Key
        guard !apiKey.isEmpty else {
            validationError = "请输入API Key"
            return false
        }

        // 验证模型名称
        guard !model.isEmpty else {
            validationError = "请输入模型名称"
            return false
        }

        // 验证智谱AI API Key格式（如果开启JWT）
        if selectedProvider == .zhipuAI && useJWT {
            let parts = apiKey.split(separator: ".")
            if parts.count != 2 {
                validationError = "智谱AI API Key格式应为 id.secret"
                return false
            }
        }

        validationError = nil
        return true
    }

    // MARK: - Build Configuration

    /// 构建配置对象
    func buildConfiguration() -> APIConfiguration? {
        guard validate() else {
            return nil
        }

        return APIConfiguration(
            provider: selectedProvider,
            apiURL: apiURL,
            apiKey: apiKey,
            model: model,
            useJWT: useJWT
        )
    }

    // MARK: - API Key Masking

    /// 获取掩码后的API Key（用于显示）
    static func maskAPIKey(_ apiKey: String) -> String {
        if apiKey.isEmpty {
            return ""
        }

        if apiKey.count <= 8 {
            return String(repeating: "*", count: apiKey.count)
        }

        let prefix = String(apiKey.prefix(4))
        let suffix = String(apiKey.suffix(4))
        let masked = String(repeating: "*", count: min(8, apiKey.count - 8))
        return "\(prefix)\(masked)\(suffix)"
    }
}
