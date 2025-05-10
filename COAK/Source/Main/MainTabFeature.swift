//
//  MainTabFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import Foundation

enum Tab: Hashable {
    case playlist, favorites, notices, settings, admin
}

struct MainTabFeature: Reducer {
    struct State: Equatable {
        var selectedTab = Tab.playlist
        var playlistState = PlaylistFeature.State()
        var announcementState = AnnouncementFeature.State()
        var settingsState = SettingsFeature.State()

        var isAdmin: Bool = false // Firestore 유저 role에서 판단
    }

    enum Action: Equatable {
        case playlistAction(PlaylistFeature.Action)
        case announcementAction(AnnouncementFeature.Action)
        case settingsAction(SettingsFeature.Action)
        case tabSelected(Tab)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.playlistState, action: /Action.playlistAction) { PlaylistFeature() }
        Scope(state: \.announcementState, action: /Action.announcementAction) { AnnouncementFeature() }
        Scope(state: \.settingsState, action: /Action.settingsAction) { SettingsFeature() }
        
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
            default:
                return .none
            }
        }
    }
}
