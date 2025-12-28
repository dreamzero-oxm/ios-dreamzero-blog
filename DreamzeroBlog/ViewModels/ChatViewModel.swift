//
//  ChatViewModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import Foundation
import Observation
import Factory

@MainActor
@Observable
final class ChatViewModel {
    enum State {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // 可观测状态
    var state: State = .idle
    var messages: [ChatMessage] = []
    var currentSession: ChatSession = ChatSession()
    var isStreaming: Bool = false  // 是否正在接收流式响应
    var inputText: String = ""     // 用户输入的文本

    // 流式更新节流 - 私有状态，不触发观察
    private var streamingContent: String = ""
    private var lastUpdateTime: Date = .distantPast
    private let updateInterval: TimeInterval = 0.08  // 80ms 更新一次（约12fps）

    // 配置
    private let model: String = "glm-4.7"
    private let temperature: Double? = 0.7

    // 依赖
    private let repository: ChatRepositoryType

    // 构造器注入
    init(repository: ChatRepositoryType) {
        self.repository = repository
    }

    // 便捷构造：从容器解析
    convenience init(container: Container = .shared) {
        self.init(repository: container.chatRepository())
    }

    // MARK: - 发送消息

    /// 发送消息并获取流式响应
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard !isStreaming else { return }  // 防止在流式传输时重复发送

        // 添加用户消息
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        currentSession.messages.append(userMessage)

        // 清空输入框
        inputText = ""

        // 创建一个空的助手消息，用于流式更新
        let assistantMessage = ChatMessage(role: .assistant, content: "", isStreaming: true)
        messages.append(assistantMessage)
        currentSession.messages.append(assistantMessage)

        // 开始流式接收
        isStreaming = true
        state = .loading

        Task {
            await streamResponse(userMessage: userMessage)
        }
    }

    // MARK: - 流式接收响应

    private func streamResponse(userMessage: ChatMessage) async {
        do {
            // 发送最后5条消息（包含当前用户问题），保持对话上下文
            let recentMessages = Array(messages.suffix(5).dropLast())
            let messageDtos = recentMessages.map { msg in
                ChatMessageDto(role: ChatRole(rawValue: msg.role.rawValue)!, content: msg.content)
            } + [ChatMessageDto(role: .user, content: userMessage.content)]

            // 获取流式响应
            let stream = try await repository.streamChat(
                messages: messageDtos,
                model: model,
                temperature: temperature
            )

            // 重置流式状态
            streamingContent = ""
            lastUpdateTime = .distantPast

            // 逐块接收并更新UI（带节流）
            for try await chunk in stream {
                streamingContent += chunk

                // 节流：只在时间间隔到达时更新UI
                let now = Date()
                if now.timeIntervalSince(lastUpdateTime) >= updateInterval {
                    lastUpdateTime = now
                    await updateStreamingContent()
                }
            }

            // 确保最后的内容被更新
            if !streamingContent.isEmpty {
                await updateStreamingContent()
            }

            // 流式传输完成
            if let index = messages.indices.last {
                messages[index].isStreaming = false
                currentSession.messages[index].isStreaming = false
            }
            self.isStreaming = false
            self.state = .loaded

        } catch {
            // 移除正在流式传输的消息
            if !messages.isEmpty && messages.last?.isStreaming == true {
                messages.removeLast()
                currentSession.messages.removeLast()
            }

            self.isStreaming = false
            self.state = .failed(error.localizedDescription)

            LogTool.shared.error("聊天请求失败: \(error)")
        }
    }

    /// 更新流式内容到UI（从后台上下文调用时需要在主线程）
    private func updateStreamingContent() async {
        guard let index = messages.indices.last else { return }

        // 只更新内容，避免触发整个数组变化
        messages[index].content = streamingContent
        currentSession.messages[index].content = streamingContent
    }

    // MARK: - 其他操作

    /// 清空聊天记录
    func clearChat() {
        messages.removeAll()
        currentSession = ChatSession()
        state = .idle
        inputText = ""
    }

    /// 删除最后一条消息
    func deleteLastMessage() {
        guard !messages.isEmpty else { return }
        messages.removeLast()
        if !currentSession.messages.isEmpty {
            currentSession.messages.removeLast()
        }
    }
}
