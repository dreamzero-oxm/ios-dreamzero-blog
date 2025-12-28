//
//  ZhipuAIInject.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/28.
//

import Factory
import Foundation

extension Container {
    /// 智谱AI API Key
    /// 使用 .cached 确保只计算一次，避免多次读取导致的不一致
    var zhipuAPIKey: Factory<String> {
        self { () -> String in
            // 方式1: 从环境变量读取（Xcode Scheme 中设置）
            if let apiKey = ProcessInfo.processInfo.environment["ZHIPU_API_KEY"], !apiKey.isEmpty {
                LogTool.shared.debug("✅ 已从环境变量读取到智谱AI API Key: \(apiKey.prefix(10))...")
                return apiKey
            }

            // 方式2: 从 User-Defined Build Settings 读取（通过 xcconfig）
            if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ZHIPU_API_KEY") as? String, !apiKey.isEmpty {
                LogTool.shared.debug("✅ 已从 Build Settings 读取到智谱AI API Key: \(apiKey.prefix(10))...")
                return apiKey
            }

            // 方式3: 直接硬编码（仅用于测试）
            // return "your-api-key-here"

            // 默认返回空字符串，需要用户配置
            LogTool.shared.warning("⚠️ 智谱AI API Key未配置")
            return ""
        }.cached
    }
}
