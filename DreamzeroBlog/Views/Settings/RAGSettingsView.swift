//
//  RAGSettingsView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

struct RAGSettingsView: View {
    @State private var viewModel: RAGSettingsViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case delimiter, prompt
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
            } header: {
                Text("基本设置")
            } footer: {
                Text("启用后，聊天时会自动检索知识库并注入上下文")
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

                TextField("分块分隔符", text: $viewModel.chunkDelimiter)
                    .focused($focusedField, equals: .delimiter)
                    .autocorrectionDisabled()
                    .onChange(of: viewModel.chunkDelimiter) { _, _ in
                        viewModel.saveSettings()
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
                Text("可用变量: {context} - 检索到的内容, {query} - 用户问题")
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
    }
}

#Preview {
    NavigationStack {
        RAGSettingsView()
    }
}
