//
//  PlaylistVideoResponse.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/17/25.
//

struct PlaylistVideoResponse: Decodable {
    let items: [Item]
    let nextPageToken: String?
    struct Item: Decodable {
        let snippet: Snippet
        
        struct Snippet: Decodable {
            let title: String
            let description: String
            let publishedAt: String
            let thumbnails: Thumbnails
            let resourceId: ResourceId?
            
            struct Thumbnails: Decodable {
                let medium: Thumbnail?
                
                struct Thumbnail: Decodable {
                    let url: String
                }
            }
            
            struct ResourceId: Decodable {
                let videoId: String
            }
        }
    }
}
