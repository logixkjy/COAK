//
//  MainHomeView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import SwiftUI
import ComposableArchitecture

struct MainHomeView: View {
    let store: StoreOf<PlaylistFeature>
    let appStore: StoreOf<AppFeature>
    let annoucementStore: StoreOf<AnnouncementFeature>

    @State private var isPresented = false
    
    @State private var isPresentedVideoList = false
    
    @State private var isGridLayout = false

    var body: some View {
        NavigationStack {
            WithViewStore(store, observe: { $0 }) { viewStore in
                VStack(spacing: 0) {
                    
                    HStack {
                        Text("Sonjin bagsh")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // 프로필 이미지
                        if let url = URL(string: appStore.userProfile?.profileImageURL ?? "") {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().frame(width: 36, height: 36).clipShape(Circle())
                                default:
                                    Circle().frame(width: 36, height: 36).foregroundColor(.gray)
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // 상단 공지 배너
                    TopNoticeBannerPlaceholderView(store: annoucementStore, appStore: appStore)
                        .frame(height: 120)
                        .background(Color.orange.opacity(0.3))
                        .padding(.top, 8)
                    
                    ScrollView {
                        LazyVStack(spacing: 32, pinnedViews: [.sectionHeaders]) {
                            ForEach(viewStore.groups) { group in
                                PlaylistSectionView(group: group, playlists: group.playlists, store: store, appStore: appStore, isPresented: $isPresented, isPresentedVideoList: $isPresentedVideoList, isGridLayout: $isGridLayout)
                            }
                            
                            // Scroll 내부에도 추가 공간 여유
                            Spacer().frame(height: 16)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    
//                    // 하단 고정 광고
//                    BottomAdPlaceholderView()
//                        .frame(height: 60)
//                        .background(Color.gray.opacity(0.2))
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
                .fullScreenCover(isPresented: $isPresented) {
                    PlaylistView(store: store, appStore: appStore, isGridLayout: $isGridLayout)
                }
                .fullScreenCover(isPresented: $isPresentedVideoList) {
                    VideoListView(
                        store: Store(
                            initialState: VideoListFeature.State(playlistItem: viewStore.selectedPlaylist!),
                            reducer: { VideoListFeature() }
                        ),
                        appStore: appStore,
                        isGridLayout: $isGridLayout,
                        isMain: true
                    )
                }
            }
        }
    }
}
