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
    // AppDelegate를 SwiftUI에서 사용하기 위한 설정
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Firebase 중복 초기화 방지
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase initialized in COAKApp")
        }
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
