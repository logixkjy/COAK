//
//  NoticeDetailView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import ComposableArchitecture

struct NoticeDetailView: View {
    @State private var notice: Notice
    let store: StoreOf<NoticesFeature>
    let appStore: StoreOf<AppFeature>
    @State private var isShowingEditor = false

    init(notice: Notice,
         store: StoreOf<NoticesFeature>,
         appStore: StoreOf<AppFeature>) {
        self.notice = notice
        self.store = store
        self.appStore = appStore
    }
    
    var body: some View {
        WithViewStore(appStore, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(notice.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(notice.createdAt.formatted())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Divider()
                    
                    Text(notice.content)
                        .font(.body)
                    
                    if let urlString = notice.imageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(10)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("공지 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewStore.isAdmin {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("수정") {
                            isShowingEditor = true
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingEditor) {
                NoticeEditorView(notice: $notice, store: store)
            }
        }
    }
}
