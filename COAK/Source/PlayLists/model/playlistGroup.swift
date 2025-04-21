//
//  playkistGroup.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/17/25.
//

import Foundation

struct PlaylistGroup: Identifiable, Codable, Equatable {
    var id: String { title }
    var title: String
    var playlists: [PlaylistItem]
    var order: Int
}
