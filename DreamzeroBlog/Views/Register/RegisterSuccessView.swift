//
//  RegisterSuccessView.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/25.
//

import SwiftUI
import Factory

/// 注册成功视图 - 显示注册成功信息
struct RegisterSuccessView: View {
    // 使用 Factory 容器获取 @Observable 的 ViewModel
    @State private var viewModel: RegisterViewModel = Container.shared.registerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: RegisterViewModel?) {
        if let vm = viewModel {
            _viewModel = State(initialValue: vm)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                
                // 成功图标
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // 成功标题
                VStack(spacing: 8) {
                    Text("注册成功！")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("欢迎加入 Dreamzero Blog")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                // 用户信息展示
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("用户名")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(viewModel.username)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("邮箱地址")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(viewModel.email)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // 提示信息
                VStack(spacing: 8) {
                    Text("您的账号已创建成功")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("现在您可以使用新账号登录并开始使用 Dreamzero Blog 了")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 按钮区域
                VStack(spacing: 15) {
                    // 立即登录按钮
                    Button(action: {
                        // 完成注册并关闭注册流程
                        viewModel.completeRegistration()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("立即登录")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // 返回首页按钮
                    Button(action: {
                        viewModel.completeRegistration()
                        dismiss()
                    }) {
                        Text("返回首页")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarBackButtonHidden(true)
        }
    }
}

// 默认为viewModel为空的初始化器
extension RegisterSuccessView {
    init () {
        self.init(viewModel: nil)
    }
}

// MARK: - 预览
struct RegisterSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        return RegisterSuccessView()
    }
}
