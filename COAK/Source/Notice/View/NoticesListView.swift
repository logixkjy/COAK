//
//  NoticesListView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/9/25.
//

import SwiftUI
import ComposableArchitecture

struct NoticesListView: View {
    let store: StoreOf<NoticesFeature>
    let appStore: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            WithViewStore(appStore, observe: { $0 }) { appViewStore in
                NavigationStack {
                    Group {
                        if viewStore.isLoading {
                            ProgressView("불러오는 중...")
                        } else if let error = viewStore.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                        } else {
                            List {
                                ForEach(viewStore.notices) { notice in
                                    NavigationLink(destination: NoticeDetailView(notice: notice, store: store, appStore: appStore)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(notice.title)
                                                .font(.headline)
                                            Text(notice.createdAt.formatted())
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .swipeActions {
                                        if appViewStore.isAdmin {
                                            Button(role: .destructive) {
                                                if let id = notice.id {
                                                    viewStore.send(.deleteNotice(id))
                                                }
                                            } label: {
                                                Label("삭제", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                    .navigationTitle("공지사항")
                    .onAppear {
                        viewStore.send(.onAppear)
                    }
                }
            }
        }
    }
}

// 날짜 포맷 확장
extension Date {
    func formatted(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
}

