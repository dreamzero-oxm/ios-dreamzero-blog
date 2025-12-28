//
//  ThemeColor+Extensions.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/28.
//

import SwiftUI

extension Color {
    // MARK: - 通用颜色

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

    // MARK: - 代码块颜色

    /// 代码文本颜色
    static let codeText = Color.primary

    /// 代码背景颜色
    static let codeBackground = Color(.systemGray6)

    /// 代码边框颜色
    static let codeBorder = Color(.systemGray4)

    // MARK: - 引用块颜色

    /// 引用块边框颜色
    static let blockquoteBorder = Color.blue.opacity(0.5)

    // MARK: - 表格颜色

    /// 表格边框颜色
    static let tableBorder = Color(.systemGray4)

    /// 表格第一行颜色
    static let tableRow1 = Color.clear

    /// 表格第二行颜色
    static let tableRow2 = Color(.systemGray6).opacity(0.3)
}
