//
//  ArticleDetailView.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//

import SwiftUI
import Factory

struct ArticleDetailView: View {
    let articleId: String

    @State private var vm: ArticleDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(articleId: String) {
        self.articleId = articleId
        _vm = State(initialValue: Container.shared.articleDetailViewModel())
    }

    var body: some View {
        NavigationStack {
            Group{
                switch vm.state {
                case .idle, .loading:
                    ProgressView("加载中...")
                        .task {
                            vm.load(articleId: articleId)
                        }

                case .loaded:
                    if let article = vm.article {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // 封面图
                                if let coverImage = article.coverImage,
                                   !coverImage.isEmpty {
                                    ImageLoader(url: coverImage)
                                        .frame(height: 250)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                // 标题
                                Text(article.title)
                                    .font(.title)
                                    .fontWeight(.bold)

                                // 作者信息
                                HStack {
//                                    if let avatar = article.user.avatar {
//                                        ImageLoader(url: avatar)
//                                            .frame(width: 40, height: 40)
//                                            .clipShape(Circle())
//                                    }
//
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text(article.user.nickname)
//                                            .font(.subheadline)
//                                            .fontWeight(.semibold)
//
//                                        if let bio = article.user.bio {
//                                            Text(bio)
//                                                .font(.caption)
//                                                .foregroundColor(.secondary)
//                                        }
//                                    }

//                                    Spacer()

                                    // 发布时间
                                    if let publishedAt = article.publishedAt {
                                        Text(formatDate(publishedAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                // 统计信息
                                HStack(spacing: 20) {
                                    Label("\(article.viewCount)", systemImage: "eye")
                                    Label("\(article.likeCount)", systemImage: "heart")
                                    Label("\(article.tags.count)", systemImage: "tag")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                                // 标签
                                if !article.tags.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(article.tags, id: \.self) { tag in
                                                Text("#\(tag)")
                                                    .font(.subheadline)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.blue.opacity(0.1))
                                                    .foregroundColor(.blue)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    }
                                }

                                Divider()

                                // 文章内容
                                Text(article.content)
                                    .font(.body)
                                    .lineSpacing(8)
                            }
                            .padding()
                        }
                    } else {
                        Text("文章不存在")
                            .foregroundColor(.secondary)
                    }

                case .failed(let msg):
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("加载失败").font(.headline)
                        Text(msg).font(.footnote).foregroundColor(.secondary)
                        Button("重试", action: { vm.load(articleId: articleId) })
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 32)
                }
            }
            .navigationTitle("文章详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }

    // 格式化日期
    func formatDate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: isoString) else { return isoString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        displayFormatter.locale = Locale(identifier: "zh_CN")
        return displayFormatter.string(from: date)
    }
}

// MARK: - Preview

struct ArticleDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleDetailView(articleId: "preview-id")
    }
}
