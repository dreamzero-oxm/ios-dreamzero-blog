//
//  SettingsView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 设置页面主视图
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                // 账号设置
                Section {
                    NavigationLink(destination: AccountSettingsView()) {
                        Label("账号", systemImage: "person.circle")
                    }
                }

                // API配置
                Section {
                    NavigationLink(destination: APIConfigView()) {
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

                    NavigationLink(destination: RAGSettingsView()) {
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
    }
}

#Preview {
    SettingsView()
}
