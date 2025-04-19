//
//  PlaylistFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import Foundation
import FirebaseFirestore

// MARK: - PlaylistFeature
struct PlaylistFeature: Reducer {
    struct State: Equatable {
        var groups: [PlaylistGroup] = []
        var isLoading = false
        var error: String?
    }
    
    enum Action: Equatable {
        case onAppear
        case playlistsLoaded(TaskResult<[PlaylistGroup]>)
        case youTubeMetadataLoaded(TaskResult<[PlaylistGroup]>)
    }
    
    @Dependency(\.playlistClient) var playlistClient
    @Dependency(\.youTubeClient) var youTubeClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            state.isLoading = true
            return .run { send in
                await send(.playlistsLoaded(TaskResult {
                    try await playlistClient.loadPlaylists()
                }))
            }
            
        case let .playlistsLoaded(.success(groups)):
            let allIds = groups.flatMap { $0.playlists.map(\.id) }
            return .run { send in
                let meta = try await youTubeClient.fetchPlaylistMetadata(allIds)
                let enriched = groups.map { group in
                    var newGroup = group
                    newGroup.playlists = group.playlists.map { item in
                        if let m = meta[item.id] {
                            return PlaylistItem(
                                id: item.id,
                                title: m.title,
                                description: m.description,
                                thumbnailURL: m.thumbnailURL,
                                order: item.order,
                                isPremiumRequired: item.isPremiumRequired
                            )
                        } else { return item }
                    }
                    return newGroup
                }
                await send(.youTubeMetadataLoaded(.success(enriched)))
            }
            
        case let .playlistsLoaded(.failure(error)),
            let .youTubeMetadataLoaded(.failure(error)):
            state.isLoading = false
            state.error = error.localizedDescription
            return .none
            
        case let .youTubeMetadataLoaded(.success(groups)):
            state.groups = groups
            state.isLoading = false
            return .none
        }
    }
}
