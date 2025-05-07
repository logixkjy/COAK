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
                                    .aspectRatio(contentMode: .fill) // 중앙을 기준으로 채움
                                    .frame(width: geometry.size.width, height: geometry.size.width) // 정사각형으로 크롭
                                    .clipped() // 넘치는 부분 자름
                                    .position(x: geometry.size.width / 2, y: geometry.size.width / 2) // 중앙 정렬
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
