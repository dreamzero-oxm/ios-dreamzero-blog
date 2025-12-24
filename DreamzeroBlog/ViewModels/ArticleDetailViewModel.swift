//
//  ArticleDetailViewModel.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import Foundation
import Observation
import Factory

@Observable
final class ArticleDetailViewModel {
    enum State {
        case idle          // 初始空闲
        case loading       // 正在加载
        case loaded        // 已成功加载
        case failed(String) // 加载失败
    }

    // 可观测状态
    var state: State = .idle
    var article: Article?

    // 依赖
    private let repository: ArticleRepositoryType

    // 构造器注入（测试友好）
    init(repository: ArticleRepositoryType) {
        self.repository = repository
    }

    // 便捷构造：从容器解析
    convenience init(container: Container = .shared) {
        self.init(repository: container.articleRepository())
    }

    // 加载文章详情
    func load(articleId: String? = nil) {
        guard let articleId = articleId else {
            state = .failed("Invalid article ID")
            return
        }
        // 防重复
        if case .loading = state { return }
        state = .loading
        Task { await fetch(articleId: articleId) }
    }

    private func fetch(articleId: String) async {
        do {
            let article = try await repository.getDetail(articleId: articleId)
            await MainActor.run {
                self.article = article
                self.state = .loaded
            }
        } catch {
            await MainActor.run {
                self.state = .failed(error.localizedDescription)
            }
        }
    }
}
