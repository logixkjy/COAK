//
//  YouTubeClient.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/17/25.
//

import ComposableArchitecture
import Foundation

struct YouTubeClient {
    var fetchPlaylistVideos: @Sendable (_ playlistId: String) async throws -> [YouTubeVideo]
    var fetchVideoDurations: @Sendable (_ videoIds: [String]) async throws -> [String: String]
    var fetchPlaylistMetadata: @Sendable (_ ids: [String]) async throws -> [String: YouTubePlaylistMeta]
}

extension YouTubeClient: DependencyKey {
    static var liveValue: YouTubeClient {
        return Self(
            fetchPlaylistVideos: { playlistId in
                var apiKey: String {
                    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "youtubeApiKey") as? String else {
                        fatalError("apiKey 환경변수가 등록되어 있지 않음.")
                    }
                    return apiKey
                }
                var nextPageToken: String? = nil
                var allVideos: [YouTubeVideo] = []
                repeat {
                    var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/playlistItems")!
                    components.queryItems = [
                        .init(name: "part", value: "snippet"),
                        .init(name: "playlistId", value: playlistId),
                        .init(name: "maxResults", value: "50"),
                        .init(name: "key", value: apiKey)
                    ]
                    if let token = nextPageToken {
                        components.queryItems?.append(.init(name: "pageToken", value: token))
                    }
                    
                    let (data, _) = try await URLSession.shared.data(from: components.url!)
                    let decoded = try JSONDecoder().decode(PlaylistVideoResponse.self, from: data)
                    
                    let items = decoded.items.compactMap { item -> YouTubeVideo? in
                        guard let videoId = item.snippet.resourceId?.videoId else { return nil }
                        return YouTubeVideo(
                            id: videoId,
                            title: item.snippet.title,
                            description: item.snippet.description,
                            thumbnailURL: item.snippet.thumbnails.medium?.url ?? "",
                            publishedAt: ISO8601DateFormatter().date(from: item.snippet.publishedAt),
                            duration: nil
                        )
                    }
                    
                    allVideos.append(contentsOf: items)
                    nextPageToken = decoded.nextPageToken
                } while nextPageToken != nil
                
                return allVideos
            },
            
            fetchVideoDurations: { ids in
                guard !ids.isEmpty else { return [:] }
                var apiKey: String {
                    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "youtubeApiKey") as? String else {
                        fatalError("apiKey 환경변수가 등록되어 있지 않음.")
                    }
                    return apiKey
                }
                let url = URL(string: "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(ids.joined(separator: ","))&key=\(apiKey)")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(VideoDurationResponse.self, from: data)
                
                return decoded.items.reduce(into: [String: String]()) { dict, item in
                    dict[item.id] = formatYouTubeDuration(item.contentDetails.duration)
                }
            },
            
            fetchPlaylistMetadata: { ids in
                guard !ids.isEmpty else { return [:] }
                var apiKey: String {
                    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "youtubeApiKey") as? String else {
                        fatalError("apiKey 환경변수가 등록되어 있지 않음.")
                    }
                    return apiKey
                }
                
                let joinedIds = ids.joined(separator: ",")
                let url = URL(string: "https://www.googleapis.com/youtube/v3/playlists?part=snippet&id=\(joinedIds)&key=\(apiKey)")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoded = try JSONDecoder().decode(PlaylistResponse.self, from: data)
                
                return decoded.items.reduce(into: [:]) { dict, item in
                    let thumb = item.snippet.thumbnails.medium?.url ?? ""
                    dict[item.id] = YouTubePlaylistMeta(
                        id: item.id,
                        title: item.snippet.title,
                        description: item.snippet.description,
                        thumbnailURL: thumb
                    )
                }
            }
        )
    }
}

extension DependencyValues {
    var youTubeClient: YouTubeClient {
        get { self[YouTubeClient.self] }
        set { self[YouTubeClient.self] = newValue }
    }
}


