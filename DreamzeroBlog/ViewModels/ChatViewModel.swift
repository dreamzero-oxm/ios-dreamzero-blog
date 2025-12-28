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
            // 只发送当前用户的问题，不包含历史对话
            let messageDtos = [ChatMessageDto(role: .user, content: userMessage.content)]

            // 获取流式响应
            let stream = try await repository.streamChat(
                messages: messageDtos,
                model: model,
                temperature: temperature
            )

            // 逐块接收并更新UI
            var fullContent = ""
            for try await chunk in stream {
                fullContent += chunk

                // 更新最后一条消息的内容
                if let index = messages.indices.last {
                    messages[index].content = fullContent
                    currentSession.messages[index].content = fullContent
                }
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
