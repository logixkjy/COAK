//
//  PlaylistGroupEdit.swift
//  COAK
//
//  Created by JooYoung Kim on 4/21/25.
//

import Foundation

struct PlaylistGroupEdit: Identifiable, Codable, Equatable {
    var id: String { title }
    var title: String
    var playlists: [PlaylistItemEdit]
    var order: Int
}
