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
}
