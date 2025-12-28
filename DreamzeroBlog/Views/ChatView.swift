//
//  ChatView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI
import Factory
import MarkdownUI

struct ChatView: View {
    @State private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool

    init(viewModel: ChatViewModel = Container.shared.chatViewModel()) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 消息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            // 流式传输中的加载指示器
                            if viewModel.isStreaming {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("正在思考...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // 新消息添加时滚动到底部
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isStreaming) { _, newValue in
                        // 流式传输时持续滚动到底部
                        if newValue, let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }

                Divider()

                // 输入区域
                inputArea
            }
            .navigationTitle("AI 对话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.clearChat) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .disabled(viewModel.messages.isEmpty || viewModel.isStreaming)
                }
            }
        }
    }

    // MARK: - 输入区域

    private var inputArea: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                // 文本输入框
                TextField("输入消息...", text: $viewModel.inputText, axis: .vertical)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...6)

                // 发送按钮
                Button(action: {
                    viewModel.sendMessage()
                    isInputFocused = false
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(canSendMessage ? .blue : .gray)
                }
                .disabled(!canSendMessage || viewModel.isStreaming)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - 辅助方法

    private var canSendMessage: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - 消息气泡

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // 角色标签
                Text(roleLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)

                // 消息内容
                if message.role == .user {
                    // 用户消息使用普通文本
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(backgroundColor)
                        .cornerRadius(16)
                } else {
                    // AI 助手消息使用 Markdown 渲染
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

                // 流式传输指示器
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
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
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

// MARK: - 预览

#Preview {
    ChatView()
}
