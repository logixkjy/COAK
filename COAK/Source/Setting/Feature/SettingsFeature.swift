//
//  SettingsFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import Foundation
import FirebaseAuth

struct SettingsFeature: Reducer {
    struct State: Equatable {
        var userEmail: String = ""
    }

    enum Action: Equatable {
        case onAppear
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if let user = Auth.auth().currentUser {
                    state.userEmail = user.email ?? ""
                }
                return .none
            }
        }
    }
}

// SettingsView.swift 에서는 이 Feature를 기반으로 유저 정보, 로그아웃 버튼 구성 가능
