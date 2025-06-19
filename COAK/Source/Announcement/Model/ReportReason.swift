//
//  ReportReason.swift
//  COAK
//
//  Created by JooYoung Kim on 6/18/25.
//

import Foundation

public enum ReportReason: String, CaseIterable, Identifiable, Codable, Equatable {
    case abuse = "abuse"
    case spam = "spam"
    case offTopic = "offTopic"
    case inappropriate = "inappropriate"

    public var id: String { self.rawValue }
    public var label: String {
        switch self {
        case .abuse: return NSLocalizedString("report_reason_abuse", comment: "") //"욕설 또는 비방"
        case .spam: return NSLocalizedString("report_reason_spam", comment: "") //"스팸 또는 광고"
        case .offTopic: return NSLocalizedString("report_reason_offTopic", comment: "") //"주제와 무관함"
        case .inappropriate: return NSLocalizedString("report_reason_inappropriate", comment: "") //"부적절한 콘텐츠"
        }
    }
    
    public static func parseTo(id: String) -> ReportReason {
        switch id {
        case "abuse": return .abuse
        case "spam": return .spam
        case "offTopic": return .offTopic
        case "inappropriate": return .inappropriate
        default: return .abuse
        }
    }
}
