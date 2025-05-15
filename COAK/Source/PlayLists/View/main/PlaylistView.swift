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
    
    @State private var isPresented = false
    
    @State private var selectedPlaylistItem: PlaylistItem? = nil
    
    @State private var toastMessage: String? = nil
    
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
                                        VStack(alignment: .leading, spacing: 6) {
                                            ZStack {
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
                                                    
                                                    // 프리미엄 여부에 따른 딤 처리와 자물쇠 아이콘
                                                    if playlist.isPremiumRequired == true &&
                                                        (appStore.userProfile?.isPremium ?? false) == false &&
                                                        (appStore.userProfile?.isAdmin ?? false) == false {
                                                        Color.black.opacity(0.4) // 딤 처리
                                                            .cornerRadius(8)
                                                        
                                                        VStack {
                                                            Image(systemName: "lock.fill")
                                                                .resizable()
                                                                .frame(width: 20, height: 20)
                                                                .foregroundColor(.white)
                                                                .padding(8)
                                                                .background(Color.black.opacity(0.6))
                                                                .clipShape(Circle())
                                                        }
                                                    }
                                                }
                                            }
                                            Text(playlist.title)
                                                .font(.headline)
                                                .lineLimit(2)
                                                .foregroundColor(.white)
                                        }
                                        .onTapGesture {
                                            if playlist.isPremiumRequired == true &&
                                                (appStore.userProfile?.isPremium ?? false) == false &&
                                                (appStore.userProfile?.isAdmin ?? false) == false {
                                                showToast(message: "유료 컨텐츠 입니다.")
                                            } else {
                                                viewStore.send(.selectPlaylist(playlist))
                                                isPresented.toggle()
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
                                        ZStack {
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
                                            
                                            // 프리미엄 여부에 따른 딤 처리와 자물쇠 아이콘
                                            if playlist.isPremiumRequired == true &&
                                                (appStore.userProfile?.isPremium ?? false) == false &&
                                                (appStore.userProfile?.isAdmin ?? false) == false {
                                                Color.black.opacity(0.4) // 딤 처리
                                                    .cornerRadius(8)
                                                
                                                VStack {
                                                    Image(systemName: "lock.fill")
                                                        .resizable()
                                                        .frame(width: 20, height: 20)
                                                        .foregroundColor(.white)
                                                        .padding(8)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                }
                                            }
                                        }
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
                                    if playlist.isPremiumRequired == true &&
                                        (appStore.userProfile?.isPremium ?? false) == false &&
                                        (appStore.userProfile?.isAdmin ?? false) == false {
                                        showToast(message: "유료 컨텐츠 입니다.")
                                    } else {
                                        viewStore.send(.selectPlaylist(playlist))
                                        isPresented.toggle()
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .transition(.opacity.combined(with: .scale))
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
                .fullScreenCover(isPresented: $isPresented) {
                    VideoListView(
                        store: Store(
                            initialState: VideoListFeature.State(playlistItem: viewStore.selectedPlaylist!),
                            reducer: { VideoListFeature() }
                        ),
                        appStore: appStore,
                        isGridLayout: $isGridLayout
                    )
                }
                .overlay(
                    Group {
                        if let message = toastMessage {
                            VStack {
                                Spacer()
                                Text(message)
                                    .padding()
                                    .background(Color.black.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .padding(.bottom, 40)
                            }
                            .animation(.easeInOut, value: toastMessage)
                            .transition(.move(edge: .bottom))
                        }
                    }
                )
            }
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            toastMessage = nil
        }
    }
}
