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
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              background-color: black;
              height: 100%;
              width: 100%;
              overflow: hidden;
            }
            #player {
              position: absolute;
              top: 0;
              left: 0;
              width: 100%;
              height: 100%;
            }
          </style>
        </head>
        <body>
          <div id="player"></div>
          <script>
            var tag = document.createElement('script');
            tag.src = "https://www.youtube.com/iframe_api";
            var firstScriptTag = document.getElementsByTagName('script')[0];
            firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

            var player;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                videoId: '\(videoId)',
                playerVars: {
                  'playsinline': 1,
                  'rel': 0,
                  'modestbranding': 1,
                  'enablejsapi': 1,
                  'origin': 'https://www.youtube-nocookie.com'
                },
                events: {
                  'onReady': function() { console.log('ready'); },
                  'onError': function(e) { console.log('error', e.data); }
                }
              });
            }
          </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }
}
