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
        
        var selectedGroupId: String? = nil
        var selectedPlaylist: PlaylistItem? = nil
    }
    
    enum Action: Equatable {
        case onAppear
        case playlistsLoaded(TaskResult<[PlaylistGroup]>)
        case youTubeMetadataLoaded(TaskResult<[PlaylistGroup]>)
        
        case selectGroup(String)
        case selectPlaylist(PlaylistItem)
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
//                let meta = try await youTubeClient.fetchPlaylistMetadata(allIds)
                let enriched = groups.map { group in
                    var newGroup = group
                    newGroup.playlists = group.playlists.map { item in
//                        if let m = meta[item.id] {
                            return PlaylistItem(
                                id: item.id,
                                title: item.title,
                                description: item.description,
                                thumbnailURL: "https://i.ytimg.com/vi/\(item.videoId)/hqdefault.jpg",
                                order: item.order,
                                videoId: item.videoId,
                                isPremiumRequired: item.isPremiumRequired
                            )
//                        } else { return item }
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
            
            
        case let .selectGroup(id):
            state.selectedGroupId = id
            return .none
            
        case let .selectPlaylist(item):
            state.selectedPlaylist = item
            return .none

        }
    }
}
