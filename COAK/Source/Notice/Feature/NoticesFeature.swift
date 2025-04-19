//
//  NoticesFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import FirebaseFirestore
import Foundation

// MARK: - NoticeFeature
struct NoticesFeature: Reducer {
    struct State: Equatable {
        var notices: [Notice] = []
        var isLoading: Bool = false
        var errorMessage: String? = nil
    }

    enum Action: Equatable {
        case onAppear
        case noticesLoaded([Notice])
        case noticesFailed(String)
        
        case deleteNotice(String)
        case deleteNoticeSuccess(String)
        case deleteNoticeFailure(String)
    }
    
    @Dependency(\.noticesClient) var noticesClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let result = try await noticesClient.loadNotices()
                        await send(.noticesLoaded(result))
                    } catch {
                        await send(.noticesFailed("공지 불러오기에 실패했어요."))
                    }
                }

            case let .noticesLoaded(notices):
                state.notices = notices
                state.isLoading = false
                return .none

            case let .noticesFailed(message):
                state.errorMessage = message
                state.isLoading = false
                return .none

            case let .deleteNotice(id):
                state.isLoading = true
                return .run { send in
                    do {
                        try await noticesClient.deleteNotice(id)
                        await send(.deleteNoticeSuccess(id))
                    } catch {
                        await send(.deleteNoticeFailure("삭제 실패"))
                    }
                }
                
            case let .deleteNoticeSuccess(id):
                state.notices.removeAll { $0.id == id }
                state.isLoading = false
                return .none
                
            case let .deleteNoticeFailure(message):
                state.errorMessage = message
                state.isLoading = false
                return .none
            }
        }
    }
}

