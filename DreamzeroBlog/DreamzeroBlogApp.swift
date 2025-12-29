//
//  DreamzeroBlogApp.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/24.
//

import SwiftUI
import SwiftData

@main
struct DreamzeroBlogApp: App {
    /// SwiftData ModelContainer 配置
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ChatSessionModel.self,
            ChatMessageModel.self,
            KBDocumentModel.self,
            KBChunkModel.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
