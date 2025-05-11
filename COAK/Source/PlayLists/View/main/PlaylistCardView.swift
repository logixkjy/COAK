//
//  PlaylistCardView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import SwiftUI

struct PlaylistCardView: View {
    let item: PlaylistItem
    let isPremium: Bool
    let isAdmin: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                AsyncImage(url: URL(string: item.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(width: 260, height: 146)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 260, height: 146)
                        .cornerRadius(8)
                }

                // 프리미엄 여부에 따른 딤 처리와 자물쇠 아이콘
                if item.isPremiumRequired == true && isPremium == false && isAdmin == false {
                    Color.black.opacity(0.4) // 딤 처리
                        .cornerRadius(8)
                    
                    VStack {
                        Image(systemName: "lock.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
            }

            // 제목 표시
            Text(item.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 260, alignment: .leading) // 텍스트 너비 맞추기
        }
    }
}
