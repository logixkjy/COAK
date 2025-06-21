//
//  CommentClient.swift
//  COAK
//
//  Created by JooYoung Kim on 5/2/25.
//

import ComposableArchitecture
import FirebaseFirestore
import Foundation

struct CommentClient {
    var fetchComments: @Sendable (_ videoId: String, _ after: DocumentSnapshot?) async throws -> ([Comment], DocumentSnapshot?)
    var postComment: @Sendable (_ videoId: String, _ content: String, _ userId: String, _ email: String, _ isSecret: Bool) async throws -> Comment
    var editComment: @Sendable (_ videoId: String, _ commentId: String, _ newContent: String, _ isSecret: Bool) async throws -> Void
    var deleteComment: @Sendable (_ videoId: String, _ commentId: String) async throws -> Void

    var fetchReplies: @Sendable (_ videoId: String, _ commentId: String) async throws -> [Reply]
    var postReply: @Sendable (_ videoId: String, _ commentId: String, _ content: String, _ userId: String, _ email: String, _ isSecret: Bool) async throws -> Reply
    var editReply: @Sendable (_ videoId: String, _ commentId: String, _ replyId: String, _ newContent: String, _ isSecret: Bool) async throws -> Void
    var deleteReply: @Sendable (_ videoId: String, _ commentId: String, _ replyId: String) async throws -> Void
    
    public var setCommentHidden: @Sendable (String, String, Bool) async throws -> Void
    public var setReplyHidden: @Sendable (String, String, String, Bool) async throws -> Void
}

extension CommentClient: DependencyKey {
    static let liveValue: CommentClient = .init(
        fetchComments: { videoId, after in
            let query = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments")
                .order(by: "createdAt", descending: true)
                .limit(to: 10)

            let snapshot = try await (after != nil ? query.start(afterDocument: after!).getDocuments() : query.getDocuments())
            let comments = snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
            return (comments, snapshot.documents.last)
        },

        postComment: { videoId, content, userId, email, isSecret in
            let docRef = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments").document()

            let comment = Comment(
                id: docRef.documentID,
                content: content,
                createdAt: Date(),
                userId: userId,
                email: email,
                replyCount: 0,
                isSecret: isSecret
            )
            try docRef.setData(from: comment)
            return comment
        },

        editComment: { videoId, commentId, newContent, isSecret in
            let doc = Firestore.firestore().collection("videos").document(videoId).collection("comments").document(commentId)
            try await doc.updateData(["content": newContent, "isSecret" : isSecret])
        },

        deleteComment: { videoId, commentId in
            let doc = Firestore.firestore().collection("videos").document(videoId).collection("comments").document(commentId)
            try await doc.delete()
        },

        fetchReplies: { videoId, parentId in
            let query = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments").document(parentId)
                .collection("replies")
                .order(by: "createdAt")
            let snapshot = try await query.getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Reply.self) }
        },

        postReply: { videoId, parentId, content, userId, email, isSecret in
            let docRef = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments").document(parentId)
                .collection("replies").document()

            let reply = Reply(
                id: docRef.documentID,
                content: content,
                createdAt: Date(),
                userId: userId,
                email: email,
                parentId: parentId,
                isSecret: isSecret
            )
            try docRef.setData(from: reply)

            // replyCount 증가
            let parentRef = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments").document(parentId)
            try await parentRef.updateData(["replyCount": FieldValue.increment(Int64(1))])

            return reply
        },

        editReply: { videoId, parentId, replyId, newContent, isSecret in
            let ref = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments").document(parentId)
                .collection("replies").document(replyId)
            try await ref.updateData(["content": newContent, "isSecret" : isSecret])
        },

        deleteReply: { videoId, parentId, replyId in
            let ref = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments").document(parentId)
                .collection("replies").document(replyId)
            try await ref.delete()

            // replyCount 감소
            let parentRef = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments").document(parentId)
            try await parentRef.updateData(["replyCount": FieldValue.increment(Int64(-1))])
        },
        
        setCommentHidden: { videoId, commentId, hidden in
            let doc = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments").document(commentId)
            try await doc.updateData(["isHidden": hidden])
        },
        
        setReplyHidden: { videoId, parentId, replyId, hidden in
            let doc = Firestore.firestore()
                .collection("videos").document(videoId)
                .collection("comments").document(parentId)
                .collection("replies").document(replyId)
            try await doc.updateData(["isHidden": hidden])
        }
    )
}

extension DependencyValues {
    var commentClient: CommentClient {
        get { self[CommentClient.self] }
        set { self[CommentClient.self] = newValue }
    }
}

// MARK: - Model (여기만 정의)

struct Comment: Identifiable, Codable, Equatable {
    var id: String
    var content: String
    var createdAt: Date
    var userId: String
    var email: String
    var replyCount: Int
    var isSecret: Bool?
    var isHidden: Bool?
    
    func isVisible(for uid: String, isAdmin: Bool) -> Bool {
        return !(isSecret ?? false) || userId == uid || isAdmin
    }
}

struct Reply: Identifiable, Codable, Equatable {
    var id: String
    var content: String
    var createdAt: Date
    var userId: String
    var email: String
    var parentId: String
    var isSecret: Bool?
    var isHidden: Bool?
}
