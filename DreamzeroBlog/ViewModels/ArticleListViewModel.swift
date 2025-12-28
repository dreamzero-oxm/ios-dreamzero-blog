//
//  ArticleListViewModel.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import Foundation
import Observation
import Factory

@Observable
final class ArticleListViewModel {
    enum State {
        case idle          // 初始空闲：尚未触发加载
        case loading       // 正在加载：可显示菊花/骨架屏
        case loaded        // 已成功加载：展示内容
        case failed(String) // 加载失败：携带错误信息用于提示
    }

    // 可观测状态（注意：在主线程更新）
    var state: State = .idle
    var articles: [Article] = []

    // 分页相关
    private var currentPage: Int = 1
    private var pageSize: Int = 10
    private var total: Int = 0
    private(set) var hasMore: Bool = true

    // 筛选条件
    private var nickName: String?
    private var tags: [String]?
    private var title: String?
    private var sortBy: String?
    private var sortOrder: String?
    

    // 是否正在加载更多（避免重复触发）
    private var isLoadingMore: Bool = false

    // 依赖
    private let repository: ArticleRepositoryType

    // 构造器注入（测试友好）
    init(repository: ArticleRepositoryType) {
        self.repository = repository
    }

    // 便捷构造：从容器解析（可选）
    convenience init(container: Container = .shared) {
        self.init(repository: container.articleRepository())
    }

    // 设置筛选条件
    func setFilter(nickName: String? = nil, tags: [String]? = nil, title: String? = nil, sortBy: String? = nil, sortOrder: String? = nil) {
        self.nickName = nickName
        self.tags = tags
        self.title = title
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }

    // 加载第一页数据
    func load() {
        // 防重复
        if case .loading = state { return }
        state = .loading
        currentPage = 1
        Task { await fetch() }
    }

    // 刷新数据（重新加载第一页）
    func refresh() {
        currentPage = 1
        Task { await fetch() }
    }

    // 加载更多数据
    func loadMore() {
        guard hasMore && !isLoadingMore else { return }
        isLoadingMore = true
        currentPage += 1
        Task { await fetchMore() }
    }

    private func fetch() async {
        do {
            let pageData = try await repository.fetchList(
                page: currentPage,
                pageSize: pageSize,
                nickName: nickName,
                tags: tags,
                title: title,
                sortBy: sortBy,
                sortOrder: sortOrder
            )

            await MainActor.run {
                self.articles = pageData.articles
                self.total = pageData.total
                self.hasMore = pageData.hasMore
                self.state = .loaded
            }
        } catch {
            await MainActor.run {
                self.state = .failed(error.localizedDescription)
            }
        }
    }

    private func fetchMore() async {
        do {
            let pageData = try await repository.fetchList(
                page: currentPage,
                pageSize: pageSize,
                nickName: nickName,
                tags: tags,
                title: title,
                sortBy: sortBy,
                sortOrder: sortOrder
            )

            await MainActor.run {
                self.articles.append(contentsOf: pageData.articles)
                self.total = pageData.total
                self.hasMore = pageData.hasMore
                self.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingMore = false
                // 加载更多失败不改变状态，只打印日志
                LogTool.shared.error("Load more articles failed: \(error.localizedDescription)")
            }
        }
    }
}
