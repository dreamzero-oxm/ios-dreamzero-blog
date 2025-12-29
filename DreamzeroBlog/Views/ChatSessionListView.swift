//
//  ChatSessionListView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import SwiftData

/// 聊天会话列表视图
struct ChatSessionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSessionModel.updatedAt, order: .reverse) private var sessionModels: [ChatSessionModel]

    let onSelectSession: (ChatSession) -> Void
    let onDeleteSession: (ChatSession) -> Void

    var body: some View {
        Group {
            if sessionModels.isEmpty {
                emptyStateView
            } else {
                listView
            }
        }
    }

    private var listView: some View {
        List {
            // 会话列表
            ForEach(sessionModels.map { $0.toDomainModel() }) { session in
                Button(action: { onSelectSession(session) }) {
                    ChatSessionCell(session: session)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onDeleteSession(session)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        onDeleteSession(session)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "message.badge")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))

            VStack(spacing: 8) {
                Text("暂无对话历史")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("点击上方「+」按钮开始新对话")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// 聊天会话单元格
struct ChatSessionCell: View {
    let session: ChatSession

    // 使用固定的基准时间（打开列表时的时间）
    @State private var displayTime: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "message.circle")
                .font(.system(size: 32))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(displayTime.isEmpty ? timeString(from: session.updatedAt) : displayTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            // 在首次出现时计算并固定显示时间
            displayTime = timeString(from: session.updatedAt)
        }
    }

    private func timeString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else {
            let days = Int(interval / 86400)
            return "\(days)天前"
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ChatSessionModel.self, configurations: config)

    // 添加示例数据
    let context = container.mainContext
    let session1 = ChatSessionModel(title: "SwiftUI 入门教程", createdAt: Date().addingTimeInterval(-86400), updatedAt: Date().addingTimeInterval(-3600))
    let session2 = ChatSessionModel(title: "SwiftData 持久化方案...", createdAt: Date().addingTimeInterval(-172800), updatedAt: Date().addingTimeInterval(-7200))
    context.insert(session1)
    context.insert(session2)

    return NavigationStack {
        ChatSessionListView(
            onSelectSession: { _ in },
            onDeleteSession: { _ in }
        )
    }
    .modelContainer(container)
}
