//
//  RegisterVerificationView.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/25.
//

import SwiftUI
import Factory

/// 注册验证码视图 - 用于输入邮箱验证码
struct RegisterVerificationView: View {
    // 使用 Factory 容器获取 @Observable 的 ViewModel
    @State private var viewModel: RegisterViewModel = Container.shared.registerViewModel()
    @State private var countdownSeconds = 60
    @State private var canResend = false
    @State private var timer: Timer?
    @FocusState private var isCodeFieldFocused: Bool
    
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
                    Text("验证邮箱")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("我们已向您的邮箱发送了验证码")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                // 邮箱显示
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Text(viewModel.email)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // 验证码输入框
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("验证码")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if !viewModel.verificationCode.isEmpty {
                            Image(systemName: viewModel.isVerificationCodeValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.isVerificationCodeValid ? .green : .red)
                                .font(.system(size: 16))
                        }
                    }
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.gray)
                        
                        TextField("请输入6位验证码", text: $viewModel.verificationCode)
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                            .focused($isCodeFieldFocused)
                            .submitLabel(.done)
                            .onChange(of: viewModel.verificationCode) { _, newValue in
                                // 限制只能输入数字且最多6位
                                viewModel.verificationCode = filterVerificationCode(newValue)
                            }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCodeFieldFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    
                    if !viewModel.verificationCode.isEmpty && !viewModel.isVerificationCodeValid {
                        Text("请输入6位数字验证码")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // 重新发送验证码按钮
                HStack {
                    Button(action: resendCode) {
                        Text(canResend ? "重新发送验证码" : "重新发送 (\(viewModel.getCountdownText(seconds: countdownSeconds)))")
                            .font(.subheadline)
                            .foregroundColor(canResend ? .blue : .gray)
                    }
                    .disabled(!canResend || viewModel.isLoading)
                    
                    Spacer()
                }
                .padding(.vertical, 5)
                
                // 验证按钮
                Button(action: { viewModel.verifyCode() }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("验证并注册")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isVerificationCodeValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
                }
                .disabled(!viewModel.isVerificationCodeValid || viewModel.isLoading)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                
                Spacer()
                
                // 返回上一步
                Button(action: { viewModel.currentStep = .basicInfo }) {
                    Text("返回上一步")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .onAppear {
                startCountdown()
                isCodeFieldFocused = true
            }
            .onDisappear {
                stopCountdown()
            }
            .alert("验证错误", isPresented: $viewModel.showError) {
                Button("确定") { }
            } message: {
                Text(viewModel.errorMessage ?? "验证码错误")
            }
            .onSubmit {
                if viewModel.isVerificationCodeValid {
                    viewModel.verifyCode()
                }
            }
            .onTapGesture {
                isCodeFieldFocused = false
            }
        }
    }
    
    // MARK: - 重新发送验证码
    private func resendCode() {
        viewModel.resendCode()
        countdownSeconds = 60
        canResend = false
        startCountdown()
    }
    
    // MARK: - 倒计时
    private func startCountdown() {
        stopCountdown()
        canResend = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
            } else {
                canResend = true
                stopCountdown()
            }
        }
    }
    
    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
    }

    // 在RegisterVerificationView结构体内添加私有函数
    private func filterVerificationCode(_ newValue: String) -> String {
        // 限制只能输入数字且最多6位
        let filtered = newValue.filter { $0.isNumber }
        if filtered.count <= 6 {
            return filtered
        } else {
            return String(filtered.prefix(6))
        }
    }
}

// 默认为viewModel为空的初始化器
extension RegisterVerificationView {
    init () {
        self.init(viewModel: nil)
    }
}

// MARK: - 预览
struct RegisterVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterVerificationView(viewModel: createPreviewViewModel())
    }
    
    static func createPreviewViewModel() -> RegisterViewModel {
        let vm = RegisterViewModel()
        vm.email = "test@example.com"
        return vm
    }
}
