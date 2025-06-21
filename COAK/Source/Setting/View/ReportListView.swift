//
//  ReportListView.swift
//  COAK
//
//  Created by JooYoung Kim on 6/20/25.
//

import SwiftUI
import ComposableArchitecture

struct ReportListView: View {
    let store: StoreOf<ReportAdminFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                ZStack {
                    Color.black01.ignoresSafeArea()
                    
                    List {
                        ForEach(viewStore.reports) { report in
                            VStack(alignment: .leading) {
                                Text("\(NSLocalizedString("setting_report_reported_by", comment: "")): \(report.reportedByEmail)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(NSLocalizedString("setting_report_reason", comment: "")): \(ReportReason.parseTo(id: report.reason ?? "").label) ( \(report.source.rawValue == "notice" ? NSLocalizedString("main_notice", comment: "") : NSLocalizedString("setting_report_type_video", comment: "")) / \(report.type.rawValue == "comment" ? NSLocalizedString("common_comment", comment: "") : NSLocalizedString("common_reply", comment: "")) )")
                                Text("\(NSLocalizedString("setting_report_content", comment: "")): \(report.content)")
                                Text("\(NSLocalizedString("setting_report_completed", comment: "")): \(report.completed ? "✅" : "❌")")
                                    .foregroundColor(report.completed ? .green : .red)
                                
                                Button("setting_report_hidden") {
                                    viewStore.send(.markReportAsCompleted(
                                        report.id,
                                        report.type,
                                        report.source,
                                        report.targetId,
                                        report.parentCommentId ?? "",
                                        report.documentId
                                    ))
                                }
                                .disabled(report.completed)
                                .foregroundColor(.blue)
                                .padding(.top, 6)
                            }
                            .padding(8)
                        }
                    }
                }
                .navigationTitle("setting_report_list")
            }
            .overlay {
                if viewStore.isLoading {
                    ProgressView()
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}
