//
//  VideoListView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import ComposableArchitecture

struct VideoListView: View {
    let store: StoreOf<VideoListFeature>
    let appStore: StoreOf<AppFeature> // 즐겨찾기 등 연동 가능
    
    @Environment(\.presentationMode) private var presentationMode
    
    @Binding private var isGridLayout: Bool
    @State private var selectedYouTubeVideoItem: YouTubeVideo? = nil
    
    let columns = [
        GridItem(.flexible()), GridItem(.flexible())
    ]
    
    init(store: StoreOf<VideoListFeature>, appStore: StoreOf<AppFeature>, isGridLayout: Binding<Bool>) {
        self.store = store
        self.appStore = appStore
        self._isGridLayout = isGridLayout
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 8) {
                if viewStore.isLoading {
                    ProgressView("재생목록 불러오는 중...")
                } else if let error = viewStore.errorMessage {
                    Text(error).foregroundColor(.red)
                } else {
                    if isGridLayout {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewStore.videos) { video in
                                    NavigationLink(
                                        destination:
                                            VideoDetailView(video: video, store: appStore)
                                    ) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            ZStack(alignment: .bottomTrailing) {
                                                let url = video.thumbnailURL
                                                AsyncImage(url: URL(string: url)) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(height: 100)
                                                        .clipped()
                                                        .cornerRadius(6)
                                                } placeholder: {
                                                    ProgressView()
                                                        .frame(height: 100)
                                                }
                                                
                                                // ⏱ 재생 시간 오버레이
                                                if let duration = video.duration {
                                                    Text(duration)
                                                        .font(.caption2.weight(.semibold))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.black.opacity(0.7))
                                                        .cornerRadius(4)
                                                        .padding(6)
                                                }
                                            }
                                            
                                            Text(video.title)
                                                .font(.headline)
                                                .lineLimit(2)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .transition(.opacity.combined(with: .scale))
                        }
                    } else {
                        List {
                            ForEach(viewStore.videos) { video in
                                NavigationLink(
                                    destination: VideoDetailView(video: video, store: appStore)
                                ) {
                                    VideoRowView(video: video)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle(viewStore.playlistItem?.title ?? "영상 목록")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                            Text("목록")
                                .font(.system(size: 18))
                        }
                        .foregroundColor(.primary)
                        .padding(8)
                    }
                }
                
                // 오른쪽: 레이아웃 전환 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isGridLayout.toggle()
                        }
                    }) {
                        Image(systemName: isGridLayout ? "list.bullet" : "square.grid.2x2")
                            .imageScale(.large)
                            .padding(8)
                    }
                    .accessibilityLabel("레이아웃 전환")
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}
