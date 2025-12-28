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
            contentView
                .navigationTitle("AI 对话")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
        }
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            messageListView
            Divider()
            inputArea
        }
    }

    private var messageListView: some View {
        ScrollViewReader { proxy in
            messagesScrollView(proxy: proxy)
        }
    }

    private func messagesScrollView(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            messageList
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isInputFocused = false
        }
        .onChange(of: viewModel.messages.count) { _, _ in
            scrollToBottom(proxy: proxy)
        }
        .onChange(of: viewModel.isStreaming) { _, _ in
            if viewModel.isStreaming {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }

    private var messageList: some View {
        LazyVStack(spacing: 16) {
            messageBubbles
//            streamingIndicator
        }
        .padding()
    }

    private var messageBubbles: some View {
        ForEach(viewModel.messages) { message in
            MessageBubble(message: message)
                .id(message.id)
        }
    }

    private var streamingIndicator: some View {
        Group {
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
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.clearChat) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .disabled(viewModel.messages.isEmpty || viewModel.isStreaming)
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
            Text("内容由AI生成，请仔细甄别")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - 辅助方法

    private var canSendMessage: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastMessage = viewModel.messages.last else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

// MARK: - 消息气泡

struct MessageBubble: View, Equatable {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            messageContent

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }

    private var messageContent: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
            roleLabelView
            messageContentView
            streamingIndicator
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
        if message.role == .user {
            userMessageView
        } else {
            assistantMessageView
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

    static func == (lhs: MessageBubble, rhs: MessageBubble) -> Bool {
        lhs.message == rhs.message
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
