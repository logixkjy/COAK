//
//  AnnouncementClient.swift
//  COAK
//
//  Created by JooYoung Kim on 5/5/25.
//

import Foundation
import FirebaseFirestore
import ComposableArchitecture

struct AnnouncementClient {
    var fetchAll: @Sendable () async throws -> [Announcement]
    var create: @Sendable (_ announcement: Announcement) async throws -> Void
    var update: @Sendable (_ announcement: Announcement) async throws -> Void
    var delete: @Sendable (_ id: String) async throws -> Bool
}

extension AnnouncementClient: DependencyKey {
    static let liveValue: AnnouncementClient = .init(
        fetchAll: {
            let snapshot = try await Firestore.firestore()
                .collection("notices")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            return snapshot.documents.compactMap {
                try? $0.data(as: Announcement.self)
            }
        },
        create: { announcement in
            let ref = Firestore.firestore().collection("notices").document()
            var newAnnouncement = announcement
            newAnnouncement.id = ref.documentID
            try ref.setData(from: newAnnouncement)
        },
        update: { announcement in
            try Firestore.firestore()
                .collection("notices")
                .document(announcement.id)
                .setData(from: announcement)
        },
        delete: { id in
            try await Firestore.firestore()
                .collection("notices")
                .document(id)
                .delete()
            return true
        }
    )
}

extension DependencyValues {
    var announcementClient: AnnouncementClient {
        get { self[AnnouncementClient.self] }
        set { self[AnnouncementClient.self] = newValue }
    }
}
