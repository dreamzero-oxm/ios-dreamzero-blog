//
//  ApiClientInject.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//

import Factory
import Foundation

extension Container {
    // APIClient（单例）
    var apiClient: Factory<APIClient> {
        self {
            APIClient(
                baseURL: URL(string: "https://www.dreamzero.cn")!,
                timeout: 30,
                additionalHeaders: nil,
                eventMonitors: [NetworkLogger()],
                interceptors: [LoggingInterceptor()]
            )
        }.singleton
    }

    // 智谱AI API Key
    // TODO: 请替换为您的智谱AI API Key
    // 可以从环境变量或配置文件中读取
    var zhipuAPIKey: Factory<String> {
        self {
            // 方式1: 直接硬编码（不推荐，仅用于测试）
            // return "your-api-key-here"

            // 方式2: 从环境变量读取（推荐）
            if let apiKey = ProcessInfo.processInfo.environment["ZHIPU_API_KEY"] {
                return apiKey
            }

            // 方式3: 从Info.plist读取（需要先在Info.plist中配置）
            // if let apiKey = Bundle.main.object(forInfoDictionaryKey: "ZhipuAPIKey") as? String {
            //     return apiKey
            // }

            // 默认返回空字符串，需要用户配置
            LogTool.shared.warning("⚠️ 智谱AI API Key未配置，请在ApiClientInject.swift中设置")
            return ""
        }
    }
}
