//
//  MainTabView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import ComposableArchitecture

struct MainTabView: View {
    let store: StoreOf<MainTabFeature>
    let appStore: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            TabView(selection: viewStore.binding(get: \.selectedTab, send: MainTabFeature.Action.tabSelected)) {

                MainHomeView(
                    store: store.scope(state: \.playlistState, action: MainTabFeature.Action.playlistAction),
                    appStore: appStore,
                    annoucementStore: store.scope(state: \.announcementState, action: MainTabFeature.Action.announcementAction)
                )
                .tabItem {
                    Label("main_home", systemImage: "house")
                }
                .tag(Tab.playlist)

                FavoritesView(
                    appStore: appStore
                )
                .tabItem {
                    Label("main_favorites", systemImage: "star")
                }
                .tag(Tab.favorites)
                
                AnnouncementListView(store: store.scope(state: \.announcementState, action: MainTabFeature.Action.announcementAction),
                                     appStore: appStore
                )
                .tabItem {
                    Label("main_notice", systemImage: "megaphone")
                }
                .tag(Tab.notices)

                SettingsView(
                    store: store.scope(state: \.settingsState, action: MainTabFeature.Action.settingsAction),
                    appStore: appStore,
                    announcementStore: store.scope(state: \.announcementState, action: MainTabFeature.Action.announcementAction)
                )
                .tabItem {
                    Label("main_setting", systemImage: "gear")
                }
                .tag(Tab.settings)
            }
            .onAppear {
                viewStore.send(.loginStatusChanged(true))
            }
        }
    }
}
