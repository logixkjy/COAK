//
//  ReportAdminFeature.swift
//  COAK
//
//  Created by JooYoung Kim on 6/20/25.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ReportAdminFeature {
    struct State: Equatable {
        var reports: [Report] = []
        var isLoading: Bool = false
        var errorMessage: String?
    }
    
    enum Action: Equatable {
        case onAppear
        case fetchReports
        case fetchReportsResponseSuccess([Report])
        case fetchReportsResponseFailure(CustomError)
        
        case markReportAsCompleted(String, ReportType, ReportSource, String, String, String)
        case markReportCompletedUpdate(String)
        case markReportCompletedResponseSuccess
        case markReportCompletedResponseFailure(CustomError)
    }
    
    @Dependency(\.reportClient) var reportClient
    @Dependency(\.commentClient) var commentClient
    @Dependency(\.announcementCommentClient) var announcementCommentClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.fetchReports)
                
            case .fetchReports:
                state.isLoading = true
                return .run { send in
                    do {
                        let reports = try await reportClient.fetchAllReports()
                        await send(.fetchReportsResponseSuccess(reports))
                    } catch {
                        await send(.fetchReportsResponseFailure(.firebaseError(error.localizedDescription)))
                    }
                }
                
            case .fetchReportsResponseSuccess(let reports):
                state.reports = reports
                state.isLoading = false
                return .none
                
            case .fetchReportsResponseFailure(let error):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .markReportAsCompleted(let reportId, let type, let source, let targetId, let parentCommentId, let documentId):
                return .run { send in
                    do {
                        // 1. 신고 상태 업데이트
                        let result = try await reportClient.markReportCompleted(reportId)
                        if result {
                            await send(.markReportCompletedUpdate(reportId))
                        }
                        
                        // 2. 댓글/답글 숨김 처리
                        switch type {
                        case .comment:
                            switch source {
                            case .notice:
                                try await announcementCommentClient.setCommentHidden(documentId, targetId, true)
                                
                            case .video:
                                try await commentClient.setCommentHidden(documentId, targetId, true)
                            }
                            
                        case .reply:
                            switch source {
                            case .notice:
                                try await announcementCommentClient.setReplyHidden(documentId, parentCommentId, targetId, true)
                                
                            case .video:
                                try await commentClient.setReplyHidden(documentId, parentCommentId, targetId, true)
                            }
                        }
                        
                        await send(.markReportCompletedResponseSuccess)
                    } catch {
                        await send(.markReportCompletedResponseFailure(.firebaseError(error.localizedDescription)))
                    }
                }
                
            case .markReportCompletedUpdate(let reportId):
                for var report in state.reports {
                    if report.id == reportId {
                        let index = state.reports.firstIndex(of: report)!
                        report.completed = true
                        state.reports[index] = report
                        return .none
                    }
                }
                return .none
                
                
            default:
                return .none
                
            }
        }
    }
}

