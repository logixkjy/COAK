//
//  AnnouncementListViewEx.swift
//  COAK
//
//  Created by JooYoung Kim on 5/5/25.
//

import SwiftUI
import Foundation
import ComposableArchitecture

extension AnnouncementListView {
    struct AnnouncementCardView: View {
        let announcement: Announcement

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    if let url = URL(string: announcement.authorProfileImageURL ?? "") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().frame(width: 36, height: 36).clipShape(Circle())
                            default:
                                Circle().frame(width: 36, height: 36).foregroundColor(.gray)
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.white)
                    }
                    
                    Text(announcement.authorName).bold()
                        .foregroundColor(.white)
                    
                    Text(announcement.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Text(announcement.content)
                    .lineLimit(3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                if let firstImage = announcement.imageURLs.first,
                   let url = URL(string: firstImage) {
                    GeometryReader { geometry in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                                    .clipped()
                            default:
                                Color.gray.frame(height: geometry.size.width)
                            }
                        }
                    }
                    .frame(height: UIScreen.main.bounds.width)
                }

                Divider()
                    .padding(.top, 8)
            }
            .padding(.vertical, 12)
        }
    }
}
