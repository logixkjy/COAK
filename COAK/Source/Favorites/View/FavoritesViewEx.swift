//
//  FavoritesViewEx.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/9/25.
//

import SwiftUI

extension FavoritesView {
    struct FavoriteVideoRow: View {
        let video: FavoriteVideo
        let onDelete: () -> Void

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                if let url = video.thumbnailURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 60)
                            .clipped()
                            .cornerRadius(6)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 100, height: 60)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(video.description)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
            .padding(.vertical, 4)
        }
    }
}
