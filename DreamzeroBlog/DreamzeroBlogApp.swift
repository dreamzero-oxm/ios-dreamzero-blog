//
//  DreamzeroBlogApp.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/24.
//

import SwiftUI
import SwiftData
import Factory

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

    init() {
        // 注册共享的 ModelContainer 到 Factory 容器
        Container.shared.registerSharedModelContainer(sharedModelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await syncDefaultKnowledgeIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func syncDefaultKnowledgeIfNeeded() async {
        let service: DefaultKnowledgeServiceType = Container.shared.defaultKnowledgeService()

        // 每次启动都检查同步
        guard service.needsSync else { return }

        do {
            try await service.syncDefaultKnowledge()
        } catch {
            LogTool.shared.error("默认知识同步失败: \(error)")
        }
    }
}
