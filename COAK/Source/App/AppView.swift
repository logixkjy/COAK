//
//  AppView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Group {
                if viewStore.isLoading {
                    SplashView()
                } else if !viewStore.isSignedIn {
                    AuthView(
                        store: store.scope(state: \.auth, action: AppFeature.Action.auth)
                    )
                } else if viewStore.isProfileIncomplete {
                    ProfileUpdateView(store: store)
                } else {
                    MainTabView(
                        store: store.scope(state: \.mainTab, action: AppFeature.Action.mainTab),
                        appStore: store
                    )
                }
            }
            .onAppear {
                viewStore.send(.onLaunch)
            }
        }
    }
}
