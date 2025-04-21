//
//  PlaylistEditFeature.swift
//  COAK
//
//  Created by JooYoung Kim on 4/21/25.
//

import ComposableArchitecture
import Foundation

struct PlaylistEditFeature: Reducer {
    struct State: Equatable {
        var isLoading = false
        var groups: [PlaylistGroupEdit] = []
        var error: String?
    }
    
    enum Action: Equatable {
        case onAppear
        case playlistsLoaded(TaskResult<[PlaylistGroupEdit]>)
        case addGroup(String)
        case editGroup(String, String)
        case move(IndexSet, Int)
        case delete(IndexSet)
        case groupTapped(PlaylistGroupEdit)
    }
    
    @Dependency(\.playlistClient) var playlistClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    await send(.playlistsLoaded(TaskResult {
                        try await playlistClient.loadPlaylistsEdit()
                    }))
                }
                
            case let .playlistsLoaded(.success(groups)):
                state.groups = groups
                state.isLoading = false
                return .none
                
            case let .playlistsLoaded(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case let .addGroup(title):
                let newOrder = (state.groups.map(\.order).max() ?? 0) + 1
                let newGroup = PlaylistGroupEdit(title: title, playlists: [], order: newOrder)
                state.groups.append(newGroup)
                return .none
                
            case let .editGroup(id, newTitle):
                guard let index = state.groups.firstIndex(where: { $0.id == id }) else {
                    return .none
                }
                state.groups[index].title = newTitle

                return .none
                
            case let .move(indices, destination):
                state.groups.move(fromOffsets: indices, toOffset: destination)
                for (index, _) in state.groups.enumerated() {
                    state.groups[index].order = index + 1
                }
                return .none
                
            case let .delete(indices):
                state.groups.remove(atOffsets: indices)
                for (index, _) in state.groups.enumerated() {
                    state.groups[index].order = index + 1
                }
                return .none
                
            case .groupTapped:
                return .none
            }
        }
    }
}
