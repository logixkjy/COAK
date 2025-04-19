//
//  PlaylistItem.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import Foundation

struct PlaylistItem: Identifiable, Codable, Equatable {
    let id: String         // YouTube Playlist ID
    let title: String
    let description: String?
    let thumbnailURL: String?
    let order: Int
    let isPremiumRequired: String
}
