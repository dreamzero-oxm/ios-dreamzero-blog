//
//  ChatView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI
import Factory
import MarkdownUI
import SwiftData

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct ChatView: View {
    @FocusState private var isInputFocused: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var showSessionList: Bool = false
    @State private var showCopyToast: Bool = false

    // 使用 Factory 创建的 ViewModel（不带 sessionStore）
    @State private var baseViewModel: ChatViewModel = Container.shared.chatViewModel()

    // 直接观察 shared store，无需本地 @State
    private var apiConfigStore: APIConfigurationStore { .shared }

    // 最近会话查询
    @Query(
        sort: \ChatSessionModel.updatedAt,
        order: .reverse
    ) private var recentSessionModels: [ChatSessionModel]

    // 计算属性：获取最近5条会话
    private var recentSessions: [ChatSession] {
        recentSessionModels.prefix(5).map { $0.toDomainModel() }
    }

    // 创建带 sessionStore 的 ViewModel
    private var viewModel: ChatViewModel {
        let sessionStore = ChatSessionStore(modelContext: modelContext)
        return ChatViewModel(
            repository: Container.shared.chatRepository(),
            sessionStore: sessionStore,
            ragConfig: .shared,
            knowledgeBaseStore: Container.shared.knowledgeBaseStore(),
            embeddingService: Container.shared.embeddingService(),
            webSearchService: Container.shared.webSearchService()
        )
    }

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("AI 对话")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showSessionList) {
                    SessionListSheet(
                        modelContext: modelContext,
                        baseViewModel: $baseViewModel
                    )
                }
                .overlay(alignment: .top) {
                    if showCopyToast {
                        CopyToastView()
                    }
                }
        }
        .onAppear {
            // 如果显示正在流式传输但没有实际的任务，重置状态
            if baseViewModel.isStreaming {
                // 检查是否有正在流式的消息
                let hasStreamingMessage = baseViewModel.messages.contains { $0.isStreaming }
                if !hasStreamingMessage {
                    // 没有正在流式的消息但状态显示为流式中，重置状态
                    baseViewModel.stopStreaming()
                }
            }
            syncViewModel()
        }
        .onDisappear {
            // 页面消失时取消正在进行的流式传输
            if baseViewModel.isStreaming {
                baseViewModel.stopStreaming()
            }
        }
    }

    private func syncViewModel() {
        let sessionStore = ChatSessionStore(modelContext: modelContext)
        let vm = ChatViewModel(
            repository: Container.shared.chatRepository(),
            sessionStore: sessionStore,
            ragConfig: .shared,
            knowledgeBaseStore: Container.shared.knowledgeBaseStore(),
            embeddingService: Container.shared.embeddingService(),
            webSearchService: Container.shared.webSearchService()
        )

        // 检查是否有正在流式的消息
        let hasStreamingMessage = baseViewModel.messages.contains { $0.isStreaming }

        vm.messages = baseViewModel.messages
        vm.currentSession = baseViewModel.currentSession
        vm.state = baseViewModel.state

        // 如果没有实际正在流式的消息，重置状态
        vm.isStreaming = hasStreamingMessage ? baseViewModel.isStreaming : false
        vm.inputText = baseViewModel.inputText

        baseViewModel = vm
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
        .onChange(of: baseViewModel.messages.count) { _, _ in
            scrollToBottom(proxy: proxy)
        }
        .onChange(of: baseViewModel.isStreaming) { _, _ in
            if baseViewModel.isStreaming {
                scrollToBottom(proxy: proxy, animated: false)
            }
        }
    }

    private var messageList: some View {
        Group {
            if baseViewModel.messages.isEmpty {
                EmptyStateView(
                    recentSessions: recentSessions,
                    onSelectSession: { session in
                        Task {
                            await baseViewModel.loadSession(session)
                        }
                    }
                )
            } else {
                LazyVStack(spacing: 16) {
                    messageBubbles
                }
                .padding()
            }
        }
    }

    private var messageBubbles: some View {
        ForEach(baseViewModel.messages) { message in
            MessageBubble(message: message) {
                showCopyToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showCopyToast = false
                }
            }
            .id(message.id)
        }
    }

    private var streamingIndicator: some View {
        Group {
            if baseViewModel.isStreaming {
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
            HStack(spacing: 16) {
                // 新建会话按钮
                Button(action: {
                    Task {
                        await baseViewModel.createNewSession()
                    }
                }) {
                    Image(systemName: "plus.circle")
                }

                // API配置切换按钮
                Menu {
                    ForEach(APIProvider.allCases) { provider in
                        Button(action: {
                            switchAPIProvider(provider)
                        }) {
                            HStack {
                                Text(provider.rawValue)
                                if apiConfigStore.currentProvider == provider {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }

                // 会话列表按钮
                Button(action: { showSessionList = true }) {
                    Image(systemName: "ellipsis.circle")
                }

//                // 清空按钮
//                Button(action: baseViewModel.clearChat) {
//                    Image(systemName: "trash")
//                        .foregroundColor(.red)
//                }
//                .disabled(baseViewModel.messages.isEmpty || baseViewModel.isStreaming)
            }
        }
    }

    // MARK: - 输入区域

    private var inputArea: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                // 文本输入框
                TextField("输入消息...", text: $baseViewModel.inputText, axis: .vertical)
                    .focused($isInputFocused)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(1...6)
                    .disabled(baseViewModel.isStreaming)

                // 使用新的条件按钮
                inputActionButton
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 4)

            Text("内容由AI生成，请仔细甄别")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - 辅助方法

    private var canSendMessage: Bool {
        !baseViewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @ViewBuilder
    private var inputActionButton: some View {
        if baseViewModel.isStreaming {
            // 停止按钮
            Button(action: {
                baseViewModel.stopStreaming()
            }) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
        } else {
            // 发送按钮
            Button(action: {
                baseViewModel.sendMessage()
                isInputFocused = false
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(canSendMessage ? .blue : .gray)
            }
            .disabled(!canSendMessage)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard let lastMessage = baseViewModel.messages.last else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }

    // MARK: - API Provider 切换

    private func switchAPIProvider(_ provider: APIProvider) {
        // 切换API配置
        APIConfigurationStore.shared.currentProvider = provider

        // 显示提示
        LogTool.shared.debug("✅ 已切换到 \(provider.rawValue)")

        // 重新创建chatViewModel以使用新配置
        syncViewModel()
    }
}

// MARK: - 消息头像

struct AvatarView: View {
    let role: MessageRole
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: height)

            Image(systemName: iconName)
                .font(.system(size: size * 0.5))
                .foregroundColor(.white)
        }
    }

    private var iconName: String {
        switch role {
        case .user:
            return "person.circle.fill"
        case .assistant:
            return "brain.head.profile"
        case .system:
            return "info.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch role {
        case .user:
            return .blue
        case .assistant:
            return .purple
        case .system:
            return .orange
        }
    }

    private var height: CGFloat {
        size
    }
}

// MARK: - 空状态视图

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

/// 最近会话单元格（简化版）
struct RecentSessionCell: View {
    let session: ChatSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "message.circle")
                .font(.system(size: 24))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Text(relativeTimeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var relativeTimeString: String {
        let interval = Date().timeIntervalSince(session.updatedAt)
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else {
            return "\(Int(interval / 86400))天前"
        }
    }
}

// MARK: - 消息气泡

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
            } else {
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

// MARK: - Copy Toast View

struct CopyToastView: View {
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = -20

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("已复制")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .cornerRadius(20)
        .padding(.top, 8)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
                offset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 0
                    offset = -20
                }
            }
        }
    }
}

// MARK: - Clipboard Utility

func copyToClipboard(_ text: String) {
    #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    #elseif os(iOS)
        UIPasteboard.general.string = text
    #endif
}

// MARK: - 预览

#Preview {
    ChatView()
}

// MARK: - 会话列表弹窗

struct SessionListSheet: View {
    let modelContext: ModelContext
    @Binding var baseViewModel: ChatViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ChatSessionListView(
                onSelectSession: { session in
                    Task {
                        await baseViewModel.loadSession(session)
                        dismiss()
                    }
                },
                onDeleteSession: { session in
                    Task {
                        await baseViewModel.deleteSession(session)
                    }
                }
            )
            .navigationTitle("对话历史")
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
}
