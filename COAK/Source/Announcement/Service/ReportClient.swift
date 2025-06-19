//
//  ReportClient.swift
//  COAK
//
//  Created by JooYoung Kim on 6/18/25.
//

import Foundation
import ComposableArchitecture
import FirebaseFirestore

struct ReportClient {
    var submit: @Sendable (Report) async throws -> Void
}

extension DependencyValues {
    var reportClient: ReportClient {
        get { self[ReportClientKey.self] }
        set { self[ReportClientKey.self] = newValue }
    }

    private enum ReportClientKey: DependencyKey {
        static let liveValue = ReportClient.live
    }
}

extension ReportClient {
    static let live = ReportClient(
        submit: { report in
            let ref = Firestore.firestore().collection("reports").document()
            var newReport = report
            newReport.id = ref.documentID
            try ref.setData(from: newReport)
        }
    )
}
