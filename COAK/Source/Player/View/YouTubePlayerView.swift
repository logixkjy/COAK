//
//  YouTubePlayerView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userScript = WKUserScript(
            source: """
            document.querySelectorAll('a').forEach(a => {
              a.onclick = function(e) { e.preventDefault(); }
            });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let urlString = "https://www.youtube.com/embed/\(videoId)?rel=0&playsinline=1"
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }
}
