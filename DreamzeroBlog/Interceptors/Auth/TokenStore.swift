//
//  TokenStore.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/25.
//

import Foundation // 基础库

public final class TokenStore { // 提供面向业务的令牌读写门面
    private let store: SecureStore // 依赖抽象存储，便于替换/单测
    private let keyPrefix: String // 键前缀，避免冲突

    private var accessKey: String { keyPrefix + "access" } // 访问令牌键名
    private var refreshKey: String { keyPrefix + "refresh" } // 刷新令牌键名
    private var bundleKey: String { keyPrefix + "bundle" } // 令牌包键名（含类型/过期等）

    public init(store: SecureStore, keyPrefix: String = "auth.") { // 构造函数
        self.store = store // 保存依赖
        self.keyPrefix = keyPrefix // 保存前缀
    }

    public func save(_ tokens: AuthTokens) throws { // 保存整组令牌
        try store.set(tokens, for: bundleKey) // 保存 JSON 包（含额外信息）
        try store.set(tokens.accessToken, for: accessKey) // 冗余保存 accessToken 便于快速读取
        try store.set(tokens.refreshToken, for: refreshKey) // 冗余保存 refreshToken 便于快速读取
    }

    // 获取refreshKey
    public func currentRefreshToken() throws -> String? { // 获取当前刷新令牌
        try store.getString(refreshKey) // 直接按键读取字符串
    }

    public func currentAccessToken() throws -> String? { // 获取当前访问令牌
        try store.getString(accessKey) // 直接按键读取字符串
    }

    public func currentTokens() throws -> AuthTokens? { // 获取完整令牌包
        try store.get(AuthTokens.self, for: bundleKey) // 读取并解码为 AuthTokens
    }

    public func clear() throws { // 清除所有与令牌相关的数据
        try store.remove(accessKey) // 删除 accessToken
        try store.remove(refreshKey) // 删除 refreshToken
        try store.remove(bundleKey) // 删除令牌包
    }
}
