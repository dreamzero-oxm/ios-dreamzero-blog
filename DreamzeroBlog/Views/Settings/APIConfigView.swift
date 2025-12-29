//
//  APIConfigView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// API配置视图
struct APIConfigView: View {
    @State private var formViewModel: APIConfigViewModel
    @State private var showAPIKey = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isTesting = false
    @State private var isSaving = false
    @State private var testResult: String?
    @FocusState private var focusedField: Field?

    enum Field {
        case apiURL, apiKey, model
    }

    init() {
        // 使用当前配置初始化表单ViewModel
        let config = APIConfigurationStore.shared.currentConfiguration
        _formViewModel = State(initialValue: APIConfigViewModel(configuration: config))
    }

    var body: some View {
        Form {
            // 服务商选择
            Section {
                Picker("服务商", selection: $formViewModel.selectedProvider) {
                    ForEach(APIProvider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("基本配置")
            } footer: {
                presetDescription
            }

            // API URL
            Section {
                HStack {
                    Text("API URL")
                    Spacer()
                    Text(formViewModel.apiURL)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if formViewModel.selectedProvider == .custom {
                    TextField("自定义URL", text: $formViewModel.apiURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .apiURL)
                }
            } header: {
                Text("接口地址")
            }

            // API Key
            Section {
                HStack(spacing: 8) {
                    if showAPIKey {
                        TextField("API Key", text: $formViewModel.apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .apiKey)
                    } else {
                        Text(APIConfigViewModel.maskAPIKey(formViewModel.apiKey).isEmpty ? "未配置, 点击该处进行配置" : APIConfigViewModel.maskAPIKey(formViewModel.apiKey))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showAPIKey = true
                                focusedField = .apiKey
                            }
                    }

                    Spacer(minLength: 0)

                    Button(action: {
                        showAPIKey.toggle()
                        if showAPIKey {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedField = .apiKey
                            }
                        }
                    }) {
                        Image(systemName: showAPIKey ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("认证信息")
            } footer: {
                Text(preset.apiKeyPlaceholder)
            }

            // 模型配置
            Section {
                TextField("模型名称", text: $formViewModel.model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .model)
            } header: {
                Text("模型")
            }

            // JWT配置（仅智谱AI显示）
            if formViewModel.selectedProvider.supportsJWT {
                Section {
                    Toggle("使用JWT Token认证", isOn: $formViewModel.useJWT)
                } header: {
                    Text("认证方式")
                } footer: {
                    Text("开启后将使用ZhipuAIJWT工具类生成JWT Token。关闭则直接使用API Key。")
                }
            }

            // 操作按钮
            Section {
                Button(action: {
                    Task {
                        await testConnection()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isTesting {
                            ProgressView()
                        } else {
                            Text("测试连接")
                        }
                        Spacer()
                    }
                }
                .disabled(isTesting)

                Button(action: saveConfiguration) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("保存配置")
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(formViewModel.apiKey.isEmpty ? Color.gray : Color.blue)
                .disabled(isSaving)
            } header: {
                Text("操作")
            }

            // 测试结果
            if let testResult = testResult {
                Section {
                    Text(testResult)
                        .foregroundStyle(testResult.contains("通过") ? .green : .red)
                } header: {
                    Text("测试结果")
                }
            }

            // 重置选项
            Section {
                Button(action: {
                    APIConfigurationStore.shared.resetToDefaults()
                    updateFormViewModel()
                }) {
                    Text("重置为默认配置")
                        .foregroundStyle(.orange)
                }

                Button(action: {
                    APIConfigurationStore.shared.resetToBundle()
                    updateFormViewModel()
                }) {
                    Text("重置为Bundle配置")
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("重置")
            } footer: {
                Text("重置将覆盖当前配置")
            }
        }
        .navigationTitle("API配置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // 页面打开时刷新配置
            updateFormViewModel()
        }
        .onChange(of: formViewModel.selectedProvider) { _, newValue in
            // 切换provider时更新Store的currentProvider
            APIConfigurationStore.shared.currentProvider = newValue
            // 重新加载该provider的配置
            updateFormViewModel()
        }
        .onChange(of: formViewModel.apiURL) { _, _ in
            autoSave()
        }
        .onChange(of: formViewModel.apiKey) { _, _ in
            autoSave()
        }
        .onChange(of: formViewModel.model) { _, _ in
            autoSave()
        }
        .onChange(of: formViewModel.useJWT) { _, _ in
            autoSave()
        }
    }

    // MARK: - Computed Properties

    private var preset: APIProviderPreset {
        APIProviderPreset.preset(for: formViewModel.selectedProvider)
    }

    private var presetDescription: Text {
        Text("已选择 \(preset.name) 预设配置")
    }

    // MARK: - Actions

    private func testConnection() async {
        isTesting = true
        testResult = nil

        guard let config = formViewModel.buildConfiguration() else {
            testResult = formViewModel.validationError ?? "配置验证失败"
            isTesting = false
            alertMessage = testResult ?? "配置验证失败"
            showAlert = true
            return
        }

        // 简单验证配置有效性
        guard !config.apiURL.isEmpty else {
            testResult = "请输入API URL"
            isTesting = false
            alertMessage = testResult ?? "请输入API URL"
            showAlert = true
            return
        }

        guard !config.apiKey.isEmpty else {
            testResult = "请输入API Key"
            isTesting = false
            alertMessage = testResult ?? "请输入API Key"
            showAlert = true
            return
        }

        guard !config.model.isEmpty else {
            testResult = "请输入模型名称"
            isTesting = false
            alertMessage = testResult ?? "请输入模型名称"
            showAlert = true
            return
        }

        // 验证URL格式
        guard URL(string: config.apiURL) != nil else {
            testResult = "API URL格式不正确"
            isTesting = false
            alertMessage = testResult ?? "API URL格式不正确"
            showAlert = true
            return
        }

        // 如果是智谱AI且开启了JWT，验证API Key格式
        if (config.provider == .zhipuAI || config.provider == .zhipuAIPlan) && config.useJWT {
            let parts = config.apiKey.split(separator: ".")
            if parts.count != 2 {
                testResult = "智谱AI API Key格式应为 id.secret"
                isTesting = false
                alertMessage = testResult ?? "智谱AI API Key格式应为 id.secret"
                showAlert = true
                return
            }
        }

        testResult = "配置验证通过"
        isTesting = false
        alertMessage = testResult ?? "配置验证通过"
        showAlert = true
    }

    private func saveConfiguration() {
        guard let config = formViewModel.buildConfiguration() else {
            alertMessage = formViewModel.validationError ?? "配置验证失败"
            showAlert = true
            return
        }

        isSaving = true
        APIConfigurationStore.shared.saveConfiguration(config)
        isSaving = false

        alertMessage = "配置已保存"
        showAlert = true
    }

    private func updateFormViewModel() {
        let store = APIConfigurationStore.shared
        formViewModel = APIConfigViewModel(configuration: store.currentConfiguration)
    }

    private func autoSave() {
        guard let config = formViewModel.buildConfiguration() else {
            return
        }
        // 自动保存到Store
        APIConfigurationStore.shared.saveConfiguration(config)
        LogTool.shared.debug("✅ API配置已自动保存")
    }
}

#Preview {
    NavigationStack {
        APIConfigView()
    }
}
