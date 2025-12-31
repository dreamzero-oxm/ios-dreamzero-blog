//
//  RecentSessionCell.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI

struct RecentSessionCell: View {
    let session: ChatSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "message.circle")
                .font(.system(size: 24))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Text(relativeTimeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var relativeTimeString: String {
        let interval = Date().timeIntervalSince(session.updatedAt)
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else {
            return "\(Int(interval / 86400))天前"
        }
    }
}
