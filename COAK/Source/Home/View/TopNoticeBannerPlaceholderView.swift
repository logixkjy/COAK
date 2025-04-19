//
//  TopNoticeBannerPlaceholderView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import SwiftUI

struct TopNoticeBannerPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.yellow.opacity(0.2)
            Text("📢 공지사항 영역 (배너)")
                .font(.headline)
        }
    }
}
