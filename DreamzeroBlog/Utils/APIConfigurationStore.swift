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

    /// 当前配置
    var currentConfiguration: APIConfiguration

    private init() {
        self.currentConfiguration = Self.loadConfiguration()
    }

    // MARK: - Key Keys

    private static let keyProvider = "API_CONFIG_PROVIDER"
    private static let keyAPIURL = "API_CONFIG_URL"
    private static let keyAPIKey = "API_CONFIG_KEY"
    private static let keyModel = "API_CONFIG_MODEL"
    private static let keyUseJWT = "API_CONFIG_USE_JWT"

    // MARK: - Load Configuration

    /// 加载配置
    /// 优先级: Keychain > UserDefaults > Bundle (Secrets.xcconfig) > 默认值
    private static func loadConfiguration() -> APIConfiguration {
        // 1. 尝试从 Keychain 读取
        if let config = loadFromKeychain(), config.isValid {
            LogTool.shared.debug("✅ 已从 Keychain 加载API配置")
            return config
        }

        // 2. 尝试从 UserDefaults 读取
        if let config = loadFromUserDefaults(), config.isValid {
            LogTool.shared.debug("✅ 已从 UserDefaults 加载API配置")
            // 保存到 Keychain 以便下次使用
            saveToKeychain(config)
            return config
        }

        // 3. 尝试从 Bundle (Secrets.xcconfig) 读取
        if let config = loadFromBundle(), config.isValid {
            LogTool.shared.debug("✅ 已从 Bundle 加载API配置")
            // 保存到 Keychain
            saveToKeychain(config)
            return config
        }

        // 4. 返回默认配置
        LogTool.shared.warning("⚠️ 未找到API配置，使用默认配置")
        return APIConfiguration.default
    }

    /// 从 Keychain 加载
    private static func loadFromKeychain() -> APIConfiguration? {
        guard let providerRaw = KeychainHelper.read(key: keyProvider),
              let provider = APIProvider(rawValue: providerRaw),
              let apiURL = KeychainHelper.read(key: keyAPIURL),
              let apiKey = KeychainHelper.read(key: keyAPIKey),
              let model = KeychainHelper.read(key: keyModel),
              let useJWTRaw = KeychainHelper.read(key: keyUseJWT) else {
            return nil
        }

        return APIConfiguration(
            provider: provider,
            apiURL: apiURL,
            apiKey: apiKey,
            model: model,
            useJWT: Bool(useJWTRaw) ?? true
        )
    }

    /// 从 UserDefaults 加载
    private static func loadFromUserDefaults() -> APIConfiguration? {
        let defaults = UserDefaults.standard

        guard let providerRaw = defaults.string(forKey: keyProvider),
              let provider = APIProvider(rawValue: providerRaw),
              let apiURL = defaults.string(forKey: keyAPIURL),
              let apiKey = defaults.string(forKey: keyAPIKey),
              let model = defaults.string(forKey: keyModel) else {
            return nil
        }

        let useJWT = defaults.bool(forKey: keyUseJWT)

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
        // 保存到 Keychain
        Self.saveToKeychain(config)

        // 保存到 UserDefaults (作为备份)
        Self.saveToUserDefaults(config)

        // 更新当前配置
        currentConfiguration = config

        LogTool.shared.debug("✅ API配置已保存")
    }

    /// 保存到 Keychain
    private static func saveToKeychain(_ config: APIConfiguration) {
        KeychainHelper.save(key: keyProvider, value: config.provider.rawValue)
        KeychainHelper.save(key: keyAPIURL, value: config.apiURL)
        KeychainHelper.save(key: keyAPIKey, value: config.apiKey)
        KeychainHelper.save(key: keyModel, value: config.model)
        KeychainHelper.save(key: keyUseJWT, value: String(config.useJWT))
    }

    /// 保存到 UserDefaults
    private static func saveToUserDefaults(_ config: APIConfiguration) {
        let defaults = UserDefaults.standard
        defaults.set(config.provider.rawValue, forKey: keyProvider)
        defaults.set(config.apiURL, forKey: keyAPIURL)
        defaults.set(config.apiKey, forKey: keyAPIKey)
        defaults.set(config.model, forKey: keyModel)
        defaults.set(config.useJWT, forKey: keyUseJWT)
    }

    // MARK: - Reset

    /// 重置为默认配置
    func resetToDefaults() {
        let defaultConfig = APIConfiguration.default
        saveConfiguration(defaultConfig)
        LogTool.shared.debug("✅ API配置已重置为默认值")
    }

    /// 重置为Bundle配置
    func resetToBundle() {
        if let bundleConfig = Self.loadFromBundle() {
            saveConfiguration(bundleConfig)
            LogTool.shared.debug("✅ API配置已重置为Bundle配置")
        }
    }

    /// 清除配置
    func clearConfiguration() {
        KeychainHelper.delete(key: Self.keyProvider)
        KeychainHelper.delete(key: Self.keyAPIURL)
        KeychainHelper.delete(key: Self.keyAPIKey)
        KeychainHelper.delete(key: Self.keyModel)
        KeychainHelper.delete(key: Self.keyUseJWT)

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.keyProvider)
        defaults.removeObject(forKey: Self.keyAPIURL)
        defaults.removeObject(forKey: Self.keyAPIKey)
        defaults.removeObject(forKey: Self.keyModel)
        defaults.removeObject(forKey: Self.keyUseJWT)

        currentConfiguration = APIConfiguration.empty
        LogTool.shared.debug("✅ API配置已清除")
    }
}
