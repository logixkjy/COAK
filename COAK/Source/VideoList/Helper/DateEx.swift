//
//  DateEx.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import Foundation

extension Date {
    func relativeTimeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
