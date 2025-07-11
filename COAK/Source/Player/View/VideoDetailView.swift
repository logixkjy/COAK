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
    @StateObject var commentReportStore: StoreOf<CommentReportFeature>
    
    init(video: YouTubeVideo, store: StoreOf<AppFeature>, commentStore: StoreOf<VideoCommentFeature>, commentReportStore: StoreOf<CommentReportFeature>) {
        self.video = video
        self.store = store
        _commentStore = StateObject(wrappedValue: commentStore)
        _commentReportStore = StateObject(wrappedValue: commentReportStore)
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var isDescriptionExpanded = false
    @State private var isCommenting: Bool = false
    @State private var isReply: Bool = false
    @State private var isEdit: Bool = false
    @State private var localText: String = ""
    @State private var isSecret: Bool = false
    @State private var alertMessage: String = ""
    @State private var showDiscardAlert = false
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { appViewStore in
            WithViewStore(commentStore, observe: { $0 }) { viewStore in
                WithViewStore(commentReportStore, observe: { $0 }) { reportStore in
                    NavigationStack {
                        ZStack {
                            Color.black01.ignoresSafeArea()
                            
                            ZStack(alignment: .bottom) {
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
                                                        Button(isDescriptionExpanded ? NSLocalizedString("play_detail_description_unexpanded", comment: "") : NSLocalizedString("play_detail_description_expanded", comment: "")) {
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
                                                            appViewStore.favoriteVideoIDs.contains(video.id) ? NSLocalizedString("play_detail_favorites_remove" , comment: "") : NSLocalizedString("play_detail_favorites_add", comment: ""),
                                                            systemImage: appViewStore.favoriteVideoIDs.contains(video.id) ? "star.fill" : "star"
                                                        )
                                                    }
                                                    .buttonStyle(.borderedProminent)
                                                    .tint(appViewStore.favoriteVideoIDs.contains(video.id) ? .gray : .blue)
                                                }
                                                
                                                Divider()
                                                
                                                VStack(alignment: .leading, spacing: 12) {
                                                    Text("common_comment")
                                                        .font(.headline)
                                                    ForEach(viewStore.comments) { comment in
                                                        let commentVisivle = comment.isVisible(for: appViewStore.userProfile?.uid ?? "", isAdmin: appViewStore.userProfile?.isAdmin ?? false)
                                                        let isHidden = comment.isHidden ?? false
                                                        VStack(alignment: .leading, spacing: 6) {
                                                            HStack {
                                                                if commentVisivle && !isHidden {
                                                                    Text(comment.email)
                                                                        .font(.caption)
                                                                        .foregroundColor(.white)
                                                                }
                                                                Text(comment.createdAt.formatted(date: .numeric, time: .shortened))
                                                                    .font(.caption2)
                                                                    .foregroundColor(.gray)
                                                                
                                                                Spacer()
                                                                
                                                                Menu {
                                                                    if !isHidden {
                                                                        Button("common_report") {
                                                                            reportStore.send(.reportButtonTapped(
                                                                                comment.id,
                                                                                comment.content,
                                                                                .comment,
                                                                                nil,
                                                                                .video,
                                                                                appViewStore.userProfile?.email ?? "",
                                                                                viewStore.videoId)
                                                                            )
                                                                        }
                                                                    }
                                                                    
                                                                    if comment.userId == appViewStore.userProfile?.uid || (appViewStore.userProfile?.isAdmin ?? false) {
                                                                        if comment.userId == appViewStore.userProfile?.uid {
                                                                            Button("common_edit") {
                                                                                localText = comment.content
                                                                                isSecret = comment.isSecret ?? false
                                                                                commentStore.send(.startEdit(comment))
                                                                                isCommenting = true
                                                                                isEdit = true
                                                                            }
                                                                        }
                                                                        Button("common_delete", role: .destructive) {
                                                                            commentStore.send(.deleteComment(comment.id))
                                                                        }
                                                                    }
                                                                } label: {
                                                                    Text("      ⋮")
                                                                        .foregroundColor(.white)
                                                                }
                                                            }
                                                            Text(isHidden ? NSLocalizedString("common_comment_hidden", comment: "") : (commentVisivle ? comment.content : NSLocalizedString("common_comment_secret", comment: "")))
                                                                .font(.body)
                                                                .foregroundColor(.gray)
                                                            
                                                            HStack {
                                                                Button {
                                                                    commentStore.send(.setReplyTarget(comment.id))
                                                                    isCommenting = true
                                                                    isReply = true
                                                                    isSecret = comment.isSecret ?? false
                                                                } label: {
                                                                    Label("common_reply", systemImage: "arrow.turn.down.right")
                                                                }.font(.caption).foregroundColor(.white)
                                                                
                                                                if comment.replyCount > 0, viewStore.replyMap[comment.id] == nil {
                                                                    Button(String(format: NSLocalizedString("common_reply_conut", comment: ""), comment.replyCount)) {
                                                                        commentStore.send(.loadReplies(parentId: comment.id))
                                                                    }.font(.caption2)
                                                                }
                                                            }
                                                            // 답글이 비밀댓글인경우 댓글 작성자와 관리자만 볼수 있다.
                                                            if let replies = viewStore.replyMap[comment.id] {
                                                                ForEach(replies) { reply in
                                                                    let replayVisible = (reply.isSecret ?? false) ? commentVisivle : true
                                                                    let isHidden = reply.isHidden ?? false
                                                                    VStack(alignment: .leading, spacing: 4) {
                                                                        HStack {
                                                                            if replayVisible && !isHidden {
                                                                                Text(reply.email).font(.caption2).foregroundColor(.white)
                                                                            }
                                                                            Text(reply.createdAt.formatted(date: .numeric, time: .shortened))
                                                                                .font(.caption2).foregroundColor(.gray)
                                                                            
                                                                            Spacer()
                                                                            
                                                                            Menu {
                                                                                if !isHidden {
                                                                                    Button("common_report") {
                                                                                        reportStore.send(.reportButtonTapped(
                                                                                            reply.id,
                                                                                            reply.content,
                                                                                            .reply,
                                                                                            reply.parentId,
                                                                                            .video,
                                                                                            appViewStore.userProfile?.email ?? "",
                                                                                            viewStore.videoId)
                                                                                        )
                                                                                    }
                                                                                }
                                                                                if reply.userId == appViewStore.userProfile?.uid || (appViewStore.userProfile?.isAdmin ?? false) {
                                                                                    if reply.userId == appViewStore.userProfile?.uid {
                                                                                        Button("common_edit") {
                                                                                            localText = reply.content
                                                                                            isSecret = reply.isSecret ?? false
                                                                                            commentStore.send(.startEditReply(parentId: comment.id, reply: reply))
                                                                                            isCommenting = true
                                                                                            isReply = true
                                                                                            isEdit = true
                                                                                        }
                                                                                    }
                                                                                    Button("common_delete", role: .destructive) {
                                                                                        commentStore.send(.deleteReply(parentId: comment.id, replyId: reply.id))
                                                                                    }
                                                                                }
                                                                            } label: {
                                                                                Text("      ⋮").foregroundColor(.white)
                                                                            }
                                                                        }
                                                                        Text(isHidden ? NSLocalizedString("common_comment_hidden", comment: "") : (replayVisible ? reply.content :NSLocalizedString("common_reply_secret", comment: "") )).font(.body).foregroundColor(.gray)
                                                                    }
                                                                    .padding(.leading, 16)
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                    if viewStore.hasMore {
                                                        Button("common_comment_more") {
                                                            commentStore.send(.loadMoreComments)
                                                        }.font(.caption)
                                                    }
                                                }
                                            }
                                            .padding()
                                            .onChange(of: isCommenting) { field in
                                                if field {
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
                                    // 키보드 높이만큼 빈 공간 추가
                                    Spacer(minLength: 70)
                                }
                                
                                CommentInputView(
                                    text: $localText,  // 수정된 부분
                                    isSecret: $isSecret,
                                    isReply: $isReply,
                                    isEdit: $isEdit,
                                    isFocusedExternal: $isCommenting,
                                    onSubmit: { text, secret in
                                        if text.count > 0 {
                                            viewStore.send(.setNewCommentText(text, secret))
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
                                        viewStore.send(.setNewCommentText("", false))
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
                        }
                        .onAppear {
                            commentStore.send(.onAppear)
                        }
                        .onChange(of: viewStore.alertMessage) { newValue in
                            if let newValue = newValue {
                                alertMessage = newValue
                                showDiscardAlert.toggle()
                            }
                        }
                        .onChange(of: reportStore.alertMessage) { newValue in
                            if let newValue = newValue {
                                alertMessage = newValue
                                showDiscardAlert.toggle()
                            }
                        }
                        .alert(alertMessage, isPresented: $showDiscardAlert) {
                            Button("common_ok", role: .cancel) {}
                        }
                        .confirmationDialog(
                            NSLocalizedString("report_reason_select", comment: "") /*"신고 사유를 선택해주세요"*/,
                            isPresented: reportStore.binding(get: \.isShowingReasonDialog, send: .dismissReasonDialog),
                            titleVisibility: .visible
                        ) {
                            ForEach(ReportReason.allCases) { reason in
                                Button(reason.label) {
                                    reportStore.send(.selectReason(reason))
                                }
                            }
                            Button("common_cancel", role: .cancel) {
                                reportStore.send(.dismissReasonDialog)
                            }
                        }
                    }
                }
            }
        }
    }
}

