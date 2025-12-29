//
//  ViewModelInject.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//

import Factory


extension Container {
    var photoListViewModel: Factory<PhotoListViewModel> {
        self { @MainActor in PhotoListViewModel(repo: self.photoRepository()) }
    }

    var registerViewModel: Factory<RegisterViewModel> {
        self { @MainActor in RegisterViewModel() }
    }

    // 文章相关 ViewModel
    var articleListViewModel: Factory<ArticleListViewModel> {
        self { @MainActor in ArticleListViewModel(repository: self.articleRepository()) }
    }

    var articleDetailViewModel: Factory<ArticleDetailViewModel> {
        self { @MainActor in ArticleDetailViewModel(repository: self.articleRepository()) }
    }

    // 聊天相关 ViewModel
    var chatViewModel: Factory<ChatViewModel> {
        self { @MainActor in
            ChatViewModel(
                repository: self.chatRepository(),
                ragConfig: .shared,
                knowledgeBaseStore: self.knowledgeBaseStore(),
                embeddingService: self.embeddingService()
            )
        }
    }
}
