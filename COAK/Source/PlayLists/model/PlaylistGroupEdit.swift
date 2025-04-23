//
//  PlaylistGroupEdit.swift
//  COAK
//
//  Created by JooYoung Kim on 4/21/25.
//

import Foundation

struct PlaylistContainer: Codable {
    var groups: [PlaylistGroupEdit]
}

struct PlaylistGroupEdit: Identifiable, Codable, Equatable, Hashable {
    var title: String
    var playlists: [PlaylistItemEdit]
    var order: Int
    
    var id: String { title } // 이건 저장 X
    
    // CodingKeys에서 id 제외
    enum CodingKeys: String, CodingKey {
        case title, playlists, order
    }
}
