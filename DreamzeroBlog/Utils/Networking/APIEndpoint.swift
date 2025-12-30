//
//  APIEndpoint.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/25.
//

import Foundation
import Alamofire

// MARK: - 1. 接口蓝图
// 所有业务接口（登录、商品列表、上传头像……）都通过遵守这个协议来描述：
// “我要访问哪个路径、用什么 HTTP 方法、传什么参数、要不要加头、超时多久”
public protocol APIEndpoint: Sendable {
    
    /* 必须提供 */
    var path: String { get }            // 相对路径，例如 "/login"
    var method: HTTPMethod { get }      // GET / POST / PUT / DELETE …
    var encoder: ParameterEncoder { get } // 告诉网络层“你想怎么编码参数”
    
    /* 可选，协议扩展已经给好默认值 */
    var parameters: Encodable? { get } // 要上传的参数（可以是查询字符串也可以是 JSON 体）
    var headers: HTTPHeaders? { get }   // 额外 HTTP 头
    var requiresAuth: Bool { get }      // 是否需要附赠 token（业务层可读取做拦截）
    var timeout: TimeInterval? { get }  // 自定义超时（秒），nil 就用 Alamofire 全局值
}

// MARK: - 2. 默认值
// 遵守者什么都不写也能编译通过，减少模板代码
public extension APIEndpoint {
    var parameters: Encodable? { nil }   // 默认不带参数
    var headers: HTTPHeaders?   { nil }   // 默认不加头
    var requiresAuth: Bool      { true }  // 默认"需要登录"
    var timeout: TimeInterval?  { nil }   // 默认不单独设超时
}

// MARK: - 3. 把"接口蓝图"变成"真正的网络请求"
// Alamofire 的 URLRequestConvertible 协议要求实现 asURLRequest()，
// 这里做统一装配：拼 URL、装头、装参数、设超时……
struct APIRequestConvertible: URLRequestConvertible {
    
    let baseURL: URL        // 例如 https://api.example.com
    let endpoint: APIEndpoint // 遵守协议的具体业务 endpoint
    
    func asURLRequest() throws -> URLRequest {
        // 3-1 拼完整 URL
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        // 3-2 先按 HTTP 方法创建空请求
        var request = try URLRequest(url: url, method: endpoint.method)
        
        // 3-3 如果 endpoint 自己设了超时，就覆盖全局值
        if let timeout = endpoint.timeout {
            request.timeoutInterval = timeout
        }

        // 3-3.5 传递 requiresAuth 元数据给 AuthInterceptor
        // 使用 URL 查询参数传递元数据（不会实际发送到服务器）
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            var queryItems = urlComponents.queryItems ?? []
            queryItems.append(URLQueryItem(name: "_requiresAuth", value: endpoint.requiresAuth ? "true" : "false"))
            LogTool.shared.debug("Endpoint \(endpoint.path) requiresAuth=\(endpoint.requiresAuth)")
            urlComponents.queryItems = queryItems
            if let metadataURL = urlComponents.url {
                request.url = metadataURL
            }
        }

        // 如果 endpoint 有自定义 Authorization 头，标记此信息
        if let headers = endpoint.headers, headers["Authorization"] != nil {
            if var urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false) {
                var queryItems = urlComponents.queryItems ?? []
                queryItems.append(URLQueryItem(name: "_hasCustomAuth", value: "true"))
                urlComponents.queryItems = queryItems
                if let metadataURL = urlComponents.url {
                    request.url = metadataURL
                }
            }
        }

        // 3-4 追加额外头（业务层可能给 X-Client-Version 等）
        if let headers = endpoint.headers {
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.name)
            }
        }
        
        // 3-5 把参数编码进请求体 / URL 查询字符串
        // encoder 由 endpoint 指定，可以是
        // - JSONParameterEncoder.default  → JSON 体
        // - URLEncodedFormParameterEncoder.default → form 表单
        // - CustomParameterEncoder → 业务自己写的特殊编码
        if let parameters = endpoint.parameters {
            request = try endpoint.encoder.encode(parameters, into: request)
        }
        
        return request
    }
}

// MARK: - 4. 使用示例
/*
struct LoginEndpoint: APIEndpoint {
    let username: String
    let password: String
    
    var path: String { "/login" }
    var method: HTTPMethod { .post }
    var encoder: ParameterEncoder { URLEncodedFormParameterEncoder.default } // 表单提交
    var parameters: Parameters? { ["username": username, "password": password] }
    var requiresAuth: Bool { false } // 登录前还没有 token
}

// 调用
let ep = LoginEndpoint(username: "alice", password: "123456")
let convertible = APIRequestConvertible(baseURL: URL(string: "https://api.example.com")!, endpoint: ep)
let urlRequest = try convertible.asURLRequest()
// 此时 urlRequest 已经带好了
// - URL: https://api.example.com/login
// - Method: POST
// - Content-Type: application/x-www-form-urlencoded
// - httpBody: username=alice&password=123456
*/


