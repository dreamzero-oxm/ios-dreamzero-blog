//
//  Response.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//

struct Response<T: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: [T]
}

struct SingleResponse<T: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: T?
}
