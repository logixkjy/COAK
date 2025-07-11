import SwiftUI
import ComposableArchitecture

struct LazyView<Content: View>: View {
    let build: () -> Content
    var body: some View { build() }
}

struct FavoritesView: View {
    let appStore: StoreOf<AppFeature>
    
//    @State private var isPresented = false
    @State private var selectedVideoId: StringID?
//    @State private var selectedYouTubeVideoItem: FavoriteVideo? = nil
    
    var body: some View {
        WithViewStore(appStore, observe: { $0 }) { appViewStore in
            NavigationStack {
                ZStack {
                    Color.black01.ignoresSafeArea()
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if appViewStore.favoriteVideos.isEmpty {
                            Text("favorites_list_empty")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            List(appViewStore.favoriteVideos, id: \ .id) { video in
                                FavoriteVideoRow(video: video)
                                    .onTapGesture {
                                        selectedVideoId = StringID(id: video.id)
                                    }
                                    .onLongPressGesture(perform: {
                                        appViewStore.send(.removeFromFavorites(video.id))
                                    })
                            }
                            .listStyle(.plain)
                        }
                    }
                }
                .navigationTitle("main_favorites")
//                .onChange(of: selectedYouTubeVideoItem) { newValue in
//                    if let _ = newValue {
//                        isPresented.toggle()
//                    }
//                }
                .sheet(item: $selectedVideoId) { id in
                    if let selected = appViewStore.favoriteVideos.first(where: { $0.id == id.id }) {
                        let commentStore = Store(
                            initialState: VideoCommentFeature.State(
                                videoId: selected.id,
                                userId: appStore.userProfile?.uid ?? "",
                                email: appStore.userProfile?.email ?? ""
                            ),
                            reducer: {
                                VideoCommentFeature()
                            }
                        )
                        
                        let commentReportStore = Store(
                            initialState: CommentReportFeature.State(),
                            reducer: {
                                CommentReportFeature()
                            }
                        )
                        
                        VideoDetailView(
                            video: selected.toYoutubeVideoItem(),
                            store: appStore,
                            commentStore: commentStore,
                            commentReportStore: commentReportStore
                        )
                        .presentationDetents([.fraction(1.0)]) // 전체 화면에 가까움
                        .presentationDragIndicator(.visible) // 위쪽 드래그바 표시 (숨기려면 .hidden)
                    }
                }
            }
        }
    }
}
