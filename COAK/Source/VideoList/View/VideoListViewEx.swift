//
//  VideoRowView.swift.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import SwiftUI

extension VideoListView {
    struct VideoRowView: View {
        let video: YouTubeVideo
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    // 썸네일 이미지
                    AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 160, height: 90)
                    .clipped()
                    .cornerRadius(8)
                    
                    // ⏱ 재생 시간 오버레이
                    if let duration = video.duration {
                        Text(duration)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .padding(6)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(video.title)
                        .font(.headline)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    struct VideoGridCard: View {
        let video: YouTubeVideo
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    let url = video.thumbnailURL
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(6)
                    } placeholder: {
                        ProgressView()
                            .frame(height: 100)
                    }
                    
                    // ⏱ 재생 시간 오버레이
                    if let duration = video.duration {
                        Text(duration)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .padding(6)
                    }
                }
                
                Text(video.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.white)
            }
        }
    }
}
