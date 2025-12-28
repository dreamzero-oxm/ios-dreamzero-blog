//
//  ContentView.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            // 文章列表
            ArticleListView()
                .tabItem {
                    Label("文章", systemImage: "doc.text")
                }
            
            // Daily Photo View
            PhotoGridView()
                .tabItem {
                    Label("日常照片", systemImage: "photo")
                }
            
            ChatView()
                .tabItem {
                    Label("AI聊天", systemImage: "message")
                }
            
            // Login Tab
            LoginView()
                .tabItem {
                    Label("我的", systemImage: "person.crop.circle")
                }
            
        }
    }
}


#Preview {
    ContentView()
}
