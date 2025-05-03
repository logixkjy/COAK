//
//  VideoListFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import Foundation

struct VideoListFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        let playlistItem: PlaylistItem?
        var videos: [YouTubeVideo] = []
        var youTubeVideo: YouTubeVideo?
        var isLoading: Bool = false
        var errorMessage: String?
    }
    
    enum Action: Equatable {
        case onAppear
        case videosLoaded(TaskResult<[YouTubeVideo]>)
        case setYouTubeVideo(YouTubeVideo)
    }
    
    @Dependency(\.youTubeClient) var youTubeClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {

        case .onAppear:
            state.isLoading = true
            return .run { [playlistId = state.playlistItem?.id] send in
                do {
                    let videos = try await youTubeClient.fetchPlaylistVideos(playlistId ?? "")
                    let durations = try await youTubeClient.fetchVideoDurations(videos.map(\.id))

                    let enriched = videos.map { video in
                        YouTubeVideo(
                            id: video.id,
                            title: video.title,
                            description: video.description,
                            thumbnailURL: video.thumbnailURL,
                            publishedAt: video.publishedAt,
                            duration: durations[video.id]
                        )
                    }

                    await send(.videosLoaded(.success(enriched)))
                } catch {
                    await send(.videosLoaded(.failure(error)))
                }
            }

        case let .videosLoaded(.success(videos)):
            state.videos = videos
            state.isLoading = false
            return .none

        case let .videosLoaded(.failure(error)):
            state.errorMessage = error.localizedDescription
            state.isLoading = false
            return .none
            
        case let .setYouTubeVideo(video):
            state.youTubeVideo = video
            return .none
        }
    }
}
