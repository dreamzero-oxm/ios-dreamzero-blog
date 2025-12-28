//
//  LoginView.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/25.
//

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showRegisterSheet = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo 区域
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Text("Dreamzero Blog")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("欢迎回来")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 50)
                
                // 登录表单卡片
                VStack(spacing: 20) {
                    // 用户名输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("用户名")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                            
                            TextField("请输入用户名", text: $username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // 密码输入框
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            
                            if showPassword {
                                TextField("请输入密码", text: $password)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.done)
                            } else {
                                SecureField("请输入密码", text: $password)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.done)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // 登录按钮
                    Button(action: login) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text("登录")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(username.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .scaleEffect(isLoading ? 0.95 : 1.0)
                    }
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                }
                .padding(25)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 底部链接
                HStack(spacing: 20) {
                    Button("忘记密码？") {
                        // 处理忘记密码
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    
                    Text("·")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button("注册新账号") {
                        showRegisterSheet = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)
            }
        }
        .onSubmit {
            switch focusedField {
            case .username:
                focusedField = .password
            case .password:
                login()
            case .none:
                break
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .sheet(isPresented: $showRegisterSheet) {
            RegisterView()
        }
    }
    
    private func login() {
        guard !username.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        focusedField = nil
        
        // 模拟登录请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            // 这里调用你的登录API
            print("登录用户名: \\(username), 密码: \\(password)")
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
