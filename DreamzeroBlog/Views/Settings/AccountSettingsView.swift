//
//  AccountSettingsView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI

/// 账号设置视图
/// 包含原有的登录界面内容
struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LoginViewModel()
    @State private var showPassword = false
    @State private var showRegisterSheet = false

    @FocusState private var focusedField: Field?

    enum Field {
        case account, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Logo区域
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)

                    Text("Dreamzero Blog")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("欢迎回来")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // 登录表单
                VStack(spacing: 20) {
                    // 用户名输入框
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        TextField("用户名", text: $viewModel.account)
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .account)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

                    // 密码输入框
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        if showPassword {
                            TextField("密码", text: $viewModel.password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                        } else {
                            SecureField("密码", text: $viewModel.password)
                                .textContentType(.password)
                                .focused($focusedField, equals: .password)
                        }

                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

                    // 登录按钮
                    Button(action: {
                        Task {
                            await viewModel.login()
                            if viewModel.loginSuccess {
                                dismiss()
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("登录")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: !viewModel.isValid ?
                                [Color.blue.opacity(0.5)] :
                                [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
                .padding(.horizontal, 20)

                // 忘记密码和注册
                HStack(spacing: 20) {
                    Button("忘记密码？") {
                        // TODO: 实现忘记密码功能
                    }
                    .font(.subheadline)

                    Spacer()

                    Button("注册新账号") {
                        showRegisterSheet = true
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .navigationTitle("账号")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("关闭") {
                    dismiss()
                }
            }
        }
        .onSubmit {
            switch focusedField {
            case .account:
                focusedField = .password
            case .password:
                Task {
                    await viewModel.login()
                    if viewModel.loginSuccess {
                        dismiss()
                    }
                }
            case .none:
                break
            }
        }
        .alert("登录失败", isPresented: $viewModel.showError) {
            Button("确定") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showRegisterSheet) {
            RegisterView()
        }
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView()
    }
}
