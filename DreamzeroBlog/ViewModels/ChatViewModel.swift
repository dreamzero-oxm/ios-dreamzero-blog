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
    private let sessionStore: ChatSessionStoreType?

    // 标题生成标志
    private var hasGeneratedTitle: Bool = false

    // 构造器注入
    init(repository: ChatRepositoryType, sessionStore: ChatSessionStoreType? = nil) {
        self.repository = repository
        self.sessionStore = sessionStore
    }

    // 便捷构造：从容器解析
    convenience init(container: Container = .shared) {
        self.init(repository: container.chatRepository())
    }

    // MARK: - 会话管理

    /// 创建新会话（如果当前会话有消息则先保存）
    func createNewSession() async {
        // 如果当前会话有消息，先保存
        if !messages.isEmpty {
            await saveCurrentSession()
        }
        // 创建新会话
        currentSession = ChatSession(title: "新对话")
        messages.removeAll()
        hasGeneratedTitle = false
        state = .idle
        inputText = ""
    }

    /// 加载现有会话（如果当前会话有消息则先保存）
    func loadSession(_ session: ChatSession) async {
        // 如果当前会话有消息且不是要加载的会话，先保存
        if !messages.isEmpty && currentSession.id != session.id {
            await saveCurrentSession()
        }
        state = .loading
        currentSession = session
        messages = session.messages
        hasGeneratedTitle = !session.title.isEmpty && session.title != "新对话"
        state = .loaded
    }

    /// 删除会话
    func deleteSession(_ session: ChatSession) async {
        guard let sessionStore = sessionStore else { return }
        do {
            try await sessionStore.deleteSession(session)
            // 如果删除的是当前会话，创建新会话
            if session.id == currentSession.id {
                messages.removeAll()
                currentSession = ChatSession(title: "新对话")
                hasGeneratedTitle = false
                state = .idle
                inputText = ""
            }
        } catch {
            LogTool.shared.error("删除会话失败: \(error)")
        }
    }

    /// 生成会话标题
    private func generateTitle(from text: String) {
        let title = String(text.prefix(20))
        currentSession.title = title.isEmpty ? "新对话" : (text.count > 20 ? title + "..." : title)
        hasGeneratedTitle = true
    }

    /// 保存当前会话
    private func saveCurrentSession() async {
        guard let sessionStore = sessionStore else { return }
        // 只有当会话有消息时才保存
        guard !messages.isEmpty else { return }

        // 使用最后一条消息的时间作为 updatedAt
        if let lastMessage = messages.last {
            currentSession.updatedAt = lastMessage.timestamp
        }

        do {
            try await sessionStore.saveSession(currentSession)
        } catch {
            LogTool.shared.error("保存会话失败: \(error)")
        }
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

        // 生成标题（如果还没有）
        if !hasGeneratedTitle {
            generateTitle(from: text)
        }

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
            // 流式传输完成后保存会话
            await saveCurrentSession()
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

            // 解析错误信息
            let errorMessage: String
            if let apiError = error as? APIError {
                switch apiError {
                case .network(let afError):
                    errorMessage = "网络错误: \(afError.localizedDescription)"
                case .unauthorized:
                    errorMessage = "认证失败，请检查API Key是否正确"
                case .server(let code, let msg):
                    if code == 1001 {
                        errorMessage = "认证失败：Header中未收到Authorization参数，请检查API配置"
                    } else {
                        errorMessage = msg ?? "服务器错误(\(code))"
                    }
                case .invalidResponse:
                    errorMessage = "响应格式错误，请检查API配置是否正确"
                case .decoding:
                    errorMessage = "数据解析失败"
                case .cancelled:
                    errorMessage = "请求已取消"
                case .unknown(let e):
                    errorMessage = e.localizedDescription
                }
            } else {
                // 对于非APIError，尝试从错误描述中提取信息
                let errorDesc = error.localizedDescription
                if errorDesc.contains("Authorization") || errorDesc.contains("1001") {
                    errorMessage = "认证失败：Header中未收到Authorization参数，请检查API配置"
                } else if errorDesc.contains("网络") || errorDesc.contains("network") {
                    errorMessage = "网络连接失败，请检查网络设置"
                } else if errorDesc.contains("timeout") || errorDesc.contains("超时") {
                    errorMessage = "请求超时，请稍后再试"
                } else {
                    errorMessage = "请求失败: \(errorDesc)"
                }
            }

            // 添加错误消息气泡
            let errorBubble = ChatMessage(role: .system, content: errorMessage)
            messages.append(errorBubble)
            currentSession.messages.append(errorBubble)

            self.state = .failed(errorMessage)
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
        hasGeneratedTitle = false
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
