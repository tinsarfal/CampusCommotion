//
//  CampusCommotionApp.swift
//  CampusCommotion

import SwiftUI
import WatchConnectivity

@main
struct CampusCommotionApp: App {
    // Ensure the watch session is started on app launch
    init() {
        WatchSessionManager.sharedManager.startSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // When you need to push new data to the watch, use:
                    do {
                        try WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [
                            "key": "value" as AnyObject
                        ])
                    } catch {
                        print("Error sending application context to watch: \(error)")
                    }
                }
                .preferredColorScheme(.dark)
        }
    }
}
