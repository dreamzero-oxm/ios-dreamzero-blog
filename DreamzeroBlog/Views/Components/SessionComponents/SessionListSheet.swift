//
//  SessionListSheet.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/27.
//

import SwiftUI
import SwiftData

struct SessionListSheet: View {
    let modelContext: ModelContext
    @Binding var baseViewModel: ChatViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ChatSessionListView(
                onSelectSession: { session in
                    Task {
                        await baseViewModel.loadSession(session)
                        dismiss()
                    }
                },
                onDeleteSession: { session in
                    Task {
                        await baseViewModel.deleteSession(session)
                    }
                }
            )
            .navigationTitle("对话历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}
