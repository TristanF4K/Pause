//
//  ScreenTimeController.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import Combine
import FamilyControls
import ManagedSettings
import OSLog

enum ScreenTimeError: Error, LocalizedError {
    case authorizationDenied
    case notAuthorized
    case unknownError
    case alreadyRequesting
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Screen Time Zugriff wurde verweigert"
        case .notAuthorized:
            return "Nicht autorisiert"
        case .unknownError:
            return "Ein unbekannter Fehler ist aufgetreten"
        case .alreadyRequesting:
            return "Autorisierung bereits in Bearbeitung"
        }
    }
}

@MainActor
class ScreenTimeController: ObservableObject {
    private let store = ManagedSettingsStore()
    private let authCenter = AuthorizationCenter.shared
    
    // Injected dependencies
    weak var selectionManager: SelectionManager?
    weak var appState: AppState?
    
    // Track current blocking state
    @Published private(set) var isCurrentlyBlocking = false
    @Published private(set) var activeTagID: UUID?
    @Published private(set) var isRequestingAuthorization = false
    @Published var lastAuthorizationStatus: AuthorizationStatus = .notDetermined
    
    // Public initializer for DI
    init(selectionManager: SelectionManager? = nil, appState: AppState? = nil) {
        self.selectionManager = selectionManager
        self.appState = appState
        
        // Always start with completely clean main store
        store.clearAllSettings()
        
        loadPersistedState()
        checkAuthorizationStatusNow()
    }
    
    var authorizationStatus: AuthorizationStatus {
        authCenter.authorizationStatus
    }
    
    // MARK: - Persistence
    
    private func loadPersistedState() {
        // Load blocking state
        isCurrentlyBlocking = UserDefaults.standard.blockingState
        
        // Load active source ID
        activeTagID = UserDefaults.standard.activeSourceID
    }
    
    private func saveState() {
        UserDefaults.standard.blockingState = isCurrentlyBlocking
        UserDefaults.standard.activeSourceID = activeTagID
    }
    
    private func checkAuthorizationStatusNow() {
        let currentStatus = authCenter.authorizationStatus
        lastAuthorizationStatus = currentStatus
        
        switch currentStatus {
        case .approved:
            UserDefaults.standard.authorizationGranted = true
            UserDefaults.standard.lastSuccessfulAuth = Date()
            UserDefaults.standard.hasBeenAuthorized = true
            
            // If we were blocking before app restart, try to restore the blocking state
            if isCurrentlyBlocking, let activeTag = activeTagID {
                restoreBlockingState(for: activeTag)
            }
            
        case .denied:
            UserDefaults.standard.authorizationGranted = false
            UserDefaults.standard.hasBeenAuthorized = false
            
        case .notDetermined:
            break
            
        @unknown default:
            break
        }
        
        // Notify AppState if available
        if let appState = appState {
            Task {
                await appState.checkAuthorizationStatus()
            }
        }
    }
    
    private func restoreBlockingState(for tagID: UUID) {
        guard let manager = selectionManager else {
            AppLogger.screenTime.error("❌ SelectionManager not injected, cannot restore blocking state")
            isCurrentlyBlocking = false
            activeTagID = nil
            saveState()
            return
        }
        
        guard manager.hasSelection(for: tagID) else {
            isCurrentlyBlocking = false
            activeTagID = nil
            saveState()
            return
        }
        
        // Use SelectionManager to restore blocking
        manager.activateBlocking(for: tagID)
    }
    
    func requestAuthorization() async throws {
        guard !isRequestingAuthorization else {
            throw ScreenTimeError.alreadyRequesting
        }
        
        isRequestingAuthorization = true
        defer { isRequestingAuthorization = false }
        
        do {
            try await authCenter.requestAuthorization(for: .individual)
            
            // Update status immediately after successful request
            checkAuthorizationStatusNow()
            
        } catch {
            UserDefaults.standard.authorizationGranted = false
            throw ScreenTimeError.authorizationDenied
        }
    }
    
    func checkAndRequestAuthorizationIfNeeded() async -> Bool {
        let currentStatus = authCenter.authorizationStatus
        
        switch currentStatus {
        case .approved:
            UserDefaults.standard.authorizationGranted = true
            UserDefaults.standard.lastSuccessfulAuth = Date()
            UserDefaults.standard.hasBeenAuthorized = true
            return true
            
        case .denied:
            UserDefaults.standard.authorizationGranted = false
            UserDefaults.standard.hasBeenAuthorized = false
            return false
            
        case .notDetermined:
            // Check if we've been authorized before
            let hasBeenAuthorized = UserDefaults.standard.hasBeenAuthorized
            
            if hasBeenAuthorized {
                // Try silent reauthorization first
                do {
                    try await requestAuthorization()
                    if authCenter.authorizationStatus == .approved {
                        return true
                    }
                } catch {
                    // Silent reauth failed, but that's ok - we'll handle it gracefully
                }
                
                // Even if silent reauth failed, we can still proceed
                // Authorization will be requested when actually needed
                return true
            } else {
                // First time, need explicit authorization
                do {
                    try await requestAuthorization()
                    return authCenter.authorizationStatus == .approved
                } catch {
                    return false
                }
            }
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Blocking with FamilyActivitySelection
    
    func blockApps(for tagID: UUID) {
        AppLogger.screenTime.info("blockApps called for tag \(tagID)")
        
        // Simple authorization check - if not approved, the toggle method will handle it
        guard authCenter.authorizationStatus == .approved || UserDefaults.standard.hasBeenAuthorized else {
            AppLogger.screenTime.warning("Authorization not approved")
            return
        }
        
        AppLogger.screenTime.debug("Authorization OK, activating blocking")
        
        // Use SelectionManager's blocking methods
        guard let manager = selectionManager else {
            AppLogger.screenTime.error("❌ SelectionManager not injected")
            return
        }
        
        manager.activateBlocking(for: tagID)
        
        isCurrentlyBlocking = true
        activeTagID = tagID
        saveState() // Persist state
        
        // Update app state if available
        appState?.setBlockingState(isActive: true)
        
        AppLogger.screenTime.info("Blocking state updated")
    }
    
    func unblockAll() {
        AppLogger.screenTime.info("unblockAll called")
        
        // 1. Use SelectionManager's deactivation (which clears the named blocking store)
        guard let manager = selectionManager else {
            AppLogger.screenTime.error("❌ SelectionManager not injected")
            return
        }
        
        manager.deactivateBlocking()
        
        // 2. Also clear the main/default store to be absolutely sure
        store.shield.applications = nil
        store.shield.applicationCategories = .specific([], except: [])
        store.shield.webDomains = nil
        store.shield.webDomainCategories = .specific([], except: [])
        
        // 3. Clear ALL other possible restrictions
        store.application.denyAppInstallation = false
        store.application.denyAppRemoval = false
        store.dateAndTime.requireAutomaticDateAndTime = false
        store.gameCenter.denyMultiplayerGaming = false
        store.media.denyExplicitContent = false
        store.passcode.lockPasscode = false
        store.cellular.lockAppCellularData = false
        store.account.lockAccounts = false
        
        // 4. Update state
        isCurrentlyBlocking = false
        activeTagID = nil
        saveState() // Persist state
        
        // 5. Update app state if available
        appState?.setBlockingState(isActive: false)
        
        AppLogger.screenTime.info("All restrictions cleared")
    }
    
    /// Block apps with a specific selection and source ID (for time profiles)
    func blockApps(selection: FamilyActivitySelection, sourceID: UUID) async -> Bool {
        AppLogger.screenTime.info("blockApps called for source \(sourceID)")
        
        // Ensure we have authorization first
        guard await checkAndRequestAuthorizationIfNeeded() else {
            AppLogger.screenTime.warning("Authorization failed")
            return false
        }
        
        AppLogger.screenTime.debug("Authorization OK, activating blocking")
        
        // Apply the shield using SelectionManager
        guard let manager = selectionManager else {
            AppLogger.screenTime.error("❌ SelectionManager not injected")
            return false
        }
        
        manager.setSelection(selection, for: sourceID)
        manager.activateBlocking(for: sourceID)
        
        isCurrentlyBlocking = true
        activeTagID = sourceID
        saveState() // Persist state
        
        // Update app state if available
        appState?.setBlockingState(isActive: true)
        
        AppLogger.screenTime.info("Blocking state updated")
        return true
    }
    
    // MARK: - Toggle Logic
    
    func toggleBlocking(for tagID: UUID) async -> Bool {
        AppLogger.screenTime.info("toggleBlocking called for tag \(tagID)")
        AppLogger.screenTime.debug("Current state: blocking=\(self.isCurrentlyBlocking), activeTag=\(self.activeTagID?.uuidString ?? "none")")
        
        // Ensure we have authorization first
        guard await checkAndRequestAuthorizationIfNeeded() else {
            AppLogger.screenTime.warning("Authorization failed")
            return false
        }
        
        AppLogger.screenTime.debug("Authorization OK")
        
        if isCurrentlyBlocking && activeTagID == tagID {
            // Same tag scanned again - unblock
            AppLogger.screenTime.info("Deactivating (same tag scanned)")
            unblockAll()
        } else {
            // Different tag or no active blocking - block
            AppLogger.screenTime.info("Activating (different tag or none active)")
            unblockAll() // Clear any existing restrictions first
            blockApps(for: tagID)
        }
        
        return true
    }
    
    // MARK: - Debug
    
    func debugPrintState() {
        AppLogger.screenTime.debug("=== ScreenTimeController Debug ===")
        AppLogger.screenTime.debug("Authorization Status: \(self.authCenter.authorizationStatus)")
        AppLogger.screenTime.debug("Is Blocking: \(self.isCurrentlyBlocking)")
        AppLogger.screenTime.debug("Active Tag: \(self.activeTagID?.uuidString ?? "none")")
        AppLogger.screenTime.debug("Last Auth Status: \(self.lastAuthorizationStatus)")
        AppLogger.screenTime.debug("=================================")
    }
    
    // MARK: - Deprecated (for backward compatibility)
    
    @available(*, deprecated, message: "Use blockApps(for tagID:) with FamilyActivitySelection instead")
    func blockApps(profile: BlockingProfile) {
        // Legacy method - won't work with current architecture
    }
}
