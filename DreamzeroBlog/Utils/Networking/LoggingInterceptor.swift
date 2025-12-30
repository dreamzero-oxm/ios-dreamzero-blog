//
//  LoggingInterceptor.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/25.
//

import Alamofire
import Foundation

/// 网络请求日志拦截器
/// 使用 EventMonitor 在请求发出前记录详细的请求信息
/// 注意：必须使用 EventMonitor 而不是 RequestInterceptor，
/// 因为 adapt 方法执行时 httpBody 还没有被 ParameterEncoder 编码
final class LoggingInterceptor: EventMonitor {
    let queue = DispatchQueue(label: "com.dreamzero.logging.interceptor")

    /// 请求即将发出时记录日志（此时 httpBody 已经被编码完成）
    func requestDidResume(_ request: Request) {
        guard let urlRequest = request.request else { return }

        // 记录请求URL
        var logMessage = "🌐 [网络请求] \(urlRequest.httpMethod ?? "UNKNOWN") \(urlRequest.url?.absoluteString ?? "(无 URL)")"

        // 记录请求头
        if let headers = urlRequest.allHTTPHeaderFields, !headers.isEmpty {
            logMessage += "\n📋 [请求头] \(headers)"
        }

        // 记录是否有 Authorization
        if let authHeader = urlRequest.value(forHTTPHeaderField: "Authorization") {
            let sanitized = sanitizeToken(authHeader)
            logMessage += "\n🔑 [认证] Authorization: \(sanitized)"
        }

        // 记录请求体（如果有）
        if let httpBody = urlRequest.httpBody {
            let contentType = urlRequest.value(forHTTPHeaderField: "Content-Type") ?? ""

            if contentType.contains("multipart/form-data") {
                logMessage += "\n📦 [请求体] multipart/form-data (\(httpBody))"
            } else if let bodyString = String(data: httpBody, encoding: .utf8) {
                // 限制日志长度，避免输出过长
                let displayBody = String(bodyString.prefix(500))
                logMessage += "\n📦 [请求体] \(displayBody)\(bodyString.count > 500 ? "..." : "")"
            } else {
                logMessage += "\n📦 [请求体] \(httpBody.count) bytes (二进制数据)"
            }
        }

        LogTool.shared.debug(logMessage, category: .network)
    }

    /// 脱敏Token，只显示前几位
    private func sanitizeToken(_ token: String) -> String {
        if token.isEmpty { return "(空)" }
        if token.count <= 20 { return LogTool.sanitize(token) }
        return "\(token.prefix(10))..." + String(repeating: "*", count: min(token.count - 13, 20))
    }
}
