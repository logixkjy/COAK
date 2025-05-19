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
                VStack(alignment: .leading, spacing: 0) {
                    if appViewStore.favoriteVideos.isEmpty {
                        Text("즐겨찾기한 영상이 없습니다.")
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
                .navigationTitle("즐겨찾기")
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
                        
                        VideoDetailView(
                            video: selected.toYoutubeVideoItem(),
                            store: appStore,
                            commentStore: commentStore
                        )
                        .presentationDetents([.fraction(1.0)]) // 전체 화면에 가까움
                        .presentationDragIndicator(.visible) // 위쪽 드래그바 표시 (숨기려면 .hidden)
                    }
                }
            }
        }
    }
}
