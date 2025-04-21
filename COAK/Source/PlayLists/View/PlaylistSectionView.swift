//
//  PlaylistSectionView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import SwiftUI
import ComposableArchitecture

struct PlaylistSectionView: View {
    let title: String
    let playlists: [PlaylistItem]
    let appStore: StoreOf<AppFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
            .font(.title.bold())
            .lineLimit(1) // 섹션 타이틀 한 줄로 제한
            .truncationMode(.tail)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(playlists.sorted(by: { $0.order < $1.order })) { item in
                        NavigationLink(
                            destination: VideoListView(
                                store: Store(
                                    initialState: VideoListFeature.State(playlistId: item.id),
                                    reducer: { VideoListFeature() }
                                ),
                                appStore: appStore
                            )
                        ) {
                            PlaylistCardView(item: item)
                        }
                        .buttonStyle(.plain) // 카드 스타일 유지
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
