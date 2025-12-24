//
//  PhotoGridView.swift
//  DreamzeroBlog
//
//  Created by dreamzero on 2025/10/27.
//

import SwiftUI
import Factory

struct PhotoGridView: View {
    // 使用 Factory 容器获取 @Observable 的 ViewModel
    @State private var vm: PhotoListViewModel = Container.shared.photoListViewModel()
    

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                switch vm.state {
                case .idle, .loading:
                    ProgressView("Loading…")
                        .task { vm.load() }

                case .loaded:
                    ScrollView {
                        WaterfallLayout(spacing: 8) {
                            ForEach(vm.photos.indices, id: \.self) { index in
                                let p = vm.photos[index]
                                cell(photo: p)
                                
                            }
                        }
                        .padding(8)
                    }
                    // （可选）图片加载后预取，提升滚动体验
                    .onChange(of: vm.photos) { _, newValue in
                        LogTool.shared.debug("Prefetching images for \(newValue.count) photos")
                        ImageLoaderCache.prefetch(urls: newValue.map(\.imageURL))
                    }

                case .failed(let msg):
                    VStack(spacing: 12) {
                        Text("加载失败").font(.headline)
                        Text(msg).font(.footnote).foregroundColor(.secondary)
                        Button("重试", action: vm.load)
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 32)
                }
            }
            .navigationTitle("日常照片")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func cell(photo: Photo) -> some View {
        // 用状态保存“当前已知”的纵横比：初始 1:1，加载成功后更新
        @State var ratio: CGFloat = 1

        ImageLoader(
            url: "https://www.dreamzero.cn" + photo.imageURL,
            onAspectRatio: { ratio = $0 }
        )
            
        // 关键：在测量阶段也有稳定高度 = colWidth * ratio
        .aspectRatio(ratio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

}

struct PhotoGridView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoGridView()
    }
}
