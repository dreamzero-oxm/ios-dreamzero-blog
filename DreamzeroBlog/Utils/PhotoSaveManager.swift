//
//  PhotoSaveManager.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import UIKit
import Photos
import Kingfisher

/// 照片保存管理器
class PhotoSaveManager {
    static let shared = PhotoSaveManager()

    private init() {}

    /// 保存图片到相册
    func savePhoto(from urlString: String) async throws {
        // 检查权限
        let authorized = await checkPhotoLibraryPermission()
        guard authorized else {
            throw PhotoSaveError.permissionDenied
        }

        // 下载图片数据
        guard let url = URL(string: urlString) else {
            throw PhotoSaveError.invalidURL
        }

        let data = try await downloadImageData(from: url)

        // 保存到相册
        try await saveToPhotoLibrary(data: data)
    }

    /// 检查相册权限
    private func checkPhotoLibraryPermission() async -> Bool {
        if #available(iOS 14, *) {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return status == .authorized || status == .limited
        } else {
            // iOS 14 以下使用回调方式
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }

    /// 下载图片数据
    private func downloadImageData(from url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            ImageDownloader.default.downloadImage(with: url) { result in
                switch result {
                case .success(let imageResult):
                    // originalData 是 Data 属性
                    continuation.resume(returning: imageResult.originalData)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 保存到相册
    private func saveToPhotoLibrary(data: Data) async throws {
        guard let image = UIImage(data: data) else {
            throw PhotoSaveError.invalidImage
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoSaveError.saveFailed)
                }
            }
        }
    }
}

/// 照片保存错误
enum PhotoSaveError: LocalizedError {
    case permissionDenied
    case invalidURL
    case downloadFailed
    case invalidImage
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "无法访问相册，请在设置中允许访问"
        case .invalidURL:
            return "无效的图片地址"
        case .downloadFailed:
            return "图片下载失败"
        case .invalidImage:
            return "无效的图片格式"
        case .saveFailed:
            return "保存失败"
        }
    }
}
