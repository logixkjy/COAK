//
//  PlaylistEditFeature.swift
//  COAK
//
//  Created by JooYoung Kim on 4/21/25.
//

import ComposableArchitecture
import Foundation

enum SaveError: Error, Equatable {
    case unknown
}

struct PlaylistEditFeature: Reducer {
    struct State: Equatable {
        var isLoading = false
        var error: String?
        var groups: [PlaylistGroupEdit] = []
        var selectedGroupId: String? = nil
    }
    
    enum Action: Equatable {
        case onAppear
        case playlistsLoaded(TaskResult<[PlaylistGroupEdit]>)
        
        case addGroup(String)
        case editGroup(String, String)
        case moveGroup(IndexSet, Int)
        case deleteGroup(IndexSet)
        
        case selectGroup(String)
        case addItem(String, String, String)
        case editItem(String, String, String, String)
        case deleteItem(IndexSet)
        case moveItem(IndexSet, Int)
        case setPremium(String, Bool)
        
        case saveTapped
        case saveResultSuccess
        case saveResultFailure(SaveError)
    }
    
    @Dependency(\.playlistClient) var playlistClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            if !state.groups.isEmpty { return .none }
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
            let maxOrder = state.groups.map(\.order).max() ?? 0
            let newGroup = PlaylistGroupEdit(
                title: title,
                playlists: [],
                order: maxOrder + 1
            )
            state.groups.append(newGroup)
            return .none
            
        case let .editGroup(id, newTitle):
            if let idx = state.groups.firstIndex(where: { $0.id == id }) {
                state.groups[idx].title = newTitle
            }
            return .none
            
        case let .moveGroup(indices, destination):
            state.groups.move(fromOffsets: indices, toOffset: destination)
            for (index, _) in state.groups.enumerated() {
                state.groups[index].order = index
            }
            return .none
            
        case let .deleteGroup(indices):
            state.groups.remove(atOffsets: indices)
            for (index, _) in state.groups.enumerated() {
                state.groups[index].order = index + 1
            }
            return .none
            
        case let .selectGroup(id):
            state.selectedGroupId = id
            return .none
            
        case let .addItem(title, playlistId, isPremium):
            guard let groupIdx = state.groups.firstIndex(where: { $0.id == state.selectedGroupId }) else { return .none }
            let maxOrder = state.groups[groupIdx].playlists.map(\.order).max() ?? 0
            state.groups[groupIdx].playlists.append(
                PlaylistItemEdit(id: playlistId, title: title, order: maxOrder + 1, isPremiumRequired: isPremium)
            )
            return .none

        case let .editItem(id, title, playlistId, isPremium):
            guard let groupIdx = state.groups.firstIndex(where: { $0.id == state.selectedGroupId }) else { return .none }
            if let index = state.groups[groupIdx].playlists.firstIndex(where: { $0.id == id }) {
                state.groups[groupIdx].playlists[index].id = playlistId
                state.groups[groupIdx].playlists[index].title = title
                state.groups[groupIdx].playlists[index].isPremiumRequired = isPremium
            }
            return .none
            
        case let .deleteItem(indexSet):
            guard let groupIdx = state.groups.firstIndex(where: { $0.id == state.selectedGroupId }) else { return .none }
            state.groups[groupIdx].playlists.remove(atOffsets: indexSet)
            return .none
            
        case let .moveItem(indices, destination):
            guard let groupIdx = state.groups.firstIndex(where: { $0.id == state.selectedGroupId }) else { return .none }
            state.groups[groupIdx].playlists.move(fromOffsets: indices, toOffset: destination)
            for i in state.groups[groupIdx].playlists.indices {
                state.groups[groupIdx].playlists[i].order = i
            }
            return .none
            
        case let .setPremium(id, isPremium):
            guard let groupIdx = state.groups.firstIndex(where: { $0.id == state.selectedGroupId }) else { return .none }
            if let index = state.groups[groupIdx].playlists.firstIndex(where: { $0.id == id }) {
                state.groups[groupIdx].playlists[index].isPremiumRequired = isPremium ? "true" : "false"
            }
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
        }
    }
    
}
    

