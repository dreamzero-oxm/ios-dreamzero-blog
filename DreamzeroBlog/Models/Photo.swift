//
//  Photo.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//

import Foundation

public struct Photo: Decodable, Identifiable, Hashable {
    public let id: String              // UUID 字符串
    public let createdAt: String       // "2025-11-27T14:01:45.205902Z"
    public let updatedAt: String
    public let imageURL: String
    public let title: String
    public let description: String
    public let tags: String
    public let userId: String
    public let takenAt: String
    public let location: String
    public let camera: String
    public let lens: String
    public let iso: Double
    public let aperture: Double
    public let shutterSpeed: Double
    public let focalLength: Int
    public let isPublic: Bool
    public let likes: Int
    public let views: Int

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt  = "created_at"
        case updatedAt  = "updated_at"
        case imageURL   = "image_url"
        case title
        case description
        case tags
        case userId     = "user_id"
        case takenAt    = "taken_at"
        case location
        case camera
        case lens
        case iso
        case aperture
        case shutterSpeed = "shutter_speed"
        case focalLength  = "focal_length"
        case isPublic     = "is_public"
        case likes
        case views
    }
}
