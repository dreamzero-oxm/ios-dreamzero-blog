//
//  PhotoEndpoint.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//
import Foundation
import Alamofire

/// 不要让这个类型处在任何 @MainActor 的作用域里
public struct GetPhotoListEndpoint: APIEndpoint {
    public init() {}

    public var path: String { "/api/v1/daily_photograph/user/b33ed0ca-6a5d-41a6-9e99-0c9d1db621ea" }
    public var method: HTTPMethod { .get }
    public var encoder: ParameterEncoder { URLEncodedFormParameterEncoder.default }
    public var requiresAuth: Bool { false }
}

