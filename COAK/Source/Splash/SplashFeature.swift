//
//  SplashFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture

struct SplashFeature: Reducer {
    struct State: Equatable {}
    enum Action: Equatable {
        case onAppear
        case timerFinished
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    await send(.timerFinished)
                }
            case .timerFinished:
                return .none
            }
        }
    }
}
