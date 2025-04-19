//
//  PlaylistClient.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import FirebaseStorage
import Foundation

struct PlaylistClient {
    var loadPlaylists: @Sendable () async throws -> [PlaylistGroup]
}

extension PlaylistClient: DependencyKey {
    static let liveValue: PlaylistClient = .init(
        loadPlaylists: {
            let ref = Storage.storage().reference().child("playlist/playlist.json")
            let data = try await ref.data(maxSize: 5 * 1024 * 1024)
            struct Wrapper: Decodable { let groups: [PlaylistGroup] }
            let decoded = try JSONDecoder().decode(Wrapper.self, from: data)
            return decoded.groups
        }
    )
}

extension DependencyValues {
    var playlistClient: PlaylistClient {
        get { self[PlaylistClient.self] }
        set { self[PlaylistClient.self] = newValue }
    }
}
