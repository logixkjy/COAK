//
//  AdminPushFeature.swift
//  COAK
//
//  Created by JooYoung Kim on 5/14/25.
//

import ComposableArchitecture
import Foundation

struct AdminPushFeature: Reducer {
    struct State: Equatable {
        var title: String = ""
        var body: String = ""
        var pushResult: String = ""
        var isSuccess: Bool = false
    }
    
    enum Action: Equatable {
        case sendPush(String, String)
        case pushResult(Result<String, CustomError>)
    }
    
    @Dependency(\.adminPushClient) var adminPushClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
            
        case .sendPush(let title, let body):
            state.pushResult = ""
            state.isSuccess = false
            state.title = title
            state.body = body
            
            return .run { [title = state.title, body = state.body] send in
                do {
                    try await adminPushClient.sendPush(title, body)
                    await send(.pushResult(.success("Push sent successfully.")))
                } catch {
                    await send(.pushResult(.failure(.firebaseError(error.localizedDescription))))
                }
            }
            
        case let .pushResult(.success(message)):
            state.pushResult = message
            state.isSuccess = true
            return .none
            
        case let .pushResult(.failure(error)):
            state.pushResult = "Error: \(error.localizedDescription)"
            return .none
            
            
        }
    }
}
