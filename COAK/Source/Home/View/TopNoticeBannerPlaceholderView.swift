//
//  TopNoticeBannerPlaceholderView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/18/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import ComposableArchitecture

struct TopNoticeBannerPlaceholderView: View {
    let store: StoreOf<AnnouncementFeature>
    let appStore: StoreOf<AppFeature>
    @State private var latestNotice: Announcement?
    @State var selectedAnnouncement: Announcement? = nil
    @State private var image: UIImage? = nil
    @State private var isLoading = true
    @State var isEdited: Bool = false

    var body: some View {
        ZStack {
            if let image = image {
                // 이미지가 있을 경우: 중앙 정렬 + 크롭 + 블러 + 반투명 효과
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .blur(radius: 2)
                    .opacity(0.8)
            } else {
                // 이미지가 없을 경우: 그라디언트 배경과 공지 아이콘
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.5), Color.red.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blur(radius: 2)
                .opacity(0.8)
            }

            VStack {
                if let notice = latestNotice {
                    Text(notice.content)
                        .lineLimit(3)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .padding(16) // 텍스트 패딩을 이미지와 동일하게 설정
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // 이미지와 동일 크기
                        .background(Color.black.opacity(0.3)) // 반투명 배경
                        .cornerRadius(10)
                        .foregroundColor(.white)
                } else if isLoading {
                    Text("Loading...")
                        .font(.headline)
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // 이미지와 동일 크기
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                } else {
                    Text("notice_list_empty")
                        .font(.headline)
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // 이미지와 동일 크기
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 120) // 이미지와 동일 높이 설정
            .cornerRadius(10)
//            .padding(.horizontal, 8)
        }
        .frame(height: 120)
        .cornerRadius(10)
        .onAppear {
            fetchLatestNotice()
        }
        .onTapGesture {
            selectedAnnouncement = latestNotice
        }
        .fullScreenCover(item: $selectedAnnouncement) { announcement in
            let commentStore = Store(
                initialState: AnnouncementCommentFeature.State(
                    announcemetId: announcement.id,
                    userId: appStore.userProfile?.uid ?? "",
                    email: appStore.userProfile?.email ?? ""
                ),
                reducer: {
                    AnnouncementCommentFeature()
                }
            )
            
            AnnouncementDetailView(store: self.store, appStore: self.appStore, commentStore: commentStore, announcement: announcement, isEdited: $isEdited, isAdmin: false)
        }
    }

    // Firestore에서 가장 최근 공지사항 가져오기
    private func fetchLatestNotice() {
        let db = Firestore.firestore()
        db.collection("notices")
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching latest notice: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }

                guard let document = snapshot?.documents.first else {
                    self.isLoading = false
                    return
                }

                do {
                    let notice = try document.data(as: Announcement.self)
                    self.latestNotice = notice

                    // 이미지 처리
                    if let imageURL = notice.imageURLs.first {
                        loadImage(from: imageURL)
                    }
                } catch {
                    print("Error decoding notice: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
    }

    // 이미지 로딩 함수
    private func loadImage(from url: String) {
        guard let imageURL = URL(string: url) else { return }
        URLSession.shared.dataTask(with: imageURL) { data, _, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                return
            }
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
        }.resume()
    }
}
