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
    }

    enum Action: Equatable {
        case loadAnnouncements
        case announcementsLoaded([Announcement])

        case create(Announcement)
        case update(Announcement)
        case delete(String)
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
                return .run { _ in
                    try await announcementClient.delete(id)
                }
            }
        }
    }
}
