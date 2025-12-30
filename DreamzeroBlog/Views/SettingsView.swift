//
//  SettingsView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 设置页面主视图
struct SettingsView: View {
    @State private var showUserProfile = false
    @State private var showLogin = false
    @State private var showAPIConfig = false
    @State private var showRAGSettings = false
    @State private var isValidatingToken = false

    var body: some View {
        NavigationStack {
            List {
                // 账号/个人资料/登录
                Section {
                    if isValidatingToken {
                        // 验证中显示加载状态
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("验证中...")
                                .foregroundStyle(.secondary)
                        }
                    } else if AuthSessionManager.shared.isAuthenticated {
                        // 已登录：显示个人资料
                        Button(action: { showUserProfile = true }) {
                            HStack {
                                Label("个人资料", systemImage: "person.circle")
                                Spacer()
                                if let user = AuthSessionManager.shared.currentUser {
                                    Text(user.nickname)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        // 未登录：显示登录按钮
                        Button(action: { showLogin = true }) {
                            Label("登录", systemImage: "person.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                // API配置
                Section {
                    Button(action: { showAPIConfig = true }) {
                        Label("API配置", systemImage: "network")
                    }
                } header: {
                    Text("聊天设置")
                }

                // 知识库
                Section {
                    NavigationLink(destination: KnowledgeBaseView()) {
                        Label("知识库", systemImage: "book.closed")
                    }

                    Button(action: { showRAGSettings = true }) {
                        Label("RAG 设置", systemImage: "gearshape.2")
                    }
                } header: {
                    Text("知识库")
                }

                // 关于
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
        }
        .sheet(isPresented: $showLogin) {
            AccountSettingsView()
        }
        .sheet(isPresented: $showUserProfile) {
            UserProfileView()
        }
        .sheet(isPresented: $showAPIConfig) {
            APIConfigView()
        }
        .sheet(isPresented: $showRAGSettings) {
            RAGSettingsView()
        }
        .onAppear {
            validateTokenIfNeeded()
        }
    }

    // MARK: - Token Validation

    private func validateTokenIfNeeded() {
        
        isValidatingToken = true

        Task {
            let isValid = await AuthSessionManager.shared.validateAccessToken()

            await MainActor.run {
                isValidatingToken = false
                if !isValid {
                    // Token 无效，清除认证状态
                    AuthSessionManager.shared.logout()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
