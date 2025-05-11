//
//  AnnouncementFeature.swift
//  COAK
//
//  Created by JooYoung Kim on 5/5/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AnnouncementFeature {
    struct State: Equatable {
        var announcements: [Announcement] = []
        var errorMessage: String = ""
    }

    enum Action: Equatable {
        case loadAnnouncements
        case announcementsLoaded([Announcement])

        case create(Announcement)
        case update(Announcement)
        case delete(String)
        case deleteSuccess(String)
        case deleteFailure(String)
    }

    @Dependency(\.announcementClient) var announcementClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadAnnouncements:
                return .run { send in
                    let announcements = try await announcementClient.fetchAll()
                    await send(.announcementsLoaded(announcements))
                }

            case let .announcementsLoaded(announcements):
                state.announcements = announcements
                return .none

            case let .create(announcement):
                return .run { _ in
                    try await announcementClient.create(announcement)
                }

            case let .update(announcement):
                return .run { _ in
                    try await announcementClient.update(announcement)
                }

            case let .delete(id):
                return .run { send in
                    do {
                        let result = try await announcementClient.delete(id)
                        if result {
                            await send(.deleteSuccess(id))
                        } else {
                            await send(.deleteFailure("Failed to delete announcement."))
                        }
                    } catch {
                        await send(.deleteFailure(error.localizedDescription))
                    }
                }
                
            case let .deleteSuccess(id):
                // 삭제 성공 시 상태에서 제거
                state.announcements.removeAll { $0.id == id }
                return .none
                
            case let .deleteFailure(errorMessage):
                // 삭제 실패 시 에러 처리 (예: 알림 표시)
                state.errorMessage = errorMessage
                return .none
                
                
            }
        }
    }
}
