//
//  ArticleTheme.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/28.
//

import MarkdownUI
import SwiftUI

extension Theme {
    /// 文章详情页专用 Markdown 主题
    /// 优化了阅读体验，更大的字号和行间距
    public static let article = Theme()
        .text {
            ForegroundColor(.text)
            BackgroundColor(.background)
            FontSize(17)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.9))
            ForegroundColor(.codeText)
            BackgroundColor(.codeBackground)
        }
        .strong {
            FontWeight(.semibold)
        }
        .link {
            ForegroundColor(.link)
        }
        .heading1 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 32, bottom: 16)
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(2))
                }
        }
        .heading2 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 28, bottom: 14)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.6))
                }
        }
        .heading3 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 24, bottom: 12)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.3))
                }
        }
        .heading4 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 20, bottom: 10)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.1))
                }
        }
        .heading5 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 16, bottom: 8)
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1))
                }
        }
        .heading6 { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.125))
                .markdownMargin(top: 16, bottom: 8)
                .markdownTextStyle {
                    FontWeight(.regular)
                    FontSize(.em(1))
                    ForegroundColor(.tertiaryText)
                }
        }
        .paragraph { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .relativeLineSpacing(.em(0.3))
                .markdownMargin(top: 0, bottom: 16)
        }
        .blockquote { configuration in
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blockquoteBorder)
                    .relativeFrame(width: .em(0.15))
                configuration.label
                    .markdownTextStyle {
                        ForegroundColor(.secondaryText)
                        FontSize(.em(1.05))
                    }
                    .relativePadding(.horizontal, length: .em(0.8))
            }
            .fixedSize(horizontal: false, vertical: true)
            .markdownMargin(top: 8, bottom: 16)
        }
        .codeBlock { configuration in
            ScrollView(.horizontal) {
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .relativeLineSpacing(.em(0.25))
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.9))
                        ForegroundColor(.codeText)
                    }
                    .padding(16)
            }
            .background(Color.codeBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.codeBorder, lineWidth: 1)
            )
            .markdownMargin(top: 12, bottom: 20)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.3))
        }
        .taskListMarker { configuration in
            Image(systemName: configuration.isCompleted ? "checkmark.circle.fill" : "circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.checkbox, Color.checkboxBackground)
                .imageScale(.small)
                .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
        }
        .table { configuration in
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
                .markdownTableBorderStyle(.init(color: .tableBorder))
                .markdownTableBackgroundStyle(
                    .alternatingRows(Color.tableRow1, Color.tableRow2)
                )
                .markdownMargin(top: 16, bottom: 20)
        }
        .tableCell { configuration in
            configuration.label
                .markdownTextStyle {
                    if configuration.row == 0 {
                        FontWeight(.semibold)
                    }
                    BackgroundColor(nil)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .relativeLineSpacing(.em(0.25))
        }
        .thematicBreak {
            Divider()
                .relativeFrame(height: .em(0.3))
                .overlay(Color.divider)
                .markdownMargin(top: 32, bottom: 32)
        }
}
