//
//  UserProfileViewModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/30.
//

import SwiftUI
import PhotosUI
import Factory

/// User profile view model - handles profile operations
@Observable
final class UserProfileViewModel {
    // MARK: - State

    private(set) var user: User?
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var showError = false
    var showSuccess = false

    // MARK: - Editable Fields

    var nickname = ""
    var email = ""
    var phone = ""
    var bio = ""
    var website = ""
    var location = ""
    var birthday = ""
    var gender = ""

    // MARK: - Photo Picker

    var selectedPhotoItem: PhotosPickerItem?
    var avatarImageData: Data?

    // MARK: - Dependencies

    private let authSession: AuthSessionManager
    private let userRepository: UserRepositoryType

    init(
        authSession: AuthSessionManager = .shared,
        userRepository: UserRepositoryType? = nil
    ) {
        self.authSession = authSession
        // Use injected repository or get from container
        if let userRepository = userRepository {
            self.userRepository = userRepository
        } else {
            // Use injected apiClient which has AuthInterceptor
            self.userRepository = Container.shared.userRepository()
        }
    }

    // MARK: - Load Profile

    func loadProfile() async {
        isLoading = true

        do {
            let user = try await userRepository.getProfile()
            await MainActor.run {
                self.user = user
                self.updateFields(from: user)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.showError(message: "加载用户信息失败: \(error.localizedDescription)")
            }
        }
    }

    private func updateFields(from user: User) {
        nickname = user.nickname
        email = user.email ?? ""
        phone = user.phone ?? ""
        bio = user.bio ?? ""
        website = user.website ?? ""
        location = user.location ?? ""
        birthday = user.birthday ?? ""
        gender = user.gender ?? ""
    }

    // MARK: - Save Profile

    func saveProfile() async {
        isSaving = true

        do {
            let success = try await userRepository.updateProfile(
                nickname: nickname.isEmpty ? nil : nickname,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                bio: bio.isEmpty ? nil : bio,
                website: website.isEmpty ? nil : website,
                location: location.isEmpty ? nil : location,
                birthday: birthday.isEmpty ? nil : birthday,
                gender: gender.isEmpty ? nil : gender
            )

            if success {
                // Refresh user data in auth session
                try? await authSession.refreshUserData()

                // Reload profile
                await loadProfile()

                await MainActor.run {
                    self.isSaving = false
                    self.showSuccess = true
                }
            }
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.showError(message: "保存失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Upload Avatar

    func uploadAvatar() async {
        guard let imageData = avatarImageData else { return }

        isLoading = true

        do {
            let _ = try await userRepository.uploadAvatar(
                imageData: imageData,
                fileName: "avatar_\(UUID().uuidString).jpg"
            )

            await MainActor.run {
                self.isLoading = false
                self.avatarImageData = nil
                // Refresh profile to get updated avatar
                Task {
                    await self.loadProfile()
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.showError(message: "上传头像失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Error Handling

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    // MARK: - Logout

    func logout() {
        authSession.logout()
    }
}
