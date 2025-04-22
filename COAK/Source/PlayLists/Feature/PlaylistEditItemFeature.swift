//
//  PlaylistEditItemFeature.swift
//  COAK
//
//  Created by JooYoung Kim on 4/23/25.
//

import Foundation
import ComposableArchitecture

struct PlaylistEditItemFeature: Reducer {
    struct State: Equatable {
        var group: PlaylistGroupEdit
        var items: [PlaylistItemEdit] {
            get { group.playlists }
            set { group.playlists = newValue }
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case addItem(String, String) // title, playlistId
        case delete(IndexSet)
        case move(IndexSet, Int)
        case editItem(String, String, String) // id, title, playlistId
        case setPremium(String, Bool)
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            return .none
            
        case let .addItem(title, playlistId):
            let maxOrder = state.items.map { $0.order }.max() ?? 0
            let newItem = PlaylistItemEdit(
                id: playlistId,
                title: title,
                order: maxOrder + 1,
                isPremiumRequired: "false"
            )
            state.items.append(newItem)
            return .none
            
        case let .delete(indexSet):
            state.items.remove(atOffsets: indexSet)
            return .none
            
        case let .move(indices, destination):
            state.items.move(fromOffsets: indices, toOffset: destination)
            // move 이후 order 다시 정렬
            for (index, item) in state.items.enumerated() {
                state.items[index].order = index
            }
            return .none
            
        case let .editItem(id, title, playlistId):
            if let index = state.items.firstIndex(where: { $0.id == id }) {
                state.items[index].title = title
                state.items[index].id = playlistId
//                state.items[index].isPremiumRequired = isPremium ? "true" : "false"
            }
            return .none
            
        case let .setPremium(id, isPremium):
            if let index = state.items.firstIndex(where: { $0.id == id }) {
                state.items[index].isPremiumRequired = isPremium ? "true" : "false"
            }
            return .none
        }
    }
}
