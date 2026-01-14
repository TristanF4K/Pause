//
//  PauseApp.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

@main
struct PauseApp: App {
    // MARK: - Modern Dependency Injection Architecture
    // All controllers are now properly injected via SwiftUI Environment
    // This enables better testing, loose coupling, and clearer dependencies
    
    @StateObject private var selectionManager = SelectionManager.shared
    @StateObject private var screenTimeController: ScreenTimeController
    @StateObject private var appState: AppState
    @StateObject private var tagController: TagController
    @StateObject private var timeProfileController: TimeProfileController
    
    init() {
        // Create instances with proper dependency injection
        let selection = SelectionManager.shared
        let screenTime = ScreenTimeController(selectionManager: selection)
        let state = AppState(screenTimeController: screenTime)
        let tag = TagController(
            appState: state,
            screenTimeController: screenTime,
            selectionManager: selection
        )
        let timeProfile = TimeProfileController(
            appState: state,
            screenTimeController: screenTime,
            selectionManager: selection
        )
        
        // Initialize @StateObject properties
        _selectionManager = StateObject(wrappedValue: selection)
        _screenTimeController = StateObject(wrappedValue: screenTime)
        _appState = StateObject(wrappedValue: state)
        _tagController = StateObject(wrappedValue: tag)
        _timeProfileController = StateObject(wrappedValue: timeProfile)
        
        // Set up cross-references after initialization
        screenTime.selectionManager = selection
        state.screenTimeController = screenTime
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(screenTimeController)
                .environmentObject(selectionManager)
                .environmentObject(tagController)
                .environmentObject(timeProfileController)
        }
    }
}
