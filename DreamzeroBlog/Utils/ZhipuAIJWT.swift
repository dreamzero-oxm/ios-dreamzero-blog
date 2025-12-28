//
//  ZhipuAIJWT.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/28.
//

import Foundation
import CryptoKit

/// 智谱AI JWT Token 生成工具
enum ZhipuAIJWT {

    /// 生成智谱AI所需的JWT Token
    /// - Parameter apiKey: 智谱AI API Key，格式为 "id.secret"
    /// - Returns: JWT Token字符串
    static func generateToken(from apiKey: String) throws -> String {
        // 分离 API Key 的 ID 和 Secret
        let parts = apiKey.split(separator: ".", maxSplits: 1)
        guard parts.count == 2 else {
            throw ZhipuAIError.invalidAPIKeyFormat
        }

        let id = String(parts[0])
        let secret = String(parts[1])

        // 创建过期时间（当前时间 + 1小时）
        let expiration = Date().addingTimeInterval(3600)

        // 创建 JWT payload
        let payload: [String: Any] = [
            "api_key": id,
            "exp": Int(expiration.timeIntervalSince1970),
            "timestamp": Int(Date().timeIntervalSince1970)
        ]

        // 编码 header
        let header: [String: Any] = [
            "alg": "HS256",
            "sign_type": "SIGN"
        ]

        let encodedHeader = try base64URLEncode(header)
        let encodedPayload = try base64URLEncode(payload)

        // 创建签名内容
        let signingContent = "\(encodedHeader).\(encodedPayload)"

        // 使用 HMAC-SHA256 签名
        let key = SymmetricKey(data: secret.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: signingContent.data(using: .utf8)!, using: key)

        // Base64URL 编码签名
        let encodedSignature = Data(signature)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))

        return "\(signingContent).\(encodedSignature)"
    }

    /// Base64URL 编码字典
    private static func base64URLEncode(_ dictionary: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let base64 = data.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
    }

    enum ZhipuAIError: Error {
        case invalidAPIKeyFormat
    }
}
