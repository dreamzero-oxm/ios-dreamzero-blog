//
//  MessageBubble.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI
import MarkdownUI

struct MessageBubble: View, Equatable {
    let message: ChatMessage
    var onCopy: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                AvatarView(role: message.role, size: 32)
            }

            messageContent

            if message.role == .user {
                AvatarView(role: message.role, size: 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .padding(.horizontal, 8)
    }

    private var messageContent: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
            roleLabelView
            messageContentView
            streamingIndicator

            // 添加来源列表（仅助手消息）
            if message.role == .assistant && !message.sources.isEmpty {
                MessageSourcesView(sources: message.sources)
            }

            copyButton
        }
        .frame(maxWidth: 300, alignment: message.role == .user ? .trailing : .leading)
    }

    private var roleLabelView: some View {
        Text(roleLabel)
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var messageContentView: some View {
        Group {
            if message.role == .user {
                userMessageView
            } else if message.isStreaming || !message.prefersMarkdown {
                // 流式输出时：使用纯文本渲染（高性能）
                plainTextView
            } else {
                // 流式结束后：使用 Markdown 渲染（完整格式）
                assistantMessageView
            }
        }
        .contextMenu {
            Button {
                copyToClipboard(message.content)
                onCopy?()
            } label: {
                Label("复制", systemImage: "doc.on.doc")
            }
        }
    }

    private var userMessageView: some View {
        Text(message.content)
            .font(.body)
            .foregroundColor(.white)
            .padding(12)
            .background(backgroundColor)
            .cornerRadius(16)
    }

    // 纯文本视图（流式输出时使用，避免 Markdown 重复解析）
    private var plainTextView: some View {
        Text(message.content)
            .font(.body)
            .foregroundColor(.primary)
            .padding(12)
            .background(backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 0.5)
            )
            .textSelection(.enabled)
    }

    private var assistantMessageView: some View {
        Markdown(message.content)
            .markdownTheme(.bubble)
            .padding(12)
            .background(backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 0.5)
            )
    }

    @ViewBuilder
    private var streamingIndicator: some View {
        if message.isStreaming {
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("输入中...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private var copyButton: some View {
        if !message.isStreaming {
            Button(action: {
                copyToClipboard(message.content)
                onCopy?()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                    Text("复制")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6).opacity(0.8))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }

    static func == (lhs: MessageBubble, rhs: MessageBubble) -> Bool {
        lhs.message.id == rhs.message.id &&
        lhs.message.isStreaming == rhs.message.isStreaming &&
        lhs.message.prefersMarkdown == rhs.message.prefersMarkdown &&
        lhs.message.content.count == rhs.message.content.count
    }

    private var roleLabel: String {
        switch message.role {
        case .user:
            return "你"
        case .assistant:
            return "AI 助手"
        case .system:
            return "系统"
        }
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return Color(.systemGray6)
        case .system:
            return Color(.systemYellow).opacity(0.3)
        }
    }

    private var borderColor: Color {
        switch message.role {
        case .user:
            return .clear
        case .assistant:
            return Color(.systemGray4)
        case .system:
            return Color(.systemYellow)
        }
    }
}
