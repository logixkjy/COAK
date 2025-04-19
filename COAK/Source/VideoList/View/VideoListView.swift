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

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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
            .navigationTitle(viewStore.playlistTitle ?? "영상 목록")
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}
