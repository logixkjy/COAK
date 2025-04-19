//
//  Notice.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/9/25.
//

import Foundation
import FirebaseFirestore

struct Notice: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var title: String
    var content: String
    var imageURL: String? // 이미지 추가
    var createdAt: Date

    init(id: String? = nil, title: String, content: String, imageURL: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.imageURL = imageURL
        self.createdAt = createdAt
    }
}
