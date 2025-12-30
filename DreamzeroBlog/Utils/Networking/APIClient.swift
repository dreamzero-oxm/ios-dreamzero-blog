//
//  APIClient.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/25.
//

import Foundation
import Alamofire

// MARK: - APIClient：用于执行网络请求

public final class APIClient {
    public let baseURL: URL
    private let session: Session
    private let reachability: NetworkReachabilityManager?

    public init(
        baseURL: URL,
        timeout: TimeInterval = 30,
        additionalHeaders: HTTPHeaders? = nil,
        eventMonitors: [EventMonitor] = [NetworkLogger()],
        interceptors: [RequestInterceptor] = []
    ) {
        self.baseURL = baseURL

        // 设置 URLSession 配置
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.httpAdditionalHeaders = additionalHeaders?.dictionary
        
        // 创建 Alamofire 的组合拦截器
        let combinedInterceptor = Interceptor(adapters: interceptors, retriers: interceptors)

        self.session = Session(configuration: configuration, interceptor: combinedInterceptor, eventMonitors: eventMonitors)

        // 网络可达性监听
        self.reachability = NetworkReachabilityManager()
        self.reachability?.startListening(onUpdatePerforming: { status in
            LogTool.shared.info("Network: \(status)")
        })
    }

    deinit { reachability?.stopListening() }

    // MARK: - 网络请求：解码泛型返回类型

    public func request<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type = T.self, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        let convertible = APIRequestConvertible(baseURL: baseURL, endpoint: endpoint)
        return try await withCheckedThrowingContinuation { continuation in
            session.request(convertible)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: T.self, decoder: decoder) { resp in
                    switch resp.result {
                    case .success(let value): continuation.resume(returning: value)
                    case .failure(let error):
                        if let code = resp.response?.statusCode {
                            if code == 401 {
                                
                                continuation.resume(throwing: APIError.unauthorized)
                                return
                            }
                            continuation.resume(throwing: APIError.server(code: code, message: APIClient.extractMessage(data: resp.data)))
                        } else {
                            continuation.resume(throwing: APIError.from(error))
                        }
                    }
                }
        }
    }

    // 提取服务端错误信息
    static func extractMessage(data: Data?) -> String? {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        for key in ["message", "msg", "error", "detail"] {
            if let v = json[key] as? String { return v }
        }
        return nil
    }

    // MARK: - 流式请求（Server-Sent Events）

    /// 发起流式请求（SSE），用于接收服务器持续发送的数据
    /// - Parameters:
    ///   - endpoint: API端点
    ///   - customBaseURL: 自定义baseURL（可选），用于第三方API如智谱AI
    /// - Returns: 异步流，逐块返回数据
    public func streamRequest(
        _ endpoint: APIEndpoint,
        customBaseURL: URL? = nil
    ) async throws -> AsyncThrowingStream<String, Error> {
        // 使用自定义baseURL或默认baseURL
        let targetURL = customBaseURL ?? baseURL

        let convertible = APIRequestConvertible(baseURL: targetURL, endpoint: endpoint)
        let urlRequest = try convertible.asURLRequest()

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    // 检查状态码
                    guard httpResponse.statusCode == 200 else {
                        // 读取前 1000 字节用于错误信息
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                            if errorData.count >= 1000 { break }
                        }
                        if let errorMessage = String(data: errorData, encoding: .utf8) {
                            LogTool.shared.error("流式请求失败: \(errorMessage)")
                            
                            LogTool.shared.debug("API URL: \(urlRequest.url?.absoluteString ?? "unknown")")
                        }
                        continuation.finish(throwing: APIError.server(code: httpResponse.statusCode, message: APIClient.extractMessage(data: nil)))
                        return
                    }

                    // 逐行读取SSE响应
                    for try await line in bytes.lines {
                        // SSE格式：data: {json}
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))

                            // 检查结束标记
                            if jsonString == "[DONE]" {
                                continuation.finish()
                                return
                            }

                            // 返回JSON字符串，由调用方解析
                            continuation.yield(jsonString)
                        }
                    }

                    continuation.finish()
                } catch {
                    LogTool.shared.error("流式请求错误: \(error)")
                    continuation.finish(throwing: APIError.from(error))
                }
            }
        }
    }
}

