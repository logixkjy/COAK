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
    var fetchAllReports: @Sendable () async throws -> [Report]
    var submit: @Sendable (Report) async throws -> Void
    var markReportCompleted: @Sendable (String) async throws -> Bool
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
        fetchAllReports: {
            let snapshot = try await Firestore.firestore()
                .collection("reports")
                .whereField("completed", isEqualTo: false)
                .order(by: "timestamp", descending: true)
                .getDocuments()

            return snapshot.documents.compactMap { doc in
                try? doc.data(as: Report.self)
            }
        },
        
        submit: { report in
            let ref = Firestore.firestore().collection("reports").document()
            var newReport = report
            newReport.id = ref.documentID
            try ref.setData(from: newReport)
        },
        
        markReportCompleted: { reportId in
            let ref = Firestore.firestore().collection("reports").document(reportId)
            try await ref.updateData(["completed": true])
            
            return true
        }
    )
}
