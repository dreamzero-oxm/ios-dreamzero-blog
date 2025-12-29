//
//  APIConfiguration.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation

/// API服务商预设
enum APIProvider: String, CaseIterable, Identifiable, Codable {
    case zhipuAI = "智谱AI"
    case zhipuAIPlan = "智谱AI-Plan"
    case openai = "OpenAI"
    case deepseek = "DeepSeek"
    case moonshot = "Moonshot"
    case azure = "Azure OpenAI"
    case custom = "自定义"

    var id: String { rawValue }

    /// 是否支持JWT Token认证
    var supportsJWT: Bool {
        switch self {
        case .zhipuAI, .zhipuAIPlan:
            return true
        default:
            return false
        }
    }
}

/// API配置模型
struct APIConfiguration: Codable, Equatable, Sendable {
    /// 服务商
    var provider: APIProvider

    /// API基础URL
    var apiURL: String

    /// API Key
    var apiKey: String

    /// 模型名称
    var model: String

    /// 是否使用JWT Token（仅对支持的服务商有效）
    var useJWT: Bool

    /// 是否支持JWT（计算属性）
    var supportsJWT: Bool {
        provider.supportsJWT
    }

    /// 默认配置
    static let `default` = APIConfiguration(
        provider: .zhipuAI,
        apiURL: "https://open.bigmodel.cn/api/paas/v4",
        apiKey: "",
        model: "glm-4.7",
        useJWT: true
    )

    /// 空配置
    static let empty = APIConfiguration(
        provider: .custom,
        apiURL: "",
        apiKey: "",
        model: "",
        useJWT: false
    )

    /// 验证配置是否有效
    var isValid: Bool {
        !apiURL.isEmpty && !apiKey.isEmpty && !model.isEmpty
    }
}
