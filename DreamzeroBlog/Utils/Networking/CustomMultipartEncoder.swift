//
//  CustomMultipartEncoder.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/30.
//

import Foundation
import Alamofire

/// Custom encoder for multipart/form-data requests
/// Supports both form fields and file uploads
struct CustomMultipartEncoder: ParameterEncoder {
    let formData: Alamofire.Parameters?
    let imageData: Data?
    let fileName: String

    /// Initialize with form data only
    init(formData: Alamofire.Parameters? = nil) {
        self.formData = formData
        self.imageData = nil
        self.fileName = "file.jpg"
    }

    /// Initialize with image data for file upload
    init(imageData: Data, fileName: String = "avatar.jpg") {
        self.formData = nil
        self.imageData = imageData
        self.fileName = fileName
    }

    func encode<Parameters>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest {
        var request = request
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Encode form parameters if provided
        // Handle Encodable parameters by converting to dictionary using Mirror reflection
        var paramsDict: Alamofire.Parameters?
        if let encodableParams = parameters as? Encodable {
            // Use Mirror reflection to extract all properties
            let mirror = Mirror(reflecting: encodableParams)
            var dict = [String: Any]()
            for (label, value) in mirror.children {
                if let key = label {
                    dict[key] = value
                }
            }
            paramsDict = dict.isEmpty ? nil : (dict as Alamofire.Parameters)
        } else if let params = parameters as? Alamofire.Parameters {
            paramsDict = params
        } else {
            paramsDict = formData
        }

        if let params = paramsDict {
            for (key, value) in params {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        // Add image data if provided
        if let imageData = imageData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(imageData.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        // 记录 multipart 表单数据
        logMultipartFormData(parameters: paramsDict, imageData: imageData, fileName: fileName)

        return request
    }

    /// 记录 multipart 表单数据（脱敏敏感字段）
    private func logMultipartFormData(parameters: Alamofire.Parameters?, imageData: Data?, fileName: String) {
        var logMessage = "📦 [Multipart 请求体]"

        if let params = parameters {
            for (key, value) in params {
                // 脱敏敏感字段
                let displayValue: String
                if key.lowercased().contains("password") || key.lowercased().contains("pwd") {
                    displayValue = "***"
                } else if let stringValue = value as? String {
                    displayValue = stringValue.count > 50 ? "\(stringValue.prefix(50))..." : stringValue
                } else {
                    displayValue = "\(value)"
                }
                logMessage += "\n  \(key): \(displayValue)"
            }
        }

        if let imageData = imageData {
            logMessage += "\n  \(fileName): \(imageData.count) bytes (图片数据)"
        }

        LogTool.shared.debug(logMessage, category: .network)
    }
}

// MARK: - Data Extension for MIME Type Detection

extension Data {
    /// Detects MIME type based on image data
    var mimeType: String {
        var values = [UInt8](repeating: 0, count: 1)
        self.copyBytes(to: &values, count: 1)

        switch values[0] {
        case 0xFF:
            return "image/jpeg"
        case 0x89:
            return "image/png"
        case 0x47:
            return "image/gif"
        case 0x49, 0x4D:
            return "image/tiff"
        default:
            return "image/jpeg" // Default to JPEG
        }
    }
}
