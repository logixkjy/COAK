//
//  COAKApp.swift
//  COAK
//
//  Created by JooYoung Kim on 4/18/25.
//

import SwiftUI
import FirebaseCore
import ComposableArchitecture

@main
struct COAKApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(
                    initialState: AppFeature.State(),
                    reducer: {
                        AppFeature()
                    }
                )
            )
        }
    }
}
