//
//  LogTool.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/24.
//

import Foundation
import SwiftyBeaver

// MARK: - 日志分类

enum LogCategory: String {
    case network = "Network"
    case ui = "UI"
    case database = "Database"
    case auth = "Auth"
    case general = "General"
}

// MARK: - 日志工具

class LogTool {
    static let shared = LogTool()

    private let isDebug: Bool
    private let dateFormatter: DateFormatter

    private init() {
        #if DEBUG
        self.isDebug = true
        #else
        self.isDebug = false
        #endif

        // 配置日期格式化器
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "HH:mm:ss.SSS"

        setupDestinations()
    }

    // MARK: - 配置日志目标

    private func setupDestinations() {
        // 控制台输出
        let console = ConsoleDestination()
        console.useNSLog = true
        console.minLevel = isDebug ? .verbose : .error

        #if DEBUG
        // 文件输出（仅 Debug 模式）
        let file = FileDestination()
        file.logFileMaxSize = (5 * 1024 * 1024) // 5MB
        file.logFileAmount = 3                   // 保留3个文件
        file.minLevel = .verbose
        file.format = "$DHH:mm:ss.SSS$d $C$L$c: $M"
        SwiftyBeaver.addDestination(file)
        #endif

        SwiftyBeaver.addDestination(console)
    }

    // MARK: - 基础日志方法（带调用者信息）

    func verbose(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        category: LogCategory = .general
    ) {
        guard isDebug else { return }
        let formattedMessage = formatMessage(message, category: category)
        SwiftyBeaver.verbose(formattedMessage, file: file, function: function, line: line)
    }

    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        category: LogCategory = .general
    ) {
        guard isDebug else { return }
        let formattedMessage = formatMessage(message, category: category)
        SwiftyBeaver.debug(formattedMessage, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        category: LogCategory = .general
    ) {
        guard isDebug else { return }
        let formattedMessage = formatMessage(message, category: category)
        SwiftyBeaver.info(formattedMessage, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        category: LogCategory = .general
    ) {
        let formattedMessage = formatMessage(message, category: category)
        SwiftyBeaver.warning(formattedMessage, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        category: LogCategory = .general,
        error: Error? = nil
    ) {
        var errorMessage = formatMessage(message, category: category)
        if let error = error {
            errorMessage += " | Error: \(error.localizedDescription)"
        }
        SwiftyBeaver.error(errorMessage, file: file, function: function, line: line)
    }

    // MARK: - 便捷方法

    /// 性能监控：测量代码执行时间
    func measure(
        _ label: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: () throws -> Void
    ) rethrows {
        let start = Date()
        debug("⏱️ [\(label)] 开始", file: file, function: function, line: line)
        try block()
        let duration = Date().timeIntervalSince(start) * 1000
        debug("⏱️ [\(label)] 完成 (耗时: \(String(format: "%.2f", duration))ms)", file: file, function: function, line: line)
    }

    /// 异步性能监控：测量异步代码执行时间
    func measureAsync(
        _ label: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        block: () async throws -> Void
    ) async rethrows {
        let start = Date()
        debug("⏱️ [\(label)] 开始", file: file, function: function, line: line)
        try await block()
        let duration = Date().timeIntervalSince(start) * 1000
        debug("⏱️ [\(label)] 完成 (耗时: \(String(format: "%.2f", duration))ms)", file: file, function: function, line: line)
    }

    // MARK: - 工具方法

    /// 敏感信息脱敏
    static func sanitize(_ value: String, visibleChars: Int = 6) -> String {
        guard value.count > visibleChars else { return "***" }
        let prefix = String(value.prefix(visibleChars))
        let stars = String(repeating: "*", count: min(value.count - visibleChars, 8))
        return prefix + stars
    }

    /// 格式化消息（添加分类标签）
    private func formatMessage(_ message: String, category: LogCategory) -> String {
        return "[\(category.rawValue)] \(message)"
    }
}
