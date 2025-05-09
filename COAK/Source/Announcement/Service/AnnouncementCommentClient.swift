//
//  AnnouncementCommentClient.swift
//  COAK
//
//  Created by JooYoung Kim on 5/5/25.
//

import ComposableArchitecture
import FirebaseFirestore
import Foundation

struct AnnouncementCommentClient {
    var fetchComments: @Sendable (_ noticeId: String, _ after: DocumentSnapshot?) async throws -> ([Comment], DocumentSnapshot?)
    var postComment: @Sendable (_ noticeId: String, _ content: String, _ userId: String, _ email: String, _ profileImageURL: String) async throws -> Comment
    var editComment: @Sendable (_ noticeId: String, _ commentId: String, _ newContent: String) async throws -> Void
    var deleteComment: @Sendable (_ noticeId: String, _ commentId: String) async throws -> Void

    var fetchReplies: @Sendable (_ noticeId: String, _ commentId: String) async throws -> [Reply]
    var postReply: @Sendable (_ noticeId: String, _ commentId: String, _ content: String, _ userId: String, _ email: String, _ profileImageURL: String) async throws -> Reply
    var editReply: @Sendable (_ noticeId: String, _ commentId: String, _ replyId: String, _ newContent: String) async throws -> Void
    var deleteReply: @Sendable (_ noticeId: String, _ commentId: String, _ replyId: String) async throws -> Void
}

extension AnnouncementCommentClient: DependencyKey {
    static let liveValue: AnnouncementCommentClient = .init(
        fetchComments: { announcementId, after in
            let query = Firestore.firestore()
                .collection("notice_comments")
                .document(announcementId)
                .collection("comments")
                .order(by: "createdAt", descending: false)
                .limit(to: 10)

            let snapshot = try await (after != nil ? query.start(afterDocument: after!).getDocuments() : query.getDocuments())
            let comments = snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
            return (comments, snapshot.documents.last)
        },

        postComment: { announcementId, content, userId, email, profileImageURL in
            let docRef = Firestore.firestore()
                .collection("notice_comments")
                .document(announcementId)
                .collection("comments")
                .document()

            let comment = Comment(
                id: docRef.documentID,
                content: content,
                createdAt: Date(),
                userId: userId,
                email: email,
                profileImageURL: profileImageURL,
                replyCount: 0
            )
            try docRef.setData(from: comment)
            return comment
        },

        editComment: { announcementId, commentId, newContent in
            let doc = Firestore.firestore().collection("notice_comments")
                .document(announcementId).collection("comments").document(commentId)
            try await doc.updateData(["content": newContent])
        },

        deleteComment: { announcementId, commentId in
            let doc = Firestore.firestore().collection("notice_comments")
                .document(announcementId).collection("comments").document(commentId)
            try await doc.delete()
        },

        fetchReplies: { announcementId, parentId in
            let query = Firestore.firestore().collection("notice_comments")
                .document(announcementId).collection("comments").document(parentId)
                .collection("replies")
                .order(by: "createdAt")
            let snapshot = try await query.getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Reply.self) }
        },

        postReply: { announcementId, parentId, content, userId, email, profileImageURL in
            let docRef = Firestore.firestore().collection("notice_comments")
                .document(announcementId).collection("comments").document(parentId)
                .collection("replies").document()

            let reply = Reply(
                id: docRef.documentID,
                content: content,
                createdAt: Date(),
                userId: userId,
                email: email,
                profileImageURL: profileImageURL,
                parentId: parentId
            )
            try docRef.setData(from: reply)

            // replyCount 증가
            let parentRef = Firestore.firestore()
                .collection("notice_comments")
                .document(announcementId)
                .collection("comments").document(parentId)
            try await parentRef.updateData(["replyCount": FieldValue.increment(Int64(1))])

            return reply
        },

        editReply: { announcementId, parentId, replyId, newContent in
            let ref = Firestore.firestore()
                .collection("notice_comments")
                .document(announcementId)
                .collection("comments").document(parentId)
                .collection("replies").document(replyId)
            try await ref.updateData(["content": newContent])
        },

        deleteReply: { announcementId, parentId, replyId in
            let ref = Firestore.firestore()
                .collection("notice_comments")
                .document(announcementId)
                .collection("comments").document(parentId)
                .collection("replies").document(replyId)
            try await ref.delete()

            // replyCount 감소
            let parentRef = Firestore.firestore()
                .collection("notice_comments")
                .document(announcementId)
                .collection("comments").document(parentId)
            try await parentRef.updateData(["replyCount": FieldValue.increment(Int64(-1))])
        }
    )
}

extension DependencyValues {
    var announcementCommentClient: AnnouncementCommentClient {
        get { self[AnnouncementCommentClient.self] }
        set { self[AnnouncementCommentClient.self] = newValue }
    }
}

