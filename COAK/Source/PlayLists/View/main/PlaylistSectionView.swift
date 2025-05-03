//
//  PlaylistSectionView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import SwiftUI
import ComposableArchitecture

struct PlaylistSectionView: View {
    let group: PlaylistGroup
    let playlists: [PlaylistItem]
    let store: StoreOf<PlaylistFeature>
    let appStore: StoreOf<AppFeature>
    
    @Binding private var isPresented: Bool
    @Binding private var isPresentedVideoList: Bool
    @Binding private var isGridLayout: Bool
    
    init(
        group: PlaylistGroup,
        playlists: [PlaylistItem],
        store: StoreOf<PlaylistFeature>,
        appStore: StoreOf<AppFeature>,
        isPresented: Binding<Bool>,
        isPresentedVideoList: Binding<Bool>,
        isGridLayout: Binding<Bool>
    ) {
        self.group = group
        self.playlists = playlists
        self.store = store
        self.appStore = appStore
        self._isPresented = isPresented
        self._isPresentedVideoList = isPresentedVideoList
        self._isGridLayout = isGridLayout
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(group.title)
                        .font(.title.bold())
                        .lineLimit(1) // 섹션 타이틀 한 줄로 제한
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    Button(action: {
                        viewStore.send(.selectGroup(group.id))
                        self.isPresented.toggle()
                    }) {
                        Text("모두 보기")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(playlists.sorted(by: { $0.order < $1.order })) { item in
//                            NavigationLink(
//                                destination: VideoListView(
//                                    store: Store(
//                                        initialState: VideoListFeature.State(playlistItem: item),
//                                        reducer: { VideoListFeature() }
//                                    ),
//                                    appStore: appStore,
//                                    isGridLayout: $isGridLayout
//                                )
//                            ) {
                                PlaylistCardView(item: item)
                                    .onTapGesture {
                                        viewStore.send(.selectPlaylist(item))
                                        self.isPresentedVideoList.toggle()
                                    }
//                            }
//                            .buttonStyle(.plain) // 카드 스타일 유지
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}
