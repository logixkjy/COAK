//
//  PlaylistItemEdit.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import Foundation

struct PlaylistItemEdit: Identifiable, Codable, Equatable, Hashable {
    var id: String         // YouTube Playlist ID
    var title: String
    var order: Int
    var videoId: String
    var isPremiumRequired: Bool
}
