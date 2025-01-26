//
//  WebView.swift
//  CampusCommotion


import SwiftUI
import WebKit



struct SwiftUIWebView: UIViewRepresentable {
    
    let url: URL?
    @Binding var reload: Bool
    var loadStatusChanged: ((Bool, Error?) -> Void)? = nil
    
    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        return WKWebView(frame: .zero, configuration: config)
    }
    
    func makeCoordinator() -> SwiftUIWebView.Coordinator {
        Coordinator(self)
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let myUrl = url else {
            return
        }
        if reload {
            uiView.isHidden = true
            let request = URLRequest(url: myUrl)
            uiView.navigationDelegate = context.coordinator
            uiView.load(request)
            DispatchQueue.main.async {
                //reload = false
            }
        }
    }
    
    func onLoadStatusChanged(perform: ((Bool, Error?) -> Void)?) -> some View {
        var copy = self
        copy.loadStatusChanged = perform
        return copy
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: SwiftUIWebView
        @State private var oldMenu: Bool = (UserDefaults(suiteName: "group.com.sscheffler.CampusCommotion")?.bool(forKey: "oldMenu") ?? false)

        init(_ parent: SwiftUIWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.loadStatusChanged?(true, nil)
            debugPrint("commit?")
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.loadStatusChanged?(false, nil)
            UITraitCollection.current = UITraitCollection(traitsFrom: [UITraitCollection(userInterfaceStyle: .dark)])
            let currentSystemScheme = UITraitCollection.current.userInterfaceStyle
            print("HELLO????")
            var css = ""
            if currentSystemScheme == .light {
                //add this later
            } else {
                    css = "html {background-color: black !important; color: #ffffff;} .epicure-branding {display: none !important} .navbar-brand {display: none !important} .logo-container {display: none !important;} .NavigationBar {background-color:#1a1a1a !important} body {background: black !important} .MenuList h3 span {color:white !important;} .MenuList h3 {color:white !important;} .MenuListCard {background-color: #141414 !important;} .card-title{color:white !important;} .nutrients-list small {color:white !important;} .btn.active {background-color:#8d1b1d !important;   color:white !important;}.form-select {    background-color:black !important;    color:white !important;}.feedback-switch button {  color:white !important;}.view-switch button {  color:white !important;}.sidebar{  background-color:black !important;  color:white !important;}.SidebarMeal .mb-title {  background-color: black !important;  color:white !important;}.form-control {  background-color: black !important;   color:white !important;}.sticky-top {  background-color: black !important;  color:white !important;}.feedback-switch button {  background-color: black !important;}.SidebarMeal button{    color:white !important;}.SidebarMeal span{      color:white !important;}.NavigationBar span{        color:white !important;}.NavigationBar i{background-color: black; color:white !important;}.btn-group button {  background-color: black !important;}.mobile-navigation-bar-stations {background-color: black !important;} .list-group-item {background-color:#141414 !important;color: white !important;}.filters-title-container {background-color: black !important;}.input-group-text {background-color: black !important; color: white !important;}.meal-builder-meal-period {color:white !important;}.mb-location-title {color:white !important;}.meal-nutrition small {color: white !important;}.meal-nutrition i {color: white !important;} .MenuList .MenuListCard {border:0px !important;}.border {border:0px!important;} #clearMealDay .modal-content {background-color: #202020 !important;}"
                
                }
            
            let js = "var style = document.createElement('style'); style.innerHTML = '\(css)'; document.head.appendChild(style);"
            
            webView.evaluateJavaScript(js, completionHandler: { result, error in
                let seconds = 0.2
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    webView.isHidden = false
                    self.parent.reload = false
                }
            })
            
            debugPrint("done")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.loadStatusChanged?(false, error)
            debugPrint("bad")
        }
    }
    
}
