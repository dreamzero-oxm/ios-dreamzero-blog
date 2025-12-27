//
//  ViewModelInject.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//

import Factory


extension Container {
    var photoListViewModel: Factory<PhotoListViewModel> {
        self { PhotoListViewModel(repo: self.photoRepository()) }
    }

    var registerViewModel: Factory<RegisterViewModel> {
        self { RegisterViewModel() }
    }

    // 文章相关 ViewModel
    var articleListViewModel: Factory<ArticleListViewModel> {
        self { ArticleListViewModel(repository: self.articleRepository()) }
    }

    var articleDetailViewModel: Factory<ArticleDetailViewModel> {
        self { ArticleDetailViewModel(repository: self.articleRepository()) }
    }

    // 聊天相关 ViewModel
    var chatViewModel: Factory<ChatViewModel> {
        self { ChatViewModel(repository: self.chatRepository()) }
    }
}
