//
//  VideoDurationResponse.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

struct VideoDurationResponse: Decodable {
    let items: [Item]
    struct Item: Decodable {
        let id: String
        let contentDetails: ContentDetails
        
        struct ContentDetails: Decodable {
            let duration: String // ISO 8601 duration string
        }
    }
}
