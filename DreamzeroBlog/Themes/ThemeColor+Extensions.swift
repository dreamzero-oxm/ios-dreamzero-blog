//
//  ThemeColor+Extensions.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/28.
//

import SwiftUI

extension Color {
    /// 文本颜色
    static let text = Color.primary

    /// 背景颜色
    static let background = Color.clear

    /// 次要背景颜色
    static let secondaryBackground = Color(.systemGray5)

    /// 次要文本颜色
    static let secondaryText = Color.secondary

    /// 第三级文本颜色
    static let tertiaryText = Color.secondary.opacity(0.6)

    /// 链接颜色
    static let link = Color.blue

    /// 边框颜色
    static let border = Color(.systemGray4)

    /// 复选框颜色
    static let checkbox = Color.blue

    /// 复选框背景颜色
    static let checkboxBackground = Color(.systemGray5)

    /// 分割线颜色
    static let divider = Color(.systemGray4)
}
