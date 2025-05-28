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
    
    @Binding private var isShowToast: Bool
    @Binding private var toastMessage: String
    
    init(
        group: PlaylistGroup,
        playlists: [PlaylistItem],
        store: StoreOf<PlaylistFeature>,
        appStore: StoreOf<AppFeature>,
        isPresented: Binding<Bool>,
        isPresentedVideoList: Binding<Bool>,
        isGridLayout: Binding<Bool>,
        isShowToast: Binding<Bool>,
        toastMessage: Binding<String>
    ) {
        self.group = group
        self.playlists = playlists
        self.store = store
        self.appStore = appStore
        self._isPresented = isPresented
        self._isPresentedVideoList = isPresentedVideoList
        self._isGridLayout = isGridLayout
        self._isShowToast = isShowToast
        self._toastMessage = toastMessage
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            WithViewStore(appStore, observe: { $0 }) { appViewStore in
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
                                PlaylistCardView(item: item, isPremium: (appViewStore.userProfile?.isPremium ?? false), isAdmin: appViewStore.userProfile?.isAdmin ?? false)
                                    .onTapGesture {
                                        if item.isPremiumRequired && (appViewStore.userProfile?.isPremium ?? false) == false && (appViewStore.userProfile?.isAdmin ?? false) == false {
                                            toastMessage = NSLocalizedString("common_paid_toast", comment: "") + "/n facebook.com/sonjinbagsh\n 010-2145-4221"
                                            isShowToast = true
                                        } else {
                                            viewStore.send(.selectPlaylist(item))
                                            self.isPresentedVideoList.toggle()
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
//                .alert("해당 컨텐츠는 유료 켄텐츠입니다. \n맴버쉽 가입 후 이용이 가능합니다.", isPresented: $isShowPopup) {
//                    Button("확인", role: .cancel) {}
//                }
            }
        }
    }
}
