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
    static let shared = ScreenTimeController()
    
    private let store = ManagedSettingsStore()
    private let authCenter = AuthorizationCenter.shared
    private let selectionManager = SelectionManager.shared
    
    // Track current blocking state
    @Published private(set) var isCurrentlyBlocking = false
    @Published private(set) var activeTagID: UUID?
    @Published private(set) var isRequestingAuthorization = false
    @Published var lastAuthorizationStatus: AuthorizationStatus = .notDetermined
    
    // UserDefaults keys for persistence
    private let authorizationGrantedKey = "FocusLock_AuthorizationGranted"
    private let lastSuccessfulAuthKey = "FocusLock_LastSuccessfulAuth"
    private let blockingStateKey = "FocusLock_BlockingState"
    private let activeTagKey = "FocusLock_ActiveTag"
    
    private init() {
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
        isCurrentlyBlocking = UserDefaults.standard.bool(forKey: blockingStateKey)
        
        // Load active tag
        if let tagString = UserDefaults.standard.string(forKey: activeTagKey),
           let tagUUID = UUID(uuidString: tagString) {
            activeTagID = tagUUID
        }
    }
    
    private func saveState() {
        UserDefaults.standard.set(isCurrentlyBlocking, forKey: blockingStateKey)
        UserDefaults.standard.set(activeTagID?.uuidString, forKey: activeTagKey)
    }
    
    private func checkAuthorizationStatusNow() {
        let currentStatus = authCenter.authorizationStatus
        lastAuthorizationStatus = currentStatus
        
        switch currentStatus {
        case .approved:
            UserDefaults.standard.set(true, forKey: authorizationGrantedKey)
            UserDefaults.standard.set(Date(), forKey: lastSuccessfulAuthKey)
            
            // If we were blocking before app restart, try to restore the blocking state
            if isCurrentlyBlocking, let activeTag = activeTagID {
                restoreBlockingState(for: activeTag)
            }
            
        case .denied:
            UserDefaults.standard.set(false, forKey: authorizationGrantedKey)
            
        case .notDetermined:
            break
            
        @unknown default:
            break
        }
        
        // Notify AppState
        Task {
            await AppState.shared.checkAuthorizationStatus()
        }
    }
    
    private func restoreBlockingState(for tagID: UUID) {
        guard selectionManager.hasSelection(for: tagID) else {
            isCurrentlyBlocking = false
            activeTagID = nil
            saveState()
            return
        }
        
        // Use SelectionManager to restore blocking
        selectionManager.activateBlocking(for: tagID)
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
            UserDefaults.standard.set(false, forKey: authorizationGrantedKey)
            throw ScreenTimeError.authorizationDenied
        }
    }
    
    func checkAndRequestAuthorizationIfNeeded() async -> Bool {
        let currentStatus = authCenter.authorizationStatus
        
        switch currentStatus {
        case .approved:
            UserDefaults.standard.set(true, forKey: authorizationGrantedKey)
            UserDefaults.standard.set(Date(), forKey: lastSuccessfulAuthKey)
            UserDefaults.standard.set(true, forKey: "FocusLock_HasBeenAuthorized")
            return true
            
        case .denied:
            UserDefaults.standard.set(false, forKey: authorizationGrantedKey)
            UserDefaults.standard.set(false, forKey: "FocusLock_HasBeenAuthorized")
            return false
            
        case .notDetermined:
            // Check if we've been authorized before
            let hasBeenAuthorized = UserDefaults.standard.bool(forKey: "FocusLock_HasBeenAuthorized")
            
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
        print("🔒 ScreenTimeController: blockApps called for tag \(tagID)")
        
        // Simple authorization check - if not approved, the toggle method will handle it
        guard authCenter.authorizationStatus == .approved || UserDefaults.standard.bool(forKey: "FocusLock_HasBeenAuthorized") else {
            print("⚠️ ScreenTimeController: Authorization not approved")
            return
        }
        
        print("✅ ScreenTimeController: Authorization OK, activating blocking")
        
        // Use SelectionManager's blocking methods
        selectionManager.activateBlocking(for: tagID)
        
        isCurrentlyBlocking = true
        activeTagID = tagID
        saveState() // Persist state
        
        // Update app state
        AppState.shared.setBlockingState(isActive: true)
        
        print("✅ ScreenTimeController: Blocking state updated")
    }
    
    func unblockAll() {
        print("🔓 ScreenTimeController: unblockAll called")
        
        // 1. Use SelectionManager's deactivation (which clears the named blocking store)
        selectionManager.deactivateBlocking()
        
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
        
        // 5. Update app state
        AppState.shared.setBlockingState(isActive: false)
        
        print("✅ ScreenTimeController: All restrictions cleared")
    }
    
    /// Block apps with a specific selection and source ID (for time profiles)
    func blockApps(selection: FamilyActivitySelection, sourceID: UUID) async -> Bool {
        print("🔒 ScreenTimeController: blockApps called for source \(sourceID)")
        
        // Ensure we have authorization first
        guard await checkAndRequestAuthorizationIfNeeded() else {
            print("⚠️ ScreenTimeController: Authorization failed")
            return false
        }
        
        print("✅ ScreenTimeController: Authorization OK, activating blocking")
        
        // Apply the shield using SelectionManager
        selectionManager.setSelection(selection, for: sourceID)
        selectionManager.activateBlocking(for: sourceID)
        
        isCurrentlyBlocking = true
        activeTagID = sourceID
        saveState() // Persist state
        
        // Update app state
        AppState.shared.setBlockingState(isActive: true)
        
        print("✅ ScreenTimeController: Blocking state updated")
        return true
    }
    
    // MARK: - Toggle Logic
    
    func toggleBlocking(for tagID: UUID) async -> Bool {
        print("🔄 ScreenTimeController: toggleBlocking called for tag \(tagID)")
        print("   Current state: blocking=\(isCurrentlyBlocking), activeTag=\(activeTagID?.uuidString ?? "none")")
        
        // Ensure we have authorization first
        guard await checkAndRequestAuthorizationIfNeeded() else {
            print("⚠️ ScreenTimeController: Authorization failed")
            return false
        }
        
        print("✅ ScreenTimeController: Authorization OK")
        
        if isCurrentlyBlocking && activeTagID == tagID {
            // Same tag scanned again - unblock
            print("   → Deactivating (same tag scanned)")
            unblockAll()
        } else {
            // Different tag or no active blocking - block
            print("   → Activating (different tag or none active)")
            unblockAll() // Clear any existing restrictions first
            blockApps(for: tagID)
        }
        
        return true
    }
    
    // MARK: - Debug
    
    func debugPrintState() {
        print("=== ScreenTimeController Debug ===")
        print("Authorization Status: \(authCenter.authorizationStatus)")
        print("Is Blocking: \(isCurrentlyBlocking)")
        print("Active Tag: \(activeTagID?.uuidString ?? "none")")
        print("Last Auth Status: \(lastAuthorizationStatus)")
        print("=================================")
    }
    
    // MARK: - Deprecated (for backward compatibility)
    
    @available(*, deprecated, message: "Use blockApps(for tagID:) with FamilyActivitySelection instead")
    func blockApps(profile: BlockingProfile) {
        // Legacy method - won't work with current architecture
    }
}
