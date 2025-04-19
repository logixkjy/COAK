import SwiftUI
import ComposableArchitecture

struct LazyView<Content: View>: View {
    let build: () -> Content
    var body: some View { build() }
}

struct FavoritesView: View {
    let appStore: StoreOf<AppFeature>

    var body: some View {
        WithViewStore(appStore, observe: { $0 }) { appViewStore in
            NavigationStack {
                Group {
                    if appViewStore.favoriteVideos.isEmpty {
                        Text("즐겨찾기한 영상이 없습니다.")
                            .foregroundColor(.gray)
                    } else {
                        List {
                            ForEach(appViewStore.favoriteVideos, id: \.id) { video in
                                NavigationLink(
                                        destination: LazyView {
                                            VideoDetailView(video: video.toYoutubeVideoItem(), store: appStore)
                                        }
                                    ) {
                                        FavoriteVideoRow(video: video) {
                                            appViewStore.send(.removeFromFavorites(video.id))
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("즐겨찾기")
            }
        }
    }
}
