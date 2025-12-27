//
//  RepositoryInject.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//

import Foundation
import Factory

extension Container {
    // Repository
    // 注册 PhotoRepository
    var photoRepository: Factory<PhotoRepositoryType> {
        self { PhotoRepository(client: self.apiClient()) }
    }

    // 注册 ArticleRepository
    var articleRepository: Factory<ArticleRepositoryType> {
        self { ArticleRepository(client: self.apiClient()) }
    }

    // 注册 ChatRepository（智谱AI）
    var chatRepository: Factory<ChatRepositoryType> {
        self { ChatRepository(apiKey: self.zhipuAPIKey()) }
    }
}
