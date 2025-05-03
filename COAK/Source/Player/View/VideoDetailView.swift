//
//  VideoDetailView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//
import SwiftUI
import WebKit
import ComposableArchitecture
import FirebaseFirestore

struct VideoDetailView: View {
    let video: YouTubeVideo
    let store: StoreOf<AppFeature>
    @StateObject var commentStore: StoreOf<VideoCommentFeature>
    
    init(video: YouTubeVideo, store: StoreOf<AppFeature>, commentStore: StoreOf<VideoCommentFeature>) {
        self.video = video
        self.store = store
        _commentStore = StateObject(wrappedValue: commentStore)
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var isDescriptionExpanded = false
    @State private var localText: String = ""
    
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case comment
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { appViewStore in
            WithViewStore(commentStore, observe: { $0 }) { viewStore in
                NavigationStack {
                    VStack(spacing: 0) {
                        YouTubePlayerView(videoId: video.id)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(alignment: .topLeading) {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 20, weight: .semibold))
                                        .padding(8)
                                        .foregroundColor(.primary)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                .padding(.top, 12)
                                .padding(.leading, 12)
                            }
                        
                        Divider()
                        
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(video.title)
                                        .font(.title2)
                                        .bold()
                                    
                                    Text(video.description)
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .lineLimit(isDescriptionExpanded ? nil : 3)
                                    
                                    HStack {
                                        if video.description.count > 0 {
                                            Button(isDescriptionExpanded ? "접기" : "자세히 보기") {
                                                withAnimation {
                                                    isDescriptionExpanded.toggle()
                                                }
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            if appViewStore.favoriteVideoIDs.contains(video.id) {
                                                appViewStore.send(.removeFromFavorites(video.id))
                                            } else {
                                                appViewStore.send(.addToFavorites(video))
                                            }
                                        }) {
                                            Label(
                                                appViewStore.favoriteVideoIDs.contains(video.id) ? "즐겨찾기 삭제" : "즐겨찾기 추가",
                                                systemImage: appViewStore.favoriteVideoIDs.contains(video.id) ? "star.fill" : "star"
                                            )
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(appViewStore.favoriteVideoIDs.contains(video.id) ? .gray : .blue)
                                    }
                                    
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(viewStore.comments) { comment in
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
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
                                                                    commentStore.send(.startEdit(comment))
                                                                    focusedField = .comment
                                                                    localText = comment.content
                                                                }
                                                            }
                                                            Button("삭제", role: .destructive) {
                                                                commentStore.send(.deleteComment(comment.id))
                                                            }
                                                        } label: {
                                                            Text("⋮")
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
                                                        focusedField = .comment
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
                                                                                commentStore.send(.startEditReply(parentId: comment.id, reply: reply))
                                                                                focusedField = .comment
                                                                                localText = reply.content
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
                                .onChange(of: focusedField) { field in
                                    if field == .comment {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation {
                                                proxy.scrollTo("댓글입력영역", anchor: .bottom)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        HStack(spacing: 8) {
                            ZStack(alignment: .trailing) {
                                TextField(viewStore.replyTarget == nil ? "댓글을 입력하세요" : "대댓글을 입력하세요", text: $localText)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .comment)
                                    .padding(.trailing, 40)
                                
                                Text("\(localText.count)/200")
                                    .font(.caption)
                                    .foregroundColor(localText.count > 200 ? .red : .gray)
                            }
                            .onChange(of: localText) { newValue in
                                if newValue.count > 200 {
                                    localText = String(newValue.prefix(200))
                                }
                            }
                            
                            Button("등록") {
                                if localText.count > 0 {
                                    viewStore.send(.setNewCommentText(localText))
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
                                focusedField = nil
                                localText = ""
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        // Do scroll if needed
                                    }
                                }
                            }
                            .disabled(localText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding()
                        .id("댓글입력영역")
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("완료") {
                                focusedField = nil
                            }
                        }
                    }
                    .onAppear {
                        commentStore.send(.onAppear)
                    }
                }
            }
        }
    }
}
