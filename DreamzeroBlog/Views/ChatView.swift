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
        .onReceive(NotificationCenter.default.publisher(for: .streamContentDidUpdate)) { _ in
            scrollToBottom(proxy: proxy, animated: false)
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

// MARK: - 预览

#Preview {
    ChatView()
}
