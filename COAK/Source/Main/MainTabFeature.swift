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
        var announcementCommentState = AnnouncementCommentFeature.State()
        var settingsState = SettingsFeature.State()
        
        var isLoggedIn: Bool = false
    }

    enum Action: Equatable {
        case playlistAction(PlaylistFeature.Action)
        case announcementAction(AnnouncementFeature.Action)
        case announcementCommentAction(AnnouncementCommentFeature.Action)
        case settingsAction(SettingsFeature.Action)
        case tabSelected(Tab)
        case loginStatusChanged(Bool)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.playlistState, action: /Action.playlistAction) { PlaylistFeature() }
        Scope(state: \.announcementState, action: /Action.announcementAction) { AnnouncementFeature() }
        Scope(state: \.announcementCommentState, action: /Action.announcementCommentAction) { AnnouncementCommentFeature() }
        Scope(state: \.settingsState, action: /Action.settingsAction) { SettingsFeature() }
        
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .loginStatusChanged(let status):
                state.isLoggedIn = status
                state.selectedTab = Tab.playlist
                return .none
                
            default:
                return .none
            }
        }
    }
}
