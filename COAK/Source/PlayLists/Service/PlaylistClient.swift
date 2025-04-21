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
    var loadPlaylistsEdit: @Sendable () async throws -> [PlaylistGroupEdit]
    var savePlaylists: @Sendable ([PlaylistGroup]) async throws -> Void
}

extension PlaylistClient: DependencyKey {
    static let liveValue: PlaylistClient = .init(
        loadPlaylists: {
            let ref = Storage.storage().reference().child("playlist/playlist.json")
            let data = try await ref.data(maxSize: 5 * 1024 * 1024)
            struct Wrapper: Decodable { let groups: [PlaylistGroup] }
            let decoded = try JSONDecoder().decode(Wrapper.self, from: data)
            return decoded.groups
        },
        loadPlaylistsEdit: {
            let ref = Storage.storage().reference().child("playlist/playlist.json")
            let data = try await ref.data(maxSize: 5 * 1024 * 1024)
            struct Wrapper: Decodable { let groups: [PlaylistGroupEdit] }
            let decoded = try JSONDecoder().decode(Wrapper.self, from: data)
            return decoded.groups
        },
        savePlaylists: { groups in
            let ref = Storage.storage().reference(withPath: "playlist/playlist.json")
            let encoder = JSONEncoder()
            let data = try encoder.encode(groups)
            _ = try await ref.putDataAsync(data, metadata: nil)
        }
    )
}

extension DependencyValues {
    var playlistClient: PlaylistClient {
        get { self[PlaylistClient.self] }
        set { self[PlaylistClient.self] = newValue }
    }
}
