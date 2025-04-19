//
//  VideoDetailView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import ComposableArchitecture

struct VideoDetailView: View {
    let video: YouTubeVideo
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { appViewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    YouTubePlayerView(videoId: video.id)
                        .frame(height: 220)
                    
                    Text(video.title)
                        .font(.title2)
                        .bold()
                    
                    Text(video.description)
                        .font(.body)
                        .foregroundColor(.gray)
                    if appViewStore.favoriteVideoIDs.contains(video.id) {
                        Button(action: {
                            appViewStore.send(.removeFromFavorites(video.id))
                        }) {
                            Label("즐겨찾기 삭제", systemImage: "star.fill"
                            )
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.gray)
                    } else {
                        Button(action: {
                            appViewStore.send(.addToFavorites(video))
                        }) {
                            Label("즐겨찾기 추가", systemImage: "star")
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("영상 상세")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
