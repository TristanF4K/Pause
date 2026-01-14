//
//  PauseApp.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

@main
struct PauseApp: App {
    @StateObject private var appState = AppState.shared
    
    init() {
        // Initialize TimeProfileController to start monitoring
        _ = TimeProfileController.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
