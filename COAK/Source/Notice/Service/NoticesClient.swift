//
//  NoticesClient.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/9/25.
//

import Foundation
import ComposableArchitecture
import Firebase
import FirebaseFirestore

struct NoticesClient {
    var loadNotices: @Sendable () async throws -> [Notice]
    var deleteNotice: @Sendable (String) async throws -> Void
}

extension NoticesClient: DependencyKey {
    static var liveValue: NoticesClient {
        return Self(
            loadNotices: {
                let snapshot = try await Firestore.firestore()
                    .collection("notices")
                    .order(by: "createdAt", descending: true)
                    .getDocuments()
                return try snapshot.documents.compactMap { try $0.data(as: Notice.self) }
            },
            deleteNotice: { id in
                try await Firestore.firestore()
                    .collection("notices")
                    .document(id)
                    .delete()
            }
        )
    }
}

extension DependencyValues {
    var noticesClient: NoticesClient {
        get { self[NoticesClient.self] }
        set { self[NoticesClient.self] = newValue }
    }
}
