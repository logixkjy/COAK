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
    var loadFavorites: (String) async throws -> [FavoriteVideo]
    var removeFavorite: (String, String) async throws -> Void
    var isFavorite: (String) async throws -> Bool
}

extension FavoritesClient: DependencyKey {
    static let liveValue = FavoritesClient(
        loadFavorites: { userId in
            let snapshot = try await Firestore.firestore()
                .collection("favorites")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            return snapshot.documents.compactMap {
                try? $0.data(as: FavoriteVideo.self)
            }
        },
        removeFavorite: { videoId, userId in
            try await Firestore.firestore()
                .collection("favorites")
                .document("\(userId)_\(videoId)")
                .delete()
        },
        isFavorite: { videoId in
            guard let uid = Auth.auth().currentUser?.uid else { return false }
            let doc = try await Firestore.firestore()
                .collection("users").document(uid)
                .collection("favorites").document(videoId).getDocument()
            return doc.exists
        }
    )
}

extension DependencyValues {
    var favoritesClient: FavoritesClient {
        get { self[FavoritesClient.self] }
        set { self[FavoritesClient.self] = newValue }
    }
}
