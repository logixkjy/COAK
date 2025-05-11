//
//  Announcement.swift
//  COAK
//
//  Created by JooYoung Kim on 5/5/25.
//

import Foundation

struct Announcement: Identifiable, Codable, Equatable {
    var id: String
    var content: String
    var imageURLs: [String] = []
    var imageFileNames: [String] = [] // 삭제를 위해 추가
    var email: String
    var userId: String
    var createdAt: Date
}
