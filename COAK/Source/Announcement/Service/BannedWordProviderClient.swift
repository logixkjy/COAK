//
//  BannedWordProviderClient.swift
//  COAK
//
//  Created by JooYoung Kim on 6/19/25.
//

import Foundation
import ComposableArchitecture
import FirebaseStorage

struct BannedWordProviderClient {
    var load: @Sendable () async throws -> [String]
}

extension DependencyValues {
    var bannedWordProvider: BannedWordProviderClient {
        get { self[BannedWordProviderClientKey.self] }
        set { self[BannedWordProviderClientKey.self] = newValue }
    }
    
    private enum BannedWordProviderClientKey: DependencyKey {
        static let liveValue = BannedWordProviderClient.live
    }
}

extension BannedWordProviderClient {
    static let live = BannedWordProviderClient(
        load: {
            let ref = Storage.storage().reference().child("filter/banned_words.json")
            let data = try await ref.data(maxSize: 1 * 1024 * 1024)
            struct Wrapper: Codable { let words: [String] }
            return try JSONDecoder().decode(Wrapper.self, from: data).words
        }
    )
}
