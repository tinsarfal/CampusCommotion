//
//  WebViewController.swift
//  CampusCommotion

import UIKit
import WebKit

public class WebViewController: UIViewController {

    private let webView: WKWebView = WKWebView()

    override public func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self
        webView.isUserInteractionEnabled = true

        view = webView
    }
}

extension WebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("didCommit")
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish")
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFail")
    }
}
