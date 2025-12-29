//
//  APIConfigurationStore.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// API配置存储管理器
@Observable
final class APIConfigurationStore {
    /// 单例
    static let shared = APIConfigurationStore()

    /// 当前选中的服务商
    var currentProvider: APIProvider {
        didSet {
            // 保存到 UserDefaults（非敏感数据）
            UserDefaults.standard.set(currentProvider.rawValue, forKey: Self.kLastSelectedProvider)
            LogTool.shared.debug("✅ 已保存选择的服务商: \(currentProvider.rawValue)")
        }
    }

    /// 所有provider的配置字典
    private var configurations: [String: APIConfiguration] = [:]

    /// 当前配置（计算属性）
    var currentConfiguration: APIConfiguration {
        get {
            configurations[currentProvider.rawValue] ?? preset(for: currentProvider)
        }
        set {
            configurations[currentProvider.rawValue] = newValue
        }
    }

    private init() {
        // 从 UserDefaults 读取上次选择的服务商
        if let savedProviderRaw = UserDefaults.standard.string(forKey: Self.kLastSelectedProvider),
           let savedProvider = APIProvider.allCases.first(where: { $0.rawValue == savedProviderRaw }) {
            self.currentProvider = savedProvider
            LogTool.shared.debug("✅ 已恢复上次选择的服务商: \(savedProvider.rawValue)")
        } else {
            // 首次使用，默认选择智谱AI
            self.currentProvider = .zhipuAI
            LogTool.shared.debug("✅ 首次使用，默认服务商: 智谱AI")
        }

        loadAllConfigurations()
    }

    // MARK: - Keys

    /// 存储当前选中的服务商的键
    private static let kLastSelectedProvider = "API_LAST_SELECTED_PROVIDER"

    // MARK: - Key Keys

    private static func keyProvider(for provider: APIProvider) -> String {
        "API_CONFIG_\(provider.rawValue)_PROVIDER"
    }

    private static func keyAPIURL(for provider: APIProvider) -> String {
        "API_CONFIG_\(provider.rawValue)_URL"
    }

    private static func keyAPIKey(for provider: APIProvider) -> String {
        "API_CONFIG_\(provider.rawValue)_KEY"
    }

    private static func keyModel(for provider: APIProvider) -> String {
        "API_CONFIG_\(provider.rawValue)_MODEL"
    }

    private static func keyUseJWT(for provider: APIProvider) -> String {
        "API_CONFIG_\(provider.rawValue)_USE_JWT"
    }

    // MARK: - Load Configuration

    /// 加载所有provider的配置
    private func loadAllConfigurations() {
        for provider in APIProvider.allCases {
            if let config = Self.loadConfiguration(for: provider) {
                configurations[provider.rawValue] = config
            } else {
                // 使用预设作为默认值
                configurations[provider.rawValue] = preset(for: provider)
            }
        }
    }

    /// 加载单个provider的配置
    /// 优先级: Keychain > UserDefaults > Bundle (Secrets.xcconfig) > nil
    private static func loadConfiguration(for provider: APIProvider) -> APIConfiguration? {
        // 1. 尝试从 Keychain 读取
        if let config = loadFromKeychain(for: provider), config.isValid {
            LogTool.shared.debug("✅ 已从 Keychain 加载 \(provider.rawValue) API配置")
            return config
        }

        // 2. 尝试从 UserDefaults 读取
        if let config = loadFromUserDefaults(for: provider), config.isValid {
            LogTool.shared.debug("✅ 已从 UserDefaults 加载 \(provider.rawValue) API配置")
            // 保存到 Keychain 以便下次使用
            saveToKeychain(config, for: provider)
            return config
        }

        // 3. 尝试从 Bundle (Secrets.xcconfig) 读取（仅zhipuAI）
        if provider == .zhipuAI, let config = loadFromBundle() {
            LogTool.shared.debug("✅ 已从 Bundle 加载 \(provider.rawValue) API配置")
            // 保存到 Keychain
            saveToKeychain(config, for: provider)
            return config
        }

        return nil
    }

    /// 从 Keychain 加载单个provider配置
    private static func loadFromKeychain(for provider: APIProvider) -> APIConfiguration? {
        guard let apiURL = KeychainHelper.read(key: keyAPIURL(for: provider)),
              let apiKey = KeychainHelper.read(key: keyAPIKey(for: provider)),
              let model = KeychainHelper.read(key: keyModel(for: provider)) else {
            return nil
        }

        let useJWTRaw = KeychainHelper.read(key: keyUseJWT(for: provider))
        let useJWT = useJWTRaw == "true" || useJWTRaw == "1"

        return APIConfiguration(
            provider: provider,
            apiURL: apiURL,
            apiKey: apiKey,
            model: model,
            useJWT: useJWT
        )
    }

    /// 从 UserDefaults 加载单个provider配置
    private static func loadFromUserDefaults(for provider: APIProvider) -> APIConfiguration? {
        let defaults = UserDefaults.standard

        guard let apiURL = defaults.string(forKey: keyAPIURL(for: provider)),
              let apiKey = defaults.string(forKey: keyAPIKey(for: provider)),
              let model = defaults.string(forKey: keyModel(for: provider)) else {
            return nil
        }

        let useJWT = defaults.bool(forKey: keyUseJWT(for: provider))

        return APIConfiguration(
            provider: provider,
            apiURL: apiURL,
            apiKey: apiKey,
            model: model,
            useJWT: useJWT
        )
    }

    /// 从 Bundle (Secrets.xcconfig) 加载
    private static func loadFromBundle() -> APIConfiguration? {
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

    // MARK: - Save Configuration

    /// 保存配置
    func saveConfiguration(_ config: APIConfiguration) {
        let provider = config.provider

        // 保存到 Keychain
        Self.saveToKeychain(config, for: provider)

        // 保存到 UserDefaults (作为备份)
        Self.saveToUserDefaults(config, for: provider)

        // 更新字典
        configurations[provider.rawValue] = config

        LogTool.shared.debug("✅ \(provider.rawValue) API配置已保存")
    }

    /// 保存到 Keychain
    private static func saveToKeychain(_ config: APIConfiguration, for provider: APIProvider) {
        _ = KeychainHelper.save(key: keyAPIURL(for: provider), value: config.apiURL)
        _ = KeychainHelper.save(key: keyAPIKey(for: provider), value: config.apiKey)
        _ = KeychainHelper.save(key: keyModel(for: provider), value: config.model)
        _ = KeychainHelper.save(key: keyUseJWT(for: provider), value: String(config.useJWT))
    }

    /// 保存到 UserDefaults
    private static func saveToUserDefaults(_ config: APIConfiguration, for provider: APIProvider) {
        let defaults = UserDefaults.standard
        defaults.set(config.apiURL, forKey: keyAPIURL(for: provider))
        defaults.set(config.apiKey, forKey: keyAPIKey(for: provider))
        defaults.set(config.model, forKey: keyModel(for: provider))
        defaults.set(config.useJWT, forKey: keyUseJWT(for: provider))
    }

    // MARK: - Reset

    /// 重置指定provider为默认配置
    func resetToDefaults(for provider: APIProvider? = nil) {
        let targetProvider = provider ?? currentProvider
        let defaultConfig = preset(for: targetProvider)
        saveConfiguration(defaultConfig)
        LogTool.shared.debug("✅ \(targetProvider.rawValue) API配置已重置为默认值")
    }

    /// 重置指定provider为Bundle配置
    func resetToBundle(for provider: APIProvider? = nil) {
        let targetProvider = provider ?? currentProvider

        // 只有zhipuAI支持从Bundle重置
        guard targetProvider == .zhipuAI,
              let bundleConfig = Self.loadFromBundle() else {
            LogTool.shared.warning("⚠️ 只有智谱AI支持从Bundle重置")
            return
        }

        saveConfiguration(bundleConfig)
        LogTool.shared.debug("✅ \(targetProvider.rawValue) API配置已重置为Bundle配置")
    }

    /// 清除所有配置
    func clearConfiguration() {
        for provider in APIProvider.allCases {
            _ = KeychainHelper.delete(key: Self.keyProvider(for: provider))
            _ = KeychainHelper.delete(key: Self.keyAPIURL(for: provider))
            _ = KeychainHelper.delete(key: Self.keyAPIKey(for: provider))
            _ = KeychainHelper.delete(key: Self.keyModel(for: provider))
            _ = KeychainHelper.delete(key: Self.keyUseJWT(for: provider))

            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: Self.keyProvider(for: provider))
            defaults.removeObject(forKey: Self.keyAPIURL(for: provider))
            defaults.removeObject(forKey: Self.keyAPIKey(for: provider))
            defaults.removeObject(forKey: Self.keyModel(for: provider))
            defaults.removeObject(forKey: Self.keyUseJWT(for: provider))
        }

        configurations.removeAll()
        currentConfiguration = APIConfiguration.empty
        LogTool.shared.debug("✅ API配置已清除")
    }

    // MARK: - Helpers

    /// 获取provider的预设配置
    private func preset(for provider: APIProvider) -> APIConfiguration {
        let preset = APIProviderPreset.preset(for: provider)
        return APIConfiguration(
            provider: provider,
            apiURL: preset.apiURL,
            apiKey: "",
            model: preset.defaultModel,
            useJWT: provider.supportsJWT
        )
    }
}
