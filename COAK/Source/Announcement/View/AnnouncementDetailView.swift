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
    @StateObject var commentStore: StoreOf<AnnouncementCommentFeature>
    @State var announcement: Announcement
    @Binding var isEdited: Bool
    var isAdmin: Bool = false
    
    @State private var isEditing: Bool = false
    
    
    init(
        store: StoreOf<AnnouncementFeature>,
        appStore: StoreOf<AppFeature>,
        commentStore: StoreOf<AnnouncementCommentFeature>,
        announcement: Announcement,
        isEdited: Binding<Bool>,
        isAdmin: Bool
    ) {
        self.store = store
        self.appStore = appStore
        _commentStore = StateObject(wrappedValue: commentStore)
        self.announcement = announcement
        self._isEdited = isEdited
        self.isAdmin = isAdmin
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var isCommenting: Bool = false
    @State private var isReply: Bool = false
    @State private var isEdit: Bool = false
    @State private var localText: String = ""
    
    var body: some View {
        WithViewStore(appStore, observe: { $0 }) { appViewStore in
            WithViewStore(commentStore, observe: { $0 }) { viewStore in
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
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
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                // 작성자 정보
                                HStack {
//                                    if let url = URL(string: announcement.authorProfileImageURL ?? "") {
//                                        AsyncImage(url: url) { phase in
//                                            switch phase {
//                                            case .success(let image):
//                                                image.resizable().frame(width: 40, height: 40).clipShape(Circle())
//                                            default:
//                                                Circle().frame(width: 40, height: 40).foregroundColor(.gray)
//                                                    .foregroundColor(.white)
//                                            }
//                                        }
//                                    } else {
//                                        Image(systemName: "person.crop.circle.fill")
//                                            .resizable()
//                                            .frame(width: 40, height: 40)
//                                            .foregroundColor(.white)
//                                    }
                                    
                                    Text(announcement.email).bold()
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
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("댓글")
                                        .font(.headline)
                                    ForEach(viewStore.comments) { comment in
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
//                                                if let url = URL(string: comment.profileImageURL ?? "") {
//                                                    AsyncImage(url: url) { phase in
//                                                        switch phase {
//                                                        case .success(let image):
//                                                            image.resizable().frame(width: 24, height: 24).clipShape(Circle())
//                                                        default:
//                                                            Circle().frame(width: 24, height: 24).foregroundColor(.gray)
//                                                        }
//                                                    }
//                                                } else {
//                                                    Image(systemName: "person.crop.circle.fill")
//                                                        .resizable()
//                                                        .frame(width: 24, height: 24)
//                                                }
                                                
                                                Text(comment.email)
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                Text(comment.createdAt.formatted(date: .numeric, time: .shortened))
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                                
                                                Spacer()
                                                
                                                if comment.userId == appViewStore.userProfile?.uid || appViewStore.isAdmin {
                                                    Menu {
                                                        if comment.userId == appViewStore.userProfile?.uid {
                                                            Button("수정") {
                                                                localText = comment.content
                                                                commentStore.send(.startEdit(comment))
                                                                isCommenting = true
                                                                isEdit = true
                                                            }
                                                        }
                                                        Button("삭제", role: .destructive) {
                                                            commentStore.send(.deleteComment(comment.id))
                                                        }
                                                    } label: {
                                                        Text("      ⋮")
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                            }
                                            Text(comment.content)
                                                .font(.body)
                                                .foregroundColor(.gray)
                                            
                                            HStack {
                                                Button {
                                                    commentStore.send(.setReplyTarget(comment.id))
                                                    isCommenting = true
                                                    isReply = true
                                                } label: {
                                                    Label("답글", systemImage: "arrow.turn.down.right")
                                                }.font(.caption).foregroundColor(.white)
                                                
                                                if comment.replyCount > 0, viewStore.replyMap[comment.id] == nil {
                                                    Button("답글 \(comment.replyCount)개 보기") {
                                                        commentStore.send(.loadReplies(parentId: comment.id))
                                                    }.font(.caption2)
                                                }
                                            }
                                            
                                            if let replies = viewStore.replyMap[comment.id] {
                                                ForEach(replies) { reply in
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        HStack {
                                                            Text(reply.email).font(.caption2).foregroundColor(.white)
                                                            Text(reply.createdAt.formatted(date: .numeric, time: .shortened))
                                                                .font(.caption2).foregroundColor(.gray)
                                                            Spacer()
                                                            if reply.userId == appViewStore.userProfile?.uid || appViewStore.isAdmin {
                                                                Menu {
                                                                    if reply.userId == appViewStore.userProfile?.uid {
                                                                        Button("수정") {
                                                                            localText = reply.content
                                                                            commentStore.send(.startEditReply(parentId: comment.id, reply: reply))
                                                                            isCommenting = true
                                                                            isReply = true
                                                                            isEdit = true
                                                                        }
                                                                    }
                                                                    Button("삭제", role: .destructive) {
                                                                        commentStore.send(.deleteReply(parentId: comment.id, replyId: reply.id))
                                                                    }
                                                                } label: {
                                                                    Text("⋮").foregroundColor(.white)
                                                                }
                                                            }
                                                        }
                                                        Text(reply.content).font(.body).foregroundColor(.gray)
                                                    }
                                                    .padding(.leading, 16)
                                                }
                                            }
                                        }
                                    }
                                    
                                    if viewStore.hasMore {
                                        Button("더 보기") {
                                            commentStore.send(.loadMoreComments)
                                        }.font(.caption)
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        Divider()
                        // 키보드 높이만큼 빈 공간 추가
                        Spacer(minLength: 70)
                    }
                    .background(Color.black.opacity(0.8))
                
                
                    CommentInputView(
                        text: $localText,  // 수정된 부분
                        isReply: $isReply,
                        isEdit: $isEdit,
                        isFocusedExternal: $isCommenting,
                        onSubmit: { text in
                            if text.count > 0 {
                                viewStore.send(.setNewCommentText(text))
                            }
                            if viewStore.isEditing {
                                commentStore.send(.confirmEdit)
                            } else if viewStore.isEditingReply {
                                commentStore.send(.confirmEditReply)
                            } else if let parentId = viewStore.replyTarget {
                                commentStore.send(.postReply(parentId: parentId))
                            } else {
                                commentStore.send(.postComment)
                            }
                            viewStore.send(.setNewCommentText(""))
                            localText = ""
                            isCommenting = false
                        },
                        onCancel: {
                            if isReply && isEdit {
                                commentStore.send(.cancelEditReply)
                            } else if !isReply && isEdit {
                                commentStore.send(.cancelEdit)
                            } else if isReply && !isEdit {
                                commentStore.send(.clearReplyTarget)
                            }
                            isReply = false
                            isEdit = false
                        }
                    )
                    .id("댓글입력영역")
                    
                }
//                .ignoresSafeArea(.all, edges: .bottom)
                .navigationBarHidden(true)
                
                .onAppear {
                    commentStore.send(.onAppear)
                }
                .sheet(isPresented: $isEditing, content: {
                    AnnouncementEditView(store: self.store, appStore: self.appStore, announcement: $announcement, isEdited: $isEdited)
                })
            }
        }
    }
}
