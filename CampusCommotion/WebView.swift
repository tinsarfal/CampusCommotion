import SwiftUI
import WebKit
import Alamofire

struct SwiftUIWebView: UIViewRepresentable {
    let url: URL?
    @Binding var reload: Bool
    var loadStatusChanged: ((Bool, Error?) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isHidden = true // Hide the web view initially
        return webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = url else { return }

        if reload {
            NetworkManager.shared.request(url).response { response in
                if let data = response.data {
                    uiView.load(data, mimeType: response.response?.mimeType ?? "text/html", characterEncodingName: "utf-8", baseURL: url)
                }
                DispatchQueue.main.async {
                    self.reload = false
                }
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SwiftUIWebView

        init(_ parent: SwiftUIWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.loadStatusChanged?(true, nil)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.loadStatusChanged?(false, nil)

            let darkModeCSS = """
            (function() {
                if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
                    var css = 'html {background-color: black !important; color: #ffffff;} .epicure-branding {display: none !important} .navbar-brand {display: none !important} .logo-container {display: none !important;} .NavigationBar {background-color:#1a1a1a !important} body {background: black !important} .MenuList h3 span {color:white !important;} .MenuList h3 {color:white !important;} .MenuListCard {background-color: #141414 !important;} .card-title{color:white !important;} .nutrients-list small {color:white !important;} .btn.active {background-color:#8d1b1d !important; color:white !important;}.form-select {background-color:black !important; color:white !important;}.feedback-switch button {color:white !important;}.view-switch button {color:white !important;}.sidebar{background-color:black !important; color:white !important;}.SidebarMeal .mb-title {background-color: black !important; color:white !important;}.form-control {background-color: black !important; color:white !important;}.sticky-top {background-color: black !important; color:white !important;}.feedback-switch button {background-color: black !important;}.SidebarMeal button{color:white !important;}.SidebarMeal span{color:white !important;}.NavigationBar span{color:white !important;}.NavigationBar i{background-color: black; color:white !important;}.btn-group button {background-color: black !important;}.mobile-navigation-bar-stations {background-color: black !important;} .list-group-item {background-color:#141414 !important;color: white !important;}.filters-title-container {background-color: black !important;}.input-group-text {background-color: black !important; color: white !important;}.meal-builder-meal-period {color:white !important;}.mb-location-title {color:white !important;}.meal-nutrition small {color: white !important;}.meal-nutrition i {color: white !important;} .MenuList .MenuListCard {border:0px !important;}.border {border:0px!important;} #clearMealDay .modal-content {background-color: #202020 !important;}';
                    var style = document.createElement('style');
                    style.innerHTML = css;
                    document.head.appendChild(style);
                }
            })();
            """

            webView.evaluateJavaScript(darkModeCSS) { _, _ in
                webView.isHidden = false // Show the web view after JavaScript injection
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.loadStatusChanged?(false, error)
        }
    }
}
