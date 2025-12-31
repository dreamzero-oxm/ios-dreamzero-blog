//
//  EmptyStateView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI

struct EmptyStateView: View {
    let recentSessions: [ChatSession]
    var onSelectSession: ((ChatSession) -> Void)?

    init(recentSessions: [ChatSession], onSelectSession: ((ChatSession) -> Void)? = nil) {
        self.recentSessions = recentSessions
        self.onSelectSession = onSelectSession
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                // 顶部空状态提示
                VStack(spacing: 12) {
                    Image(systemName: "message.badge")
                        .font(.system(size: 50))
                        .foregroundColor(.blue.opacity(0.6))

                    Text("开始对话")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("发送消息，AI 助手将随时为您服务")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Text("内容由 AI 生成，请仔细甄别")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                // 最近会话列表
                if !recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近会话")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 8) {
                            ForEach(recentSessions) { session in
                                Button(action: {
                                    onSelectSession?(session)
                                }) {
                                    RecentSessionCell(session: session)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .transition(.opacity)
                }

                Spacer().frame(minHeight: 40)
            }
        }
    }
}
