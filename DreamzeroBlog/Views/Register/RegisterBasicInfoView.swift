//
//  RegisterBasicInfoView.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/25.
//

import SwiftUI
import Factory

/// 注册基本信息视图 - 包含邮箱、用户名、密码输入
struct RegisterBasicInfoView: View {
    // 使用 Factory 容器获取 @Observable 的 ViewModel
    @State private var viewModel: RegisterViewModel = Container.shared.registerViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, username, password, confirmPassword
    }
    
    init(viewModel: RegisterViewModel?) {
        if let vm = viewModel {
            _viewModel = State(initialValue: vm)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 8) {
                    Text("创建账号")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("请填写以下信息完成注册")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
                
                // 邮箱输入框
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("邮箱地址")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !viewModel.email.isEmpty {
                            Image(systemName: viewModel.isEmailValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.isEmailValid ? .green : .red)
                                .font(.system(size: 16))
                        }
                    }
                    
                    // 邮箱输入框
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        
                        TextField("请输入邮箱地址", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .keyboardType(.emailAddress)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = .email
                    }
                    
                    if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                        Text("请输入有效的邮箱地址")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // 用户名输入框
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("用户名")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !viewModel.username.isEmpty {
                            Image(systemName: viewModel.isUsernameValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.isUsernameValid ? .green : .red)
                                .font(.system(size: 16))
                        }
                    }
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                        
                        TextField("请输入用户名", text: $viewModel.username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .username)
                            .submitLabel(.next)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = .username
                    }
                    
                    if !viewModel.username.isEmpty && !viewModel.isUsernameValid {
                        Text("用户名需为3-20个字符，只能包含字母、数字、下划线")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // 密码输入框
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("密码")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !viewModel.password.isEmpty {
                            Image(systemName: viewModel.isPasswordValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.isPasswordValid ? .green : .red)
                                .font(.system(size: 16))
                        }
                    }
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        
                        if viewModel.showPassword {
                            TextField("请输入密码", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                        } else {
                            SecureField("请输入密码", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                        }
                        
                        Button(action: { viewModel.showPassword.toggle() }) {
                            Image(systemName: viewModel.showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = .password
                    }
                    
                    if !viewModel.password.isEmpty && !viewModel.isPasswordValid {
                        Text("密码需至少8位，包含字母和数字")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // 确认密码输入框
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("确认密码")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !viewModel.confirmPassword.isEmpty {
                            Image(systemName: viewModel.isConfirmPasswordValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.isConfirmPasswordValid ? .green : .red)
                                .font(.system(size: 16))
                        }
                    }
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                        
                        if viewModel.showConfirmPassword {
                            TextField("请再次输入密码", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.done)
                        } else {
                            SecureField("请再次输入密码", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.done)
                        }
                        
                        Button(action: { viewModel.showConfirmPassword.toggle() }) {
                            Image(systemName: viewModel.showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = .confirmPassword
                    }
                    
                    if !viewModel.confirmPassword.isEmpty && !viewModel.isConfirmPasswordValid {
                        Text("两次输入的密码不一致")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // 注册按钮
                Button(action: { viewModel.register() }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("下一步")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isBasicInfoValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
                }
                .disabled(!viewModel.isBasicInfoValid || viewModel.isLoading)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .padding()
        .alert("注册错误", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .username
            case .username:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                if viewModel.isBasicInfoValid {
                    viewModel.register()
                }
            case .none:
                break
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

// 默认为viewModel为空的初始化器
extension RegisterBasicInfoView {
    init () {
        self.init(viewModel: nil)
    }
}

// MARK: - 预览
struct RegisterBasicInfoView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterBasicInfoView()
    }
}
