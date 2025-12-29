//
//  ZhipuAIInject.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/28.
//

import Factory
import Foundation

extension Container {
    /// API配置
    /// 使用 .cached 确保配置变化时能够及时更新
    var apiConfiguration: Factory<APIConfiguration> {
        self { APIConfigurationStore.shared.currentConfiguration }.cached
    }

    /// 智谱AI API Key（向后兼容）
    /// 使用 .cached 确保只计算一次，避免多次读取导致的不一致
    var zhipuAPIKey: Factory<String> {
        self { () -> String in
            // 优先级0: 从APIConfigurationStore读取
            let config = APIConfigurationStore.shared.currentConfiguration
            if !config.apiKey.isEmpty {
                return config.apiKey
            }
            #if DEBUG
            // Debug 模式：优先从环境变量读取（开发时使用）
            if let apiKey = ProcessInfo.processInfo.environment["ZHIPU_API_KEY"], !apiKey.isEmpty {
                LogTool.shared.debug("✅ 已从环境变量读取到智谱AI API Key: \(apiKey.prefix(10))...")
                return apiKey
            }
            #endif

            // 方式1: 从 Bundle Info.plist 读取（通过 xcconfig 或直接配置）
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ZHIPU_API_KEY") as? String, !apiKey.isEmpty {
                LogTool.shared.debug("✅ 已从 Bundle 读取到智谱AI API Key: \(apiKey.prefix(10))...")
                return apiKey
            }

            // 方式2: 从 UserDefaults 读取（运行时配置）
            if let apiKey = UserDefaults.standard.string(forKey: "ZHIPU_API_KEY"), !apiKey.isEmpty {
                LogTool.shared.debug("✅ 已从 UserDefaults 读取到智谱AI API Key: \(apiKey.prefix(10))...")
                return apiKey
            }

            // 方式3: 从 Keychain 读取（安全存储）
            if let apiKey = KeychainHelper.read(key: "ZHIPU_API_KEY"), !apiKey.isEmpty {
                LogTool.shared.debug("✅ 已从 Keychain 读取到智谱AI API Key: \(apiKey.prefix(10))...")
                return apiKey
            }

            // 仅供腾讯菁英班测试,后续将不可用
            return "bdd85b6c47e14f6997ffefd4d92d4f34.nhPfPaeuFmSpQQEQ"
            
            // 默认返回空字符串，需要用户配置
            LogTool.shared.warning("⚠️ 智谱AI API Key未配置，请在设置中配置")
            return ""
        }.cached
    }
}

// MARK: - Keychain 辅助工具

enum KeychainHelper {
    private static let service = "com.dreamzero.blog"

    static func read(key: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    static func save(key: String, value: String) -> Bool {
        let data = value.data(using: .utf8)!

        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data
        ] as CFDictionary

        // 先删除旧值
        SecItemDelete(query)

        // 添加新值
        let status = SecItemAdd(query, nil)
        return status == errSecSuccess
    }

    static func delete(key: String) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ] as CFDictionary

        let status = SecItemDelete(query)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
