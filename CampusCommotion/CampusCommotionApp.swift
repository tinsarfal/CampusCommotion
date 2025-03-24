//
//  CampusCommotionApp.swift
//  CampusCommotion

import SwiftUI
import WatchConnectivity

@main
struct CampusCommotionApp: App {
    // Ensure the watch session is started on app launch

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
