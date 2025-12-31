//
//  AvatarView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI

struct AvatarView: View {
    let role: MessageRole
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: height)

            Image(systemName: iconName)
                .font(.system(size: size * 0.5))
                .foregroundColor(.white)
        }
    }

    private var iconName: String {
        switch role {
        case .user:
            return "person.circle.fill"
        case .assistant:
            return "brain.head.profile"
        case .system:
            return "info.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch role {
        case .user:
            return .blue
        case .assistant:
            return .purple
        case .system:
            return .orange
        }
    }

    private var height: CGFloat {
        size
    }
}
