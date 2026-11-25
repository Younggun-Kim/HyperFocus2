//
//  WebPageView.swift
//  Setting
//

import SwiftUI
import WebKit

/// 주소 하나를 불러와 보여주는 웹 페이지.
/// iOS 18 타깃이라 SwiftUI `WebView`(iOS 26) 대신 `WKWebView`를 감싼다.
struct WebPageView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        // updateUIView는 SwiftUI 갱신마다 불리므로 로드는 생성 시 한 번만 한다.
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
