//
//  PlaylistItem.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import Foundation

struct PlaylistItem: Identifiable, Codable, Equatable {
    var id: String         // YouTube Playlist ID
    var title: String
    var description: String?
    var thumbnailURL: String?
    var order: Int
    var videoId: String
    var isPremiumRequired: Bool
}
