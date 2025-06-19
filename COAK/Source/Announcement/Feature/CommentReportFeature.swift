//
//  CommentReportFeature.swift
//  COAK
//
//  Created by JooYoung Kim on 6/18/25.
//

import Foundation
import ComposableArchitecture
import FirebaseAuth

@Reducer
struct CommentReportFeature {
    struct State: Equatable {
        var isReporting: Bool = false
        var isShowingReasonDialog = false
        var selectedReason: ReportReason?
        var pendingTargetId: String?
        var pendingContent: String?
        var pendingType: ReportType?
        var pendingParentId: String?
        var pendingSource: ReportSource?
        var alertMessage: String? = nil
    }
    
    enum Action: Equatable {
        case reportButtonTapped(String, String, ReportType, String?, ReportSource)
        case showReasonDialog
        case selectReason(ReportReason)
        case confirmReport
        case reportResponseSuccess
        case reportResponseFailure
        case dismissAlert
        case dismissReasonDialog
    }
    
    @Dependency(\.reportClient) var reportClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .reportButtonTapped(targetId, content, type, parentId, source):
                state.pendingTargetId = targetId
                state.pendingContent = content
                state.pendingType = type
                state.pendingParentId = parentId
                state.pendingSource = source
                state.isShowingReasonDialog = true
                return .none
                
            case .selectReason(let reason):
                state.selectedReason = reason
                return .send(.confirmReport)
                
            case .confirmReport:
                guard let targetId = state.pendingTargetId,
                      let content = state.pendingContent,
                      let type = state.pendingType,
                      let source = state.pendingSource,
                      let reason = state.selectedReason
                else { return .none }

                let report = Report(
                    id: "",
                    type: type,
                    targetId: targetId,
                    content: content,
                    parentCommentId: state.pendingParentId,
                    source: source,
                    reason: reason.id,
                    reportedBy: Auth.auth().currentUser?.uid ?? "unknown",
                    timestamp: Date.now,
                    completed: false
                )

                state.isShowingReasonDialog = false

                return .run { send in
                    do {
                        try await reportClient.submit(report)
                        await send(.reportResponseSuccess)
                    } catch {
                        await send(.reportResponseFailure)
                    }
                }
                
            case .reportResponseSuccess:
                state.alertMessage = NSLocalizedString("report_response_success", comment: "") //"신고가 접수되었습니다. 감사합니다."
                return .none

            case .reportResponseFailure:
                state.alertMessage = NSLocalizedString("report_response_failure", comment: "") //"신고 처리 중 오류가 발생했습니다."
                return .none

            case .dismissAlert:
                state.alertMessage = ""
                return .none
                
            case .dismissReasonDialog:
                state.isShowingReasonDialog = false
                return .none
                
            default:
                return .none
                
            }
        }
    }
}
  
