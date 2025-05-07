//
//  AnnouncementDetailView.swift
//  COAK
//
//  Created by JooYoung Kim on 5/5/25.
//

import SwiftUI
import ComposableArchitecture

struct AnnouncementDetailView: View {
    let store: StoreOf<AnnouncementFeature>
    let appStore: StoreOf<AppFeature>
    @Environment(\.dismiss) private var dismiss
    @State var announcement: Announcement
    @Binding var isEdited: Bool
    var isAdmin: Bool = false
    
    @State private var isEditing: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Spacer().frame(height: 16)
                    // 작성자 정보
                    HStack {
                        if let url = URL(string: announcement.authorProfileImageURL ?? "") {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().frame(width: 40, height: 40).clipShape(Circle())
                                default:
                                    Circle().frame(width: 40, height: 40).foregroundColor(.gray)
                                        .foregroundColor(.white)
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                        }
                        
                        Text(announcement.authorName).bold()
                            .foregroundColor(.white)
                        
                        Text(announcement.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 본문
                    Text(.init(announcement.content))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    
                    // 이미지들
                    ForEach(announcement.imageURLs, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                default:
                                    Color.gray.frame(height: 200)
                                }
                            }
                            .padding(.horizontal, -16) // ✅ 좌우 여백 제거
                        }
                    }
                    
                    Divider()
                    // 댓글 영역 (추후 댓글 뷰와 통합)
                    Text("댓글")
                        .font(.headline)
                    
                    Text("댓글 기능은 이후 연결 예정")
                        .foregroundColor(.secondary)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if isAdmin {
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                Spacer().frame(height: 8)
                Divider()
            }
            .padding(.horizontal)
            .padding(.top, 8)
//            .padding([.top, .bottom], 8)
//            .padding(.vertical, 16)
            .background(Color.black.opacity(0.8))
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .navigationBarHidden(true)
        
        .sheet(isPresented: $isEditing, content: {
            AnnouncementEditView(store: self.store, appStore: self.appStore, announcement: $announcement, isEdited: $isEdited)
        })
    }
}
