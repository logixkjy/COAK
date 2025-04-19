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

    var body: some View {
        NavigationStack {
            WithViewStore(store, observe: { $0 }) { viewStore in
                VStack(spacing: 0) {
                    // 상단 공지 배너
                    TopNoticeBannerPlaceholderView()
                        .frame(height: 120)
                        .background(Color.orange.opacity(0.3))
                    
                    ScrollView {
                        LazyVStack(spacing: 32, pinnedViews: [.sectionHeaders]) {
                            ForEach(viewStore.groups) { group in
                                PlaylistSectionView(title: group.title, playlists: group.playlists, appStore: appStore)
                            }
                            
                            // Scroll 내부에도 추가 공간 여유
                            Spacer().frame(height: 16)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    
                    // 하단 고정 광고
                    BottomAdPlaceholderView()
                        .frame(height: 60)
                        .background(Color.gray.opacity(0.2))
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
        }
    }
}
