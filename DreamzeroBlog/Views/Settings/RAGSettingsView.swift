//
//  RAGSettingsView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

struct RAGSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RAGSettingsViewModel
    @FocusState private var focusedField: Field?
    @State private var showBaiduAuth = false

    enum Field {
        case delimiter, prompt, baiduAuth
    }

    init() {
        _viewModel = State(initialValue: RAGSettingsViewModel())
    }

    var body: some View {
        Form {
            // 基本设置
            Section {
                Toggle("启用知识库搜索", isOn: $viewModel.isEnabled)
                    .onChange(of: viewModel.isEnabled) { _, _ in
                        viewModel.saveSettings()
                    }

                Toggle("联网搜索", isOn: $viewModel.webSearchEnabled)
                    .onChange(of: viewModel.webSearchEnabled) { _, _ in
                        viewModel.saveSettings()
                    }
            } header: {
                Text("基本设置")
            } footer: {
                Text("启用知识库搜索后，聊天时会自动检索知识库并注入上下文。启用联网搜索需要配置百度千帆 AppBuilder API Key。")
            }

            // 百度搜索配置
            if viewModel.webSearchEnabled {
                Section {
                    HStack(spacing: 8) {
                        if showBaiduAuth {
                            TextField("AppBuilder API Key", text: $viewModel.baiduSearchAuthorization)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .baiduAuth)
                                .onChange(of: viewModel.baiduSearchAuthorization) { _, _ in
                                    viewModel.saveSettings()
                                }
                        } else {
                            Text(maskedAuthorization)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showBaiduAuth = true
                                    focusedField = .baiduAuth
                                }
                        }

                        Spacer(minLength: 0)

                        Button(action: { showBaiduAuth.toggle() }) {
                            Image(systemName: showBaiduAuth ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("百度搜索配置")
                } footer: {
                    Text("请输入百度千帆 AppBuilder API Key（注意：这不是千帆平台的聊天 API Key，而是独立的搜索 API Key）")
                }
            }

            // 搜索配置
            Section {
                HStack {
                    Text("Top-K 结果数")
                    Spacer()
                    Picker("", selection: $viewModel.topK) {
                        ForEach(1...10, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .onChange(of: viewModel.topK) { _, _ in
                    viewModel.saveSettings()
                }

                Stepper("分块大小: \(viewModel.chunkSize) 字符", value: $viewModel.chunkSize, in: 100...2000, step: 100)
                    .onChange(of: viewModel.chunkSize) { _, _ in
                        viewModel.saveSettings()
                    }

                HStack {
                    Text("分块分隔符")
                    TextField("如：\\n、。、# 等", text: $viewModel.chunkDelimiter)
                        .focused($focusedField, equals: .delimiter)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: viewModel.chunkDelimiter) { _, _ in
                            viewModel.saveSettings()
                        }
                }
            } header: {
                Text("搜索配置")
            } footer: {
                Text("Top-K 控制返回的相关分块数量，分块分隔符用于切分文本")
            }

            // 自定义 Prompt
            Section {
                Toggle("使用自定义提示词", isOn: $viewModel.useCustomPrompt)
                    .onChange(of: viewModel.useCustomPrompt) { _, _ in
                        viewModel.saveSettings()
                    }

                if viewModel.useCustomPrompt {
                    TextEditor(text: $viewModel.customPromptTemplate)
                        .frame(minHeight: 150)
                        .focused($focusedField, equals: .prompt)
                        .font(.body.monospaced())
                        .onChange(of: viewModel.customPromptTemplate) { _, _ in
                            viewModel.saveSettings()
                        }
                } else {
                    Text(RAGConfigurationStore.shared.defaultPromptTemplate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
            } header: {
                Text("提示词模板")
            } footer: {
                Text("可用变量: {context} - 知识库内容, {web_context} - 联网搜索内容, {query} - 用户问题")
            }

            // 操作
            Section {
                Button("重置为默认值") {
                    viewModel.resetToDefaults()
                }
                .foregroundStyle(.orange)
            }
        }
        .navigationTitle("RAG 设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Authorization 掩码显示
    private var maskedAuthorization: String {
        let auth = viewModel.baiduSearchAuthorization
        guard !auth.isEmpty else { return "未配置，点击输入" }

        if auth.count <= 8 {
            return String(repeating: "*", count: auth.count)
        }

        let prefix = String(auth.prefix(4))
        let suffix = String(auth.suffix(4))
        let masked = String(repeating: "*", count: min(8, auth.count - 8))
        return "\(prefix)\(masked)\(suffix)"
    }
}

#Preview {
    NavigationStack {
        RAGSettingsView()
    }
}
