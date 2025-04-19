//
//  YouTubeVideo.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import Foundation

struct YouTubeVideo: Equatable, Identifiable {
    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let publishedAt: Date?
    let duration: String?
}
