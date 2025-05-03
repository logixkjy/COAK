//
//  FavoritesClient.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import FirebaseFirestore
import FirebaseAuth

struct FavoriteVideo: Identifiable, Codable, Equatable {
    var id: String       // videoId
    var title: String
    var description: String
    var thumbnailURL: URL?
    var userId: String
    var createdAt: Date
    
    func toYoutubeVideoItem() -> YouTubeVideo {
        YouTubeVideo(
            id: id,
            title: title,
            description: description,
            thumbnailURL: thumbnailURL?.absoluteString ?? "",
            publishedAt: Date(),
            duration: ""
        )
    }
}

struct FavoritesClient {
    var fetchFavorites: @Sendable (_ userId: String) async throws -> [FavoriteVideo]
    var addFavorite: @Sendable (_ userId: String, _ video: FavoriteVideo) async throws -> Void
    var removeFavorite: @Sendable (_ userId: String, _ videoId: String) async throws -> Void
}

extension FavoritesClient: DependencyKey {
    static let liveValue = FavoritesClient(
        fetchFavorites: { userId in
            let snapshot = try await Firestore.firestore()
                .collection("favorites")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                try? document.data(as: FavoriteVideo.self)
            }
        },
        
        addFavorite: { userId, video in
            try Firestore.firestore()
                .collection("favorites")
                .document("\(userId)_\(video.id)")
                .setData(from: video)
        },
        
        removeFavorite: { userId, videoId in
            try await Firestore.firestore()
                .collection("favorites")
                .document("\(userId)_\(videoId)")
                .delete()
        }
    )
}

extension DependencyValues {
    var favoritesClient: FavoritesClient {
        get { self[FavoritesClient.self] }
        set { self[FavoritesClient.self] = newValue }
    }
}
