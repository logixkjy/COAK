//
//  PlaylistFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import Foundation
import FirebaseFirestore

enum SaveError: Error, Equatable {
    case unknown
}
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
        case saveTapped
        case saveResultSuccess
        case saveResultFailure(SaveError)
        case updateGroups([PlaylistGroup])
        case addItem(toGroupIndex: Int)
        case moveItem(groupIndex: Int, source: IndexSet, destination: Int)
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
            
            
        case .saveTapped:
            return .run { [groups = state.groups] send in
                do {
                    try await playlistClient.savePlaylists(groups)
                    await send(.saveResultSuccess)
                } catch {
                    await send(.saveResultFailure(error as! SaveError))
                }
            }

        case let .saveResultFailure(error):
            state.error = "저장 실패: \(error.localizedDescription)"
            return .none

        case .saveResultSuccess:
            return .none

        case let .updateGroups(groups):
            state.groups = groups
            return .none
            
        case let .addItem(toGroupIndex):
            let currentItems = state.groups[toGroupIndex].playlists
            let maxOrder = currentItems.map { $0.order }.max() ?? 0
            let newItem = PlaylistItem(
                id: "",
                title: "",
                description: nil,
                thumbnailURL: nil,
                order: maxOrder + 1,
                isPremiumRequired: "false"
            )
            state.groups[toGroupIndex].playlists.append(newItem)
            return .none
            
        case let .moveItem(groupIndex, source, destination):
            state.groups[groupIndex].playlists.move(fromOffsets: source, toOffset: destination)
            for (index, _) in state.groups[groupIndex].playlists.enumerated() {
                state.groups[groupIndex].playlists[index].order = index + 1
            }
            return .none
        }
    }
}
