//
//  RegisterViewModel.swift
//  DreamzeroBlog
//
//  Created by AI Assistant on 2025/10/25.
//

import SwiftUI

/// 注册视图模型 - 处理注册流程的业务逻辑
@Observable
class RegisterViewModel {
    // MARK: - 输入字段
    var email = "" {
        didSet {
            validateEmail()
        }
    }
    var username = "" {
        didSet {
            validateUsername()
        }
    }
    var password = "" {
        didSet {
            validatePassword()
            validateConfirmPassword() // 密码改变时重新验证确认密码
        }
    }
    var confirmPassword = "" {
        didSet {
            validateConfirmPassword()
        }
    }
    var verificationCode = "" {
        didSet {
            validateVerificationCode()
        }
    }
    
    // MARK: - UI状态
    var isLoading = false
    var showPassword = false
    var showConfirmPassword = false
    var currentStep: RegisterStep = .basicInfo
    var errorMessage: String?
    var showError = false
    
    // MARK: - 验证状态
    var isEmailValid = false
    var isUsernameValid = false
    var isPasswordValid = false
    var isConfirmPasswordValid = false
    var isVerificationCodeValid = false
    
    // MARK: - 注册步骤枚举
    enum RegisterStep {
        case basicInfo      // 基本信息（邮箱、用户名、密码）
        case verification   // 验证码
        case success        // 注册成功
    }
    
    init() {
        // 初始化验证状态
        validateEmail()
        validateUsername()
        validatePassword()
        validateConfirmPassword()
        validateVerificationCode()
    }
    
    // MARK: - 验证方法
    private func validateEmail() {
        // 简单的邮箱格式验证
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        isEmailValid = emailPredicate.evaluate(with: email)
    }
    
    // 验证用户名
    private func validateUsername() {
        // 用户名验证（3-20个字符，只能包含字母、数字、下划线）
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        isUsernameValid = usernamePredicate.evaluate(with: username)
    }
    
    // 验证密码
    private func validatePassword() {
        // 密码验证（至少8个字符，包含字母和数字）
        isPasswordValid = password.count >= 8 && 
                         password.rangeOfCharacter(from: .letters) != nil &&
                         password.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    private func validateConfirmPassword() {
        // 确认密码验证
        isConfirmPasswordValid = !confirmPassword.isEmpty && password == confirmPassword
    }
    
    private func validateVerificationCode() {
        // 验证码验证（6位数字）
        let codeRegex = "^\\d{6}$"
        let codePredicate = NSPredicate(format: "SELF MATCHES %@", codeRegex)
        isVerificationCodeValid = codePredicate.evaluate(with: verificationCode)
    }
    
    // MARK: - 基本信息的有效性
    var isBasicInfoValid: Bool {
        isEmailValid && isUsernameValid && isPasswordValid && isConfirmPasswordValid
    }
    
    // MARK: - 注册操作
    func register() {
        guard isBasicInfoValid else {
            showError(message: "请确保所有信息填写正确")
            return
        }
        
        isLoading = true
        
        errorMessage = nil
        
        // 模拟注册请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isLoading = false
            // 模拟发送验证码成功
            self?.currentStep = .verification
            print("发送验证码到邮箱: \(self?.email ?? "")")
        }
    }
    
    // MARK: - 验证验证码
    func verifyCode() {
        guard isVerificationCodeValid else {
            showError(message: "请输入6位数字验证码")
            return
        }
        
        isLoading = true
        
        // 模拟验证码验证
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isLoading = false
            // 模拟验证成功
            self?.currentStep = .success
            print("验证码验证成功")
        }
    }
    
    // MARK: - 重新发送验证码
    func resendCode() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
            print("重新发送验证码到邮箱: \(self?.email ?? "")")
        }
    }
    
    // MARK: - 完成注册
    func completeRegistration() {
        // 重置所有状态
        reset()
    }
    
    // MARK: - 重置
    func reset() {
        email = ""
        username = ""
        password = ""
        confirmPassword = ""
        verificationCode = ""
        currentStep = .basicInfo
        errorMessage = nil
        showError = false
        isLoading = false
        
        // 重新验证
        validateEmail()
        validateUsername()
        validatePassword()
        validateConfirmPassword()
        validateVerificationCode()
    }
    
    // MARK: - 错误处理
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - 获取验证码倒计时文本
    func getCountdownText(seconds: Int) -> String {
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
