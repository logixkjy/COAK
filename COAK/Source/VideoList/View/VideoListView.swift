//
//  VideoListView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import ComposableArchitecture

struct StringID: Identifiable, Equatable {
    var id: String
}

struct VideoListView: View {
    @StateObject private var store: StoreOf<VideoListFeature>
    let appStore: StoreOf<AppFeature> // 즐겨찾기 등 연동 가능
    
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var isPresented = false
    var isMain = false
    @Binding private var isGridLayout: Bool
    @State private var selectedVideoId: StringID?
    
    let columns = [
        GridItem(.flexible()), GridItem(.flexible())
    ]
    
    init(store: StoreOf<VideoListFeature>, appStore: StoreOf<AppFeature>, isGridLayout: Binding<Bool>, isMain: Bool = false) {
        _store = StateObject(wrappedValue: store)
        self.appStore = appStore
        self._isGridLayout = isGridLayout
        self.isMain = isMain
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                VStack(spacing: 8) {
                    if viewStore.isLoading {
                        ProgressView("재생목록 불러오는 중...")
                    } else if let error = viewStore.errorMessage {
                        Text(error).foregroundColor(.red)
                    } else {
                        if isGridLayout {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(viewStore.videos) { video in
                                        VideoGridCard(video: video)
                                            .onTapGesture {
                                                selectedVideoId = StringID(id: video.id)
                                            }
                                    }
                                }
                                .padding()
                                .transition(.opacity.combined(with: .scale))
                            }
                        } else {
                            List {
                                ForEach(viewStore.videos) { video in
                                    VideoRowView(video: video)
                                        .onTapGesture {
                                            selectedVideoId = StringID(id: video.id)
                                        }
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
                .navigationBarBackButtonHidden(true)
                .navigationTitle(viewStore.playlistItem?.title ?? "영상 목록")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .medium))
                                Text(isMain ? "홈" : "목록")
                                    .font(.system(size: 18))
                            }
                            .foregroundColor(.primary)
                            .padding(8)
                        }
                    }
                    
                    // 오른쪽: 레이아웃 전환 버튼
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            withAnimation(.easeInOut) {
                                isGridLayout.toggle()
                            }
                        }) {
                            Image(systemName: isGridLayout ? "list.bullet" : "square.grid.2x2")
                                .imageScale(.large)
                                .padding(8)
                        }
                        .accessibilityLabel("레이아웃 전환")
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
                .sheet(item: $selectedVideoId) { id in
                    if let selected = viewStore.videos.first(where: { $0.id == id.id }) {
                        let commentStore = Store(
                            initialState: VideoCommentFeature.State(
                                videoId: selected.id,
                                userId: appStore.userProfile?.uid ?? "",
                                email: appStore.userProfile?.email ?? "",
                                profileImageURL: appStore.userProfile?.profileImageURL ?? ""
                            ),
                            reducer: {
                                VideoCommentFeature()
                            }
                        )
                        
                        VideoDetailView(
                            video: selected,
                            store: appStore,
                            commentStore: commentStore
                        )
                            .presentationDetents([.fraction(1.0)])
                            .presentationDragIndicator(.visible) // 위쪽 드래그바 표시
                    } else {
                        Text("영상 정보를 불러올 수 없습니다.")
                    }
                }
            }
        }
    }
}
