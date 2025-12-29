//
//  APIProviderPreset.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// API服务商预设配置
struct APIProviderPreset: Identifiable, Equatable, Sendable {
    let id: String
    let provider: APIProvider
    let name: String
    let apiURL: String
    let defaultModel: String
    let apiKeyPlaceholder: String
    let apiKeyFormat: String? // API Key格式提示

    /// 所有预设配置
    static let presets: [APIProviderPreset] = [
        APIProviderPreset(
            id: "zhipuai",
            provider: .zhipuAI,
            name: "智谱AI",
            apiURL: "https://open.bigmodel.cn/api/paas/v4",
            defaultModel: "glm-4.7",
            apiKeyPlaceholder: "请输入智谱AI API Key (格式: id.secret)",
            apiKeyFormat: "id.secret"
        ),
        APIProviderPreset(
            id: "zhipuai-plan",
            provider: .zhipuAIPlan,
            name: "智谱AI-Plan",
            apiURL: "https://open.bigmodel.cn/api/coding/paas/v4",
            defaultModel: "glm-4.7",
            apiKeyPlaceholder: "请输入智谱AI API Key (格式: id.secret)",
            apiKeyFormat: "id.secret"
        ),
        APIProviderPreset(
            id: "openai",
            provider: .openai,
            name: "OpenAI",
            apiURL: "https://api.openai.com/v1",
            defaultModel: "gpt-4o",
            apiKeyPlaceholder: "请输入OpenAI API Key (sk-开头)",
            apiKeyFormat: "sk-..."
        ),
        APIProviderPreset(
            id: "deepseek",
            provider: .deepseek,
            name: "DeepSeek",
            apiURL: "https://api.deepseek.com",
            defaultModel: "deepseek-chat",
            apiKeyPlaceholder: "请输入DeepSeek API Key (sk-开头)",
            apiKeyFormat: "sk-..."
        ),
        APIProviderPreset(
            id: "moonshot",
            provider: .moonshot,
            name: "Moonshot",
            apiURL: "https://api.moonshot.cn/v1",
            defaultModel: "moonshot-v1-8k",
            apiKeyPlaceholder: "请输入Moonshot API Key (sk-开头)",
            apiKeyFormat: "sk-..."
        ),
        APIProviderPreset(
            id: "azure",
            provider: .azure,
            name: "Azure OpenAI",
            apiURL: "https://your-resource.openai.azure.com",
            defaultModel: "gpt-4",
            apiKeyPlaceholder: "请输入Azure API Key",
            apiKeyFormat: nil
        ),
        APIProviderPreset(
            id: "custom",
            provider: .custom,
            name: "自定义",
            apiURL: "",
            defaultModel: "",
            apiKeyPlaceholder: "请输入API Key",
            apiKeyFormat: nil
        )
    ]

    /// 根据Provider获取预设
    static func preset(for provider: APIProvider) -> APIProviderPreset {
        presets.first { $0.provider == provider } ?? presets.last!
    }
}
