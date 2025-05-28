//
//  SafariWebView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/14/25.
//


// SafariWebView.swift - 닫기 및 동의 버튼 포함된 개인정보 처리방침 WebView (AuthView 연동 포함)

import SwiftUI
import WebKit

struct SafariWebView: View {
    let url: URL
    var onAgree: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    init(url: URL, onAgree: (() -> Void)? = nil) {
        self.url = url
        self.onAgree = onAgree
    }
    var body: some View {
        NavigationStack {
            WebView(url: url)
//                .navigationTitle("join_policy_title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("common_close") {
                            dismiss()
                        }
                    }
                    if let onAgree = onAgree {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("join_policy_agree") {
                                dismiss()
                                onAgree()
                            }
                        }
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}

