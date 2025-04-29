//
//  PlaylistView.swift
//  COAK
//
//  Created by JooYoung Kim on 4/28/25.
//

import SwiftUI
import ComposableArchitecture

struct PlaylistView: View {
    let store: StoreOf<PlaylistFeature>
    let appStore: StoreOf<AppFeature>
    
    @Environment(\.dismiss) private var dismiss
    
    @Binding private var isGridLayout: Bool
    @State private var selectedPlaylistItem: PlaylistItem? = nil
    
    let columns = [
        GridItem(.flexible()), GridItem(.flexible())
    ]
    
    init(store: StoreOf<PlaylistFeature>, appStore: StoreOf<AppFeature>,  isGridLayout: Binding<Bool>) {
        self.store = store
        self.appStore = appStore
        self._isGridLayout = isGridLayout
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            let selectedGroup = viewStore.groups.first(where: { $0.id == viewStore.selectedGroupId })
            let items = selectedGroup?.playlists.sorted(by: { $0.order < $1.order }) ?? []
            
            NavigationStack {
                VStack(spacing: 8) {
                    if viewStore.isLoading {
                        ProgressView("재생목록 불러오는 중...")
                    } else if let error = viewStore.error {
                        Text(error).foregroundColor(.red)
                    } else {
                        if isGridLayout {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(items) { playlist in
                                        NavigationLink(
                                            destination:
                                                VideoListView(
                                                    store: Store(
                                                        initialState: VideoListFeature.State(playlistItem: playlist),
                                                        reducer: {
                                                            VideoListFeature()
                                                        }
                                                    ),
                                                    appStore: appStore,
                                                    isGridLayout: $isGridLayout
                                                )
                                        ) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                if let url = playlist.thumbnailURL {
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
                                                }
                                                Text(playlist.title)
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
                            List(items) { playlist in
                                HStack(alignment: .top, spacing: 12) {
                                    if let url = playlist.thumbnailURL {
                                        AsyncImage(url: URL(string: url)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(16/9, contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                        }
                                        .frame(width: 160, height: 90)
                                        .clipped()
                                        .cornerRadius(8)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(playlist.title)
                                            .font(.headline)
                                            .lineLimit(2)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPlaylistItem = playlist
                                }
                            }
                            .listStyle(.plain)
                            .transition(.opacity.combined(with: .scale))
                            .background(
                                NavigationLink(
                                    destination: buildDestination(),
                                    isActive: Binding(
                                        get: { selectedPlaylistItem != nil },
                                        set: { isActive in
                                            if !isActive {
                                                selectedPlaylistItem = nil
                                            }
                                        }
                                    ),
                                    label: {
                                        EmptyView()
                                    }
                                )
                                .hidden()
                            )
                        }
                        
                    }
                }
                .navigationTitle(selectedGroup?.title ?? "재생록록")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .medium))
                                Text("홈")
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
            }
        }
    }
    
    private func buildDestination() -> some View {
        Group {
            if let item = selectedPlaylistItem {
                VideoListView(
                    store: Store(
                        initialState: VideoListFeature.State(playlistItem: item),
                        reducer: { VideoListFeature() }
                    ),
                    appStore: appStore,
                    isGridLayout: $isGridLayout
                )
            } else {
                EmptyView()
            }
        }
    }
}
