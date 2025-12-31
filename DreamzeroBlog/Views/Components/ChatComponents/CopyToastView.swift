//
//  CopyToastView.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI

struct CopyToastView: View {
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = -20

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("已复制")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .cornerRadius(20)
        .padding(.top, 8)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1
                offset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 0
                    offset = -20
                }
            }
        }
    }
}
