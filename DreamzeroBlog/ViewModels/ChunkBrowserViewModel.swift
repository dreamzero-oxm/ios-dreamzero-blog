//
//  ChunkBrowserViewModel.swift
//  DreamzeroBlog
//
//  Created by Claude on 2025/12/29.
//

import Foundation
import Observation

/// 分块浏览器 ViewModel
@MainActor
@Observable
final class ChunkBrowserViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case searching
        case failed(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.loaded, .loaded), (.searching, .searching):
                return true
            case (.failed(let lhsMsg), .failed(let rhsMsg)):
                return lhsMsg == rhsMsg
            default:
                return false
            }
        }
    }

    var state: State = .idle
    var chunks: [KBChunk] = []
    var searchResults: [KBSearchResult] = []
    var searchText: String = ""
    var isSearching = false

    private let knowledgeBaseVM: KnowledgeBaseViewModel

    init(knowledgeBaseVM: KnowledgeBaseViewModel) {
        self.knowledgeBaseVM = knowledgeBaseVM
    }

    func loadChunks() async {
        state = .loading
        await knowledgeBaseVM.loadChunks()
        chunks = knowledgeBaseVM.chunks
        state = .loaded
    }

    func searchChunks() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        state = .searching

        searchResults = await knowledgeBaseVM.searchChunks(query: searchText)

        isSearching = false
        state = .loaded

        LogTool.shared.info("Found \(searchResults.count) chunks for query: \(searchText)")
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        state = .loaded
    }
}
