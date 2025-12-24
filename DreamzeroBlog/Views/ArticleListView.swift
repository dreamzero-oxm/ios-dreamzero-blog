//
//  ArticleListView.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import SwiftUI
import Factory

struct ArticleListView: View {
    @State private var vm: ArticleListViewModel = Container.shared.articleListViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch vm.state {
                case .idle, .loading:
                    ProgressView("加载中...")
                        .task { vm.load() }

                case .loaded:
                    List {
                        ForEach(vm.articles) { article in
                            NavigationLink(destination: ArticleDetailView(articleId: article.id)) {
                                ArticleCell(article: article)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                            // 当滚动到倒数第3个时触发加载更多
                            if vm.articles.isLast(article, offset: 3) && vm.hasMore {
                                Color.clear
                                    .task {
                                        vm.loadMore()
                                    }
                            }
                        }

                        // 加载更多指示器
                        if vm.hasMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        vm.refresh()
                    }

                case .failed(let msg):
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("加载失败").font(.headline)
                        Text(msg).font(.footnote).foregroundColor(.secondary)
                        Button("重试", action: vm.load)
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 32)
                }
            }
            .navigationTitle("文章列表")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 文章列表单元格

struct ArticleCell: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 封面图
            if let coverImage = article.coverImage,
               !coverImage.isEmpty {
                let fullURL = coverImage.hasPrefix("http://") || coverImage.hasPrefix("https://")
                              ? coverImage
                              : "https://www.dreamzero.com" + coverImage

                ImageLoader(url: fullURL)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            // 标题
            Text(article.title)
                .font(.headline)
                .lineLimit(2)

            // 摘要
            Text(article.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // 标签
            if !article.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(article.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }

            // 作者和统计信息
            HStack {
                // 作者头像
//                if let avatar = article.user.avatar {
//                    ImageLoader(url: avatar)
//                        .frame(width: 24, height: 24)
//                        .clipShape(Circle())
//                }

                // 作者名称
//                Text(article.user.nickname)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//
//                Spacer()

                // 统计信息
                HStack(spacing: 12) {
                    Label("\(article.viewCount)", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(article.likeCount)", systemImage: "heart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Array 扩展

extension Array {
    /// 判断元素是否是数组中的倒数第 offset 个元素
    func isLast(_ element: Element, offset: Int = 1) -> Bool {
        guard let index = firstIndex(where: { $0 as AnyObject === element as AnyObject }) else {
            return false
        }
        return index >= count - offset
    }
}

// MARK: - Preview

struct ArticleListView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleListView()
    }
}
