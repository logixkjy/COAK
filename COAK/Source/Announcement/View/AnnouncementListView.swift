//
//  AnnouncementListView.swift
//  COAK
//
//  Created by JooYoung Kim on 5/5/25.
//

import SwiftUI
import Foundation
import ComposableArchitecture

struct AnnouncementListView: View {
    let store: StoreOf<AnnouncementFeature>
    @State var selectedAnnouncement: Announcement? = nil

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack(alignment: .leading, spacing: 0) {
                    if viewStore.announcements.isEmpty {
                        Text("등록된 공지사항이 없습니다.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewStore.announcements) { item in
                                    AnnouncementCardView(announcement: item)
                                        .onTapGesture {
                                            selectedAnnouncement = item
                                        }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("공지사항")
                .onAppear {
                    viewStore.send(.loadAnnouncements)
                }
                .fullScreenCover(item: $selectedAnnouncement) { announcement in
                    AnnouncementDetailView(announcement: announcement, isAdmin: true)
                }
            }
        }
    }
}
