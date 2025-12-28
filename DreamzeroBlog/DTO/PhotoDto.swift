//
//  PhotoDto.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/12/24.
//


import Foundation

public struct PhotoDto: Decodable, Hashable {
    public let photos: [Photo]
    public let total: Int
    
    enum CodingKeys: String, CodingKey {
        case photos
        case total
    }
}
