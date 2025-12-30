//
//  ApiClientInject.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//

import Factory
import Foundation

extension Container {
    // TokenStore（单例）
    var tokenStore: Factory<TokenStore> {
        self {
            let config = KeychainConfiguration(service: "com.dreamzero.blog")
            let secureStore = KeychainAccessStore(config: config)
            return TokenStore(store: secureStore)
        }.singleton
    }

    // APIClient（单例）
    // Uses AuthInterceptor for automatic token refresh
    var apiClient: Factory<APIClient> {
        self {
            let baseURL = URL(string: "https://www.dreamzero.cn")!

            // Create logging interceptor
            let loggingInterceptor = LoggingInterceptor()

            // Create a temporary client without auth for UserRepository (TokenRefresher)
            // This breaks the circular dependency between APIClient and AuthInterceptor
            let tempClient = APIClient(
                baseURL: baseURL,
                timeout: 30,
                additionalHeaders: nil,
                eventMonitors: [NetworkLogger(), loggingInterceptor],
                interceptors: []
            )

            // Create UserRepository which implements TokenRefresher
            let userRepository = UserRepository(client: tempClient)

            // Create AuthInterceptor with TokenStore and TokenRefresher
            let authInterceptor = AuthInterceptor(
                tokenStore: self.tokenStore(),
                refresher: userRepository
            )

            // Create final APIClient with AuthInterceptor
            return APIClient(
                baseURL: baseURL,
                timeout: 30,
                additionalHeaders: nil,
                eventMonitors: [NetworkLogger(), loggingInterceptor],
                interceptors: [authInterceptor]
            )
        }.singleton
    }
}
