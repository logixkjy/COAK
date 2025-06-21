//
//  Report.swift
//  COAK
//
//  Created by JooYoung Kim on 6/18/25.
//

import Foundation

struct Report: Codable, Equatable, Identifiable {
    var id: String
    var documentId: String        // 공지/영상 id
    let type: ReportType          // .comment or .reply
    let targetId: String          // 댓글 or 답글 ID
    let content: String          // 내용
    let parentCommentId: String?  // 대댓글일 경우
    let source: ReportSource      // .video or .notice
    let reason: String?           // 신고 사유 (선택)
    let reportedBy: String
    let reportedByEmail: String
    let timestamp: Date

    var completed: Bool           // 신고 처리 여부 (기본값 false)
}

public enum ReportType: String, Codable {
    case comment, reply
}

public enum ReportSource: String, Codable {
    case video, notice
}
