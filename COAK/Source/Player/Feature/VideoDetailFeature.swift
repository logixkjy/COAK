//
//  VideoDetailFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture

struct VideoDetailFeature: Reducer {
    struct State: Equatable {
        let video: YouTubeVideo
        let playlistId: String
        var isFavorite = false
        var newComment = ""
//        var comments: [Comment] = []
    }

    enum Action: Equatable {
        case onAppear
//        case toggleFavoriteTapped
        case favoriteResult(Bool)
//        case commentChanged(String)
//        case commentsLoaded([Comment])
//        case postCommentTapped
//        case commentPostedSucceeded
//        case commentPostedFailed
    }

    @Dependency(\.favoritesClient) var favoritesClient
//    @Dependency(\.commentClient) var commentClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .merge(
                    .run { [videoId = state.video.id] send in
                        let isFav = try await favoritesClient.isFavorite(videoId)
                        await send(.favoriteResult(isFav))
                    }
//                    .run { [videoId = state.video.id] send in
//                        let comments = try await commentClient.fetchComments(videoId)
//                        await send(.commentsLoaded(comments))
//                    }
                )

            case let .favoriteResult(result):
                state.isFavorite = result
                return .none

//            case .toggleFavoriteTapped:
//                return .run { [video = state.video] send in
//                    try await favoritesClient.toggleFavorite(video)
//                    let isFav = try await favoritesClient.isFavorite(video.id)
//                    await send(.favoriteResult(isFav))
//                }

//            case let .commentChanged(text):
//                state.newComment = text
//                return .none
//
//            case let .commentsLoaded(comments):
//                state.comments = comments
//                return .none
//
//            case .postCommentTapped:
//                let content = state.newComment.trimmingCharacters(in: .whitespacesAndNewlines)
//                guard !content.isEmpty else { return .none }
//                state.newComment = ""
//                return .run { [videoId = state.video.id] send in
//                    try await commentClient.postComment(videoId, content)
//                    let comments = try await commentClient.fetchComments(videoId)
//                    await send(.commentsLoaded(comments))
//                }
//
//            case .commentPostedSucceeded:
//                return .none
//            case .commentPostedFailed:
//                return .none
            }
        }
    }
}
