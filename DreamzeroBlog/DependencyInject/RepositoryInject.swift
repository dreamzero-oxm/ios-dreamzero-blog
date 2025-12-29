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
        self {
            let config = self.apiConfiguration()
            LogTool.shared.debug("🔧 ChatRepository 注入 API配置: \(config.provider.rawValue), URL: \(config.apiURL)")
            return ChatRepository(
                client: self.apiClient(),
                configuration: config
            )
        }
    }

    // MARK: - 注意
    // ChatSessionStore 需要在 View 层通过 @Environment(\.modelContext) 获取 ModelContext
    // 然后直接创建 ChatSessionStore(modelContext: modelContext)
    // 这是因为 Factory 无法直接注入 SwiftUI 的 Environment 变量
    //
    // 使用示例：
    // @Environment(\.modelContext) private var modelContext
    // private var sessionStore: ChatSessionStore {
    //     ChatSessionStore(modelContext: modelContext)
    // }
}
