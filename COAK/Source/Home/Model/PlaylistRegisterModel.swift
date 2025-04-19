//
//  PlaylistRegisterModel.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import Foundation

struct PlaylistRegisterModel: Codable {
    let youtubePlaylistId: String
    let customTitle: String
    let createdAt: Date
}
