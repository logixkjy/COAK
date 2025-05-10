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
    let appStore: StoreOf<AppFeature>
    @State var selectedAnnouncement: Announcement? = nil
    @State var isEdited: Bool = false

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
                .fullScreenCover(item: $selectedAnnouncement,
                                 onDismiss: {
                    // 공지 내용이 수정 되었다면 다시 로드
                    if isEdited {
                        isEdited.toggle()
                        viewStore.send(.loadAnnouncements)
                    }
                }, content: { announcement in
                    let commentStore = Store(
                        initialState: AnnouncementCommentFeature.State(
                            announcemetId: announcement.id,
                            userId: appStore.userProfile?.uid ?? "",
                            email: appStore.userProfile?.email ?? "",
                            profileImageURL: appStore.userProfile?.profileImageURL ?? ""
                        ),
                        reducer: {
                            AnnouncementCommentFeature()
                        }
                    )
                    
                    AnnouncementDetailView(store: self.store, appStore: self.appStore, commentStore: commentStore, announcement: announcement, isEdited: $isEdited, isAdmin: self.appStore.isAdmin)
                })
            }
        }
    }
}
