//
//  PhotoRepository.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//

import Foundation

protocol PhotoRepositoryType {
    func fetchAll() async throws -> [Photo]
}

final class PhotoRepository: PhotoRepositoryType {
    private let client: APIClient
    init(client: APIClient) { self.client = client }

    func fetchAll() async throws -> [Photo] {
        // 创建对应的EndPoint
        let ep = GetPhotoListEndpoint()
        // 发起请求并解析响应
        let resp: SingleResponse<PhotoDto> = try await client.request(ep, as: SingleResponse<PhotoDto>.self)
        // 依据业务逻辑处理响应
        guard resp.code == 0 else {
            // 依据你的项目约定把业务错误往上抛
            throw APIError.server(code: resp.code, message: resp.msg)
        }
        // 检查 data
        guard let data = resp.data else {
            throw APIError.invalidResponse
        }
        // 打印日志
        LogTool.shared.debug("Fetched \(data.photos.count) photos.")
        return data.photos
    }
}
