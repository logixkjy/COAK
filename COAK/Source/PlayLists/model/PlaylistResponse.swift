//
//  PlaylistResponse.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/17/25.
//

// MARK: - Response Decoding Models

struct PlaylistResponse: Decodable {
    let items: [Item]
    struct Item: Decodable {
        let id: String
        let snippet: Snippet
    }
    struct Snippet: Decodable {
        let title: String
        let description: String
        let thumbnails: ThumbnailGroup
    }
    struct ThumbnailGroup: Decodable {
        let medium: Thumbnail?
    }
    struct Thumbnail: Decodable {
        let url: String
    }
}
