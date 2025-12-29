//
//  PhotoDetailView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import SwiftUI
import Kingfisher

/// 照片详情预览视图
struct PhotoDetailView: View {
    let photo: Photo
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var isDownloading: Bool = false
    @State private var downloadError: String?
    @State private var showSuccessAlert: Bool = false

    var imageURL: String {
        "https://www.dreamzero.cn" + photo.imageURL
    }

    // var body: some View {
    //     NavigationStack {
    //         ScrollView([.vertical, .horizontal]) {
    //             VStack(spacing: 8) {
    //                 // 大图（支持缩放）
    //                 GeometryReader { geometry in
    //                     KFImage(URL(string: imageURL))
    //                         .resizable()
    //                         .scaledToFit()
    //                         .scaleEffect(scale)
    //                         .offset(offset)
    //                         .gesture(
    //                             SimultaneousGesture(
    //                                 MagnificationGesture()
    //                                     .onChanged { value in
    //                                         scale = lastScale * value
    //                                     }
    //                                     .onEnded { _ in
    //                                         lastScale = scale
    //                                     },
    //                                 DragGesture()
    //                                     .onChanged { value in
    //                                         offset = value.translation
    //                                     }
    //                                     .onEnded { _ in
    //                                         withAnimation {
    //                                             offset = .zero
    //                                         }
    //                                     }
    //                             )
    //                         )
    //                         .frame(width: geometry.size.width)
    //                         .cornerRadius(12)
    //                         .onAppear {
    //                             // 图片加载完成后，根据实际尺寸调整缩放
    //                             if let url = URL(string: imageURL) {
    //                                 Task {
    //                                     do {
    //                                         let result = try await ImageDownloader.default.downloadImage(with: url)
    //                                         let imageSize = result.image.size
    //                                         let screenWidth = geometry.size.width

    //                                         // 如果图片宽度小于屏幕宽度，保持原始比例
    //                                         // 如果图片宽度大于屏幕宽度，缩放到屏幕宽度
    //                                         if imageSize.width < screenWidth {
    //                                             scale = 1.0
    //                                         } else {
    //                                             scale = screenWidth / imageSize.width
    //                                         }
    //                                         lastScale = scale
    //                                     } catch {
    //                                         // 使用默认缩放
    //                                         scale = 1.0
    //                                         lastScale = 1.0
    //                                     }
    //                                 }
    //                             }
    //                         }
    //                 }
    //                 .frame(height: 300)

    //                 // 照片信息卡片
    //                 VStack(alignment: .leading, spacing: 16) {
    //                     // 基础信息
    //                     if !photo.title.isEmpty {
    //                         Text(photo.title)
    //                             .font(.title2)
    //                             .fontWeight(.bold)
    //                     }

    //                     if !photo.description.isEmpty {
    //                         Text(photo.description)
    //                             .font(.body)
    //                             .foregroundColor(.secondary)
    //                     }

    //                     Divider()

    //                     // 拍摄信息
    //                     PhotoInfoSection(title: "拍摄信息", items: [
    //                         ("时间", formatDate(photo.takenAt)),
    //                         ("地点", photo.location),
    //                         ("相机", photo.camera),
    //                         ("镜头", photo.lens)
    //                     ].filter { !$0.1.isEmpty })

    //                     Divider()

    //                     // 摄影参数
    //                     PhotoInfoSection(title: "摄影参数", items: [
    //                         ("ISO", String(format: "%.0f", photo.iso)),
    //                         ("光圈", String(format: "f/%.1f", photo.aperture)),
    //                         ("快门", formatShutterSpeed(photo.shutterSpeed)),
    //                         ("焦距", "\(photo.focalLength)mm")
    //                     ])

    //                     // 标签
    //                     if !photo.tags.isEmpty {
    //                         Divider()
    //                         Text("标签")
    //                             .font(.headline)
    //                         Text(photo.tags)
    //                             .font(.body)
    //                             .foregroundColor(.secondary)
    //                     }
    //                 }
    //                 .frame(maxWidth: .infinity, alignment: .leading)
    //                 .padding()
    //                 .background(Color(.systemGray6))
    //                 .cornerRadius(12)
    //             }
    //             .frame(maxWidth: .infinity)
    //         }
    //         .navigationTitle("照片详情")
    //         .navigationBarTitleDisplayMode(.inline)
    //         .toolbar {
    //             ToolbarItem(placement: .navigationBarLeading) {
    //                 Button("关闭") {
    //                     onDismiss()
    //                 }
    //             }
    //             ToolbarItem(placement: .navigationBarTrailing) {
    //                 Button {
    //                     Task {
    //                         await downloadPhoto()
    //                     }
    //                 } label: {
    //                     if isDownloading {
    //                         ProgressView()
    //                     } else {
    //                         Image(systemName: "square.and.arrow.down")
    //                     }
    //                 }
    //                 .disabled(isDownloading)
    //             }
    //         }
    //         .contextMenu {
    //             Button {
    //                 Task {
    //                     await downloadPhoto()
    //                 }
    //             } label: {
    //                 Label("保存到相册", systemImage: "square.and.arrow.down")
    //             }
    //         }
    //         .alert("下载失败", isPresented: .constant(downloadError != nil)) {
    //             Button("确定") {
    //                 downloadError = nil
    //             }
    //         } message: {
    //             if let error = downloadError {
    //                 Text(error)
    //             }
    //         }
    //         .alert("保存成功", isPresented: $showSuccessAlert) {
    //             Button("确定") {}
    //         } message: {
    //             Text("照片已保存到相册")
    //         }
    //     }
    // }

        var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 大图（支持缩放）
                    GeometryReader { geometry in
                        ScrollView([.vertical, .horizontal], showsIndicators: false) {
                            KFImage(URL(string: imageURL))
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width)
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                scale = lastScale * value
                                            }
                                            .onEnded { _ in
                                                lastScale = scale
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                offset = value.translation
                                            }
                                            .onEnded { _ in
                                                withAnimation {
                                                    offset = .zero
                                                }
                                            }
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .frame(height: 300)
                    }
                    .frame(height: 300)

                    // 照片信息卡片
                    VStack(alignment: .leading, spacing: 16) {
                        // 基础信息
                        if !photo.title.isEmpty {
                            Text(photo.title)
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        if !photo.description.isEmpty {
                            Text(photo.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        // 拍摄信息
                        PhotoInfoSection(title: "拍摄信息", items: [
                            ("时间", formatDate(photo.takenAt)),
                            ("地点", photo.location),
                            ("相机", photo.camera),
                            ("镜头", photo.lens)
                        ].filter { !$0.1.isEmpty })

                        Divider()

                        // 摄影参数
                        PhotoInfoSection(title: "摄影参数", items: [
                            ("ISO", String(format: "%.0f", photo.iso)),
                            ("光圈", String(format: "f/%.1f", photo.aperture)),
                            ("快门", formatShutterSpeed(photo.shutterSpeed)),
                            ("焦距", "\(photo.focalLength)mm")
                        ])

                        // 标签
                        if !photo.tags.isEmpty {
                            Divider()
                            Text("标签")
                                .font(.headline)
                            Text(photo.tags)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("照片详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await downloadPhoto()
                        }
                    } label: {
                        if isDownloading {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                    .disabled(isDownloading)
                }
            }
            .contextMenu {
                Button {
                    Task {
                        await downloadPhoto()
                    }
                } label: {
                    Label("保存到相册", systemImage: "square.and.arrow.down")
                }
            }
            .alert("下载失败", isPresented: .constant(downloadError != nil)) {
                Button("确定") {
                    downloadError = nil
                }
            } message: {
                if let error = downloadError {
                    Text(error)
                }
            }
            .alert("保存成功", isPresented: $showSuccessAlert) {
                Button("确定") {}
            } message: {
                Text("照片已保存到相册")
            }
        }
    }


    private func downloadPhoto() async {
        isDownloading = true
        defer { isDownloading = false }

        do {
            try await PhotoSaveManager.shared.savePhoto(from: imageURL)
            showSuccessAlert = true
        } catch {
            downloadError = error.localizedDescription
        }
    }

    private func formatDate(_ dateString: String) -> String {
        // 解析并格式化日期
        if let date = ISO8601DateFormatter().date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: date)
        }
        return dateString
    }

    private func formatShutterSpeed(_ speed: Double) -> String {
        if speed >= 1 {
            return "\(Int(speed))\""
        } else {
            return "1/\(Int(1 / speed))"
        }
    }
}

/// 照片信息区块
struct PhotoInfoSection: View {
    let title: String
    let items: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ForEach(items, id: \.0) { label, value in
                HStack {
                    Text(label)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(value)
                        .fontWeight(.medium)
                }
            }
        }
    }
}
