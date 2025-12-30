//
//  UserProfileView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/30.
//

import SwiftUI
import PhotosUI

struct UserProfileView: View {
    @State private var viewModel = UserProfileViewModel()
    @State private var isEditing = false
    @State private var isPickingPhoto = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Avatar Section
                Section {
                    HStack {
                        Spacer()

                        Button(action: {
                            isPickingPhoto = true
                        }) {
                            if let avatarURL = viewModel.user?.avatar,
                               let url = URL(string: avatarURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                        .disabled(viewModel.isLoading)

                        Spacer()
                    }
                    .frame(height: 120)
                }

                // Basic Info Section
                Section("基本信息") {
                    HStack {
                        Text("用户名")
                            .frame(width: 80, alignment: .leading)
                        Text(viewModel.user?.userName ?? "")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("昵称")
                            .frame(width: 80, alignment: .leading)
                        TextField("昵称", text: $viewModel.nickname)
                            .disabled(!isEditing)
                    }

                    HStack {
                        Text("邮箱")
                            .frame(width: 80, alignment: .leading)
                        TextField("邮箱", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(!isEditing)
                    }

                    HStack {
                        Text("手机")
                            .frame(width: 80, alignment: .leading)
                        TextField("手机", text: $viewModel.phone)
                            .keyboardType(.phonePad)
                            .disabled(!isEditing)
                    }
                }

                // Personal Info Section
                Section("个人信息") {
                    HStack {
                        Text("简介")
                            .frame(width: 80, alignment: .leading)
                        TextField("简介", text: $viewModel.bio)
                            .disabled(!isEditing)
                    }

                    HStack {
                        Text("网站")
                            .frame(width: 80, alignment: .leading)
                        TextField("网站", text: $viewModel.website)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disabled(!isEditing)
                    }

                    HStack {
                        Text("所在地")
                            .frame(width: 80, alignment: .leading)
                        TextField("所在地", text: $viewModel.location)
                            .disabled(!isEditing)
                    }

                    HStack {
                        Text("生日")
                            .frame(width: 80, alignment: .leading)
                        TextField("YYYY-MM-DD", text: $viewModel.birthday)
                            .keyboardType(.numbersAndPunctuation)
                            .disabled(!isEditing)
                    }

                    Picker("性别", selection: $viewModel.gender) {
                        Text("未设置").tag("")
                        Text("男").tag("男")
                        Text("女").tag("女")
                    }
                    .disabled(!isEditing)
                }

                // Actions Section
                Section {
                    if isEditing {
                        Button("保存修改") {
                            Task {
                                await viewModel.saveProfile()
                                isEditing = false
                            }
                        }
                        .disabled(viewModel.isSaving)
                    } else {
                        Button("编辑资料") {
                            isEditing = true
                        }
                    }

                    Button("退出登录") {
                        viewModel.logout()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(viewModel.isLoading)
            .task {
                await viewModel.loadProfile()
            }
            .photosPicker(
                isPresented: $isPickingPhoto,
                selection: $viewModel.selectedPhotoItem,
                matching: .images
            )
            .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        viewModel.avatarImageData = data
                        await viewModel.uploadAvatar()
                    }
                }
            }
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("成功", isPresented: $viewModel.showSuccess) {
                Button("确定") {}
            } message: {
                Text("保存成功")
            }
        }
    }
}

#Preview {
    UserProfileView()
}
