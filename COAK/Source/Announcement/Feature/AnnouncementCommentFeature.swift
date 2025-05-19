//
//  AnnouncementCommentFeature.swift
//  COAK
//
//  Created by JooYoung Kim on 5/2/25.
//

// VideoCommentFeature.swift (답글 수정/삭제 및 UI 개선 흐름 포함)

import ComposableArchitecture
import Foundation
import FirebaseFirestore

@Reducer
struct AnnouncementCommentFeature {
    @ObservableState
    struct State: Equatable {
        var comments: [Comment] = []
        var newCommentText: String = ""
        var isSecret: Bool = false
        var isLoading: Bool = false
        var hasMore: Bool = true
        var lastDocument: DocumentSnapshot? = nil
        var announcemetId: String = ""
        var userId: String = ""
        var email: String = ""
        
        var isEditing = false
        var editingCommentId: String? = nil
        var replyTarget: String? = nil

        var isEditingReply = false
        var editingReplyParentId: String? = nil
        var editingReplyId: String? = nil

        var replyMap: [String: [Reply]] = [:] // commentId -> replies
        var isReplyLoadingMap: [String: Bool] = [:]
    }

    enum Action: Equatable {
        case onAppear
        case loadInitialComments
        case loadInitialCommentsResponse(Result<[Comment], CustomError>)
        case setLastDocument(DocumentSnapshot?)

        case loadMoreComments
        case loadMoreCommentsResponse(Result<[Comment], CustomError>)
        case appendLastDocument(DocumentSnapshot?)

        case setNewCommentText(String, Bool)
        case postComment
        case postCommentResponse(Result<Comment, CustomError>)

        case startEdit(Comment)
        case cancelEdit
        case confirmEdit
        case deleteComment(String)

        case setReplyTarget(String?)
        case clearReplyTarget
        case postReply(parentId: String)
        case postReplyResponse(Result<Reply, CustomError>)

        case loadReplies(parentId: String)
        case loadRepliesResponse(parentId: String, Result<[Reply], CustomError>)

        case startEditReply(parentId: String, reply: Reply)
        case cancelEditReply
        case confirmEditReply
        case deleteReply(parentId: String, replyId: String)
    }

    @Dependency(\.announcementCommentClient) var commentClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {

        case .onAppear:
            return .send(.loadInitialComments)

        case .loadInitialComments:
            state.isLoading = true
            return .run { [announcemetId = state.announcemetId] send in
                let (comments, last) = try await commentClient.fetchComments(announcemetId, nil)
                await send(.loadInitialCommentsResponse(.success(comments)))
                await send(.setLastDocument(last))
            } catch: { error, send in
                await send(.loadInitialCommentsResponse(.failure(.firebaseError(error.localizedDescription))))
            }

        case let .loadInitialCommentsResponse(.success(comments)):
            state.comments = comments
            state.hasMore = comments.count == 10
            state.isLoading = false
            return .none

        case let .setLastDocument(doc):
            state.lastDocument = doc
            return .none

        case .loadMoreComments:
            guard state.hasMore, let last = state.lastDocument else { return .none }
            return .run { [announcemetId = state.announcemetId] send in
                let (newComments, newLast) = try await commentClient.fetchComments(announcemetId, last)
                await send(.loadMoreCommentsResponse(.success(newComments)))
                await send(.appendLastDocument(newLast))
            } catch: { error, send in
                await send(.loadMoreCommentsResponse(.failure(.firebaseError(error.localizedDescription))))
            }

        case let .loadMoreCommentsResponse(.success(newComments)):
            state.comments += newComments
            state.hasMore = newComments.count == 10
            return .none

        case let .appendLastDocument(doc):
            state.lastDocument = doc
            return .none

        case let .setNewCommentText(text, isSecret):
            state.newCommentText = text
            state.isSecret = isSecret
            return .none

        case .postComment:
            guard !state.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .none }

            let text = state.newCommentText
            let isSecret = state.isSecret
            return .run { [announcemetId = state.announcemetId, userId = state.userId, email = state.email] send in
                let comment = try await commentClient.postComment(announcemetId, text, userId, email, isSecret)
                await send(.postCommentResponse(.success(comment)))
            } catch: { error, send in
                await send(.postCommentResponse(.failure(.firebaseError(error.localizedDescription))))
            }

        case let .postCommentResponse(.success(comment)):
            state.comments.insert(comment, at: 0)
            return .none

        case let .startEdit(comment):
            state.isEditing = true
            state.editingCommentId = comment.id
            state.newCommentText = comment.content
            state.isSecret = comment.isSecret ?? false
            return .none
            
        case .cancelEdit:
            state.isEditing = false
            state.editingCommentId = nil
            state.newCommentText = ""
            state.isSecret = false
            return .none

        case .confirmEdit:
            guard let editingId = state.editingCommentId else { return .none }
            let newText = state.newCommentText
            let isSecret = state.isSecret
            state.isEditing = false
            state.editingCommentId = nil
            return .run { [announcemetId = state.announcemetId] send in
                try await commentClient.editComment(announcemetId, editingId, newText, isSecret)
                await send(.loadInitialComments)
            } catch: { _, send in }

        case let .deleteComment(commentId):
            return .run { [announcemetId = state.announcemetId] send in
                try await commentClient.deleteComment(announcemetId, commentId)
                await send(.loadInitialComments)
            } catch: { _, send in }

        case let .setReplyTarget(commentId):
            state.replyTarget = commentId
            state.newCommentText = ""
            state.isSecret = false
            return .none
            
        case .clearReplyTarget:
            state.replyTarget = nil
            state.newCommentText = ""
            state.isSecret = false
            return .none

        case let .postReply(parentId):
            let text = state.newCommentText
            let isSecret = state.isSecret
            state.replyTarget = nil
            return .run { [announcemetId = state.announcemetId, userId = state.userId, email = state.email] send in
                let reply = try await commentClient.postReply(announcemetId, parentId, text, userId, email, isSecret)
                await send(.postReplyResponse(.success(reply)))
            } catch: { error, send in
                await send(.postReplyResponse(.failure(.firebaseError(error.localizedDescription))))
            }

        case let .postReplyResponse(.success(reply)):
            // parentId는 reply.id가 아니라 fetch 시 사용해야 하므로 loadReplies로 대응
            return .send(.loadReplies(parentId: reply.parentId))

        case let .loadReplies(parentId):
            state.isReplyLoadingMap[parentId] = true
            return .run { [announcemetId = state.announcemetId] send in
                let replies = try await commentClient.fetchReplies(announcemetId, parentId)
                await send(.loadRepliesResponse(parentId: parentId, .success(replies)))
            } catch: { error, send in
                await send(.loadRepliesResponse(parentId: parentId, .failure(.firebaseError(error.localizedDescription))))
            }

        case let .loadRepliesResponse(parentId, .success(replies)):
            state.replyMap[parentId] = replies
            state.isReplyLoadingMap[parentId] = false
            return .none

        case let .startEditReply(parentId, reply):
            state.isEditingReply = true
            state.editingReplyParentId = parentId
            state.editingReplyId = reply.id
            state.newCommentText = reply.content
            state.isSecret = reply.isSecret ?? false
            return .none
            
        case .cancelEditReply:
            state.isEditingReply = false
            state.editingReplyParentId = nil
            state.editingReplyId = nil
            state.newCommentText = ""
            return .none

        case .confirmEditReply:
            guard let parentId = state.editingReplyParentId, let replyId = state.editingReplyId else { return .none }
            let text = state.newCommentText
            let isSecret = state.isSecret
            state.isEditingReply = false
            state.editingReplyId = nil
            return .run { [announcemetId = state.announcemetId] send in
                try await commentClient.editReply(announcemetId, parentId, replyId, text, isSecret)
                await send(.loadReplies(parentId: parentId))
            } catch: { _, send in }

        case let .deleteReply(parentId, replyId):
            return .run { [announcemetId = state.announcemetId] send in
                try await commentClient.deleteReply(announcemetId, parentId, replyId)
                await send(.loadReplies(parentId: parentId))
            } catch: { _, send in }

        default:
            return .none
        }
    }
}
