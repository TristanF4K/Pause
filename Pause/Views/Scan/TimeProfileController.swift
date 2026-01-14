//
//  TimeProfileController.swift
//  Pause.
//
//  Created by Tristan Srebot on 14.01.26.
//

import Foundation
import FamilyControls
import Combine

class TimeProfileController {
    static let shared = TimeProfileController()
    
    private let appState = AppState.shared
    private let screenTimeController = ScreenTimeController.shared
    private let selectionManager = SelectionManager.shared
    
    /// Timer for checking time profiles
    private var checkTimer: Timer?
    
    private init() {
        Task { @MainActor in
            startMonitoring()
        }
    }
    
    deinit {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    // MARK: - Profile Management
    
    @MainActor
    func createProfile(name: String) -> TimeProfile {
        let profile = TimeProfile(name: name)
        appState.addTimeProfile(profile)
        return profile
    }
    
    @MainActor
    func linkAppsToProfile(profile: TimeProfile, selection: FamilyActivitySelection) {
        // Store selection in SelectionManager
        selectionManager.setSelection(selection, for: profile.id)
        
        // Update profile metadata for UI purposes
        var updatedProfile = profile
        
        // Encode tokens as base64 strings for storage
        let encoder = JSONEncoder()
        updatedProfile.linkedAppTokens = Set(selection.applicationTokens.compactMap { token in
            try? encoder.encode(token).base64EncodedString()
        })
        updatedProfile.linkedCategoryTokens = Set(selection.categoryTokens.compactMap { token in
            try? encoder.encode(token).base64EncodedString()
        })
        
        appState.updateTimeProfile(updatedProfile)
    }
    
    @MainActor
    func updateSchedule(profile: TimeProfile, schedule: TimeSchedule) {
        var updatedProfile = profile
        updatedProfile.schedule = schedule
        appState.updateTimeProfile(updatedProfile)
        
        // Re-evaluate if any profiles should be active now
        checkAndUpdateProfiles()
    }
    
    @MainActor
    func toggleEnabled(profile: TimeProfile) {
        // Check if a tag is currently active
        if appState.getActiveTag() != nil && !profile.isEnabled {
            print("⚠️ Cannot enable time profile - a tag is currently active")
            return
        }
        
        var updatedProfile = profile
        updatedProfile.isEnabled = !updatedProfile.isEnabled
        appState.updateTimeProfile(updatedProfile)
        
        // Re-evaluate profiles
        checkAndUpdateProfiles()
    }
    
    @MainActor
    func deleteProfile(profile: TimeProfile) {
        // SECURITY: Cannot delete profile while it's currently blocking
        if profile.isCurrentlyBlocking(appState: appState, screenTimeController: screenTimeController) {
            print("🚫 Cannot delete time profile while it's currently active and blocking")
            return
        }
        
        // Remove selection from memory
        selectionManager.removeSelection(for: profile.id)
        
        // Remove profile from app state
        appState.deleteTimeProfile(profile)
        
        // Re-evaluate profiles
        checkAndUpdateProfiles()
    }
    
    // MARK: - Monitoring
    
    @MainActor
    private func startMonitoring() {
        print("⏰ TimeProfileController: Starting monitoring")
        
        // Check immediately
        checkAndUpdateProfiles()
        
        // Check every 5 seconds for responsive activation/deactivation
        // This ensures profiles activate/deactivate within seconds of the scheduled time
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAndUpdateProfiles()
            }
        }
        
        print("⏰ Timer scheduled to check every 5 seconds")
    }
    
    private func stopMonitoring() {
        print("⏰ TimeProfileController: Stopping monitoring")
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    /// Check all time profiles and activate/deactivate as needed
    @MainActor
    func checkAndUpdateProfiles() {
        print("⏰ TimeProfileController: Checking profiles")
        
        let now = Date()
        let activeProfiles = appState.timeProfiles.filter { $0.isActiveAt(now) }
        
        print("   Found \(activeProfiles.count) active profiles")
        print("   Current blocking state: \(appState.isBlocking)")
        if let activeSource = screenTimeController.activeTagID {
            print("   Active source ID: \(activeSource)")
        }
        
        // If any tag is currently active, don't override with time profiles
        if appState.getActiveTag() != nil {
            print("   ⚠️ Tag is active, skipping time profile activation")
            return
        }
        
        // Check if we should activate a profile
        if let activeProfile = activeProfiles.first {
            // Check if this profile is already active
            if let currentSourceID = screenTimeController.activeTagID,
               currentSourceID == activeProfile.id {
                print("   ℹ️ Profile '\(activeProfile.name)' is already active, no action needed")
                return
            }
            
            print("   ✅ Activating profile: \(activeProfile.name)")
            Task {
                await activateProfile(activeProfile)
            }
        } else {
            // No active profiles - check if we need to deactivate
            if appState.isBlocking,
               let currentSourceID = screenTimeController.activeTagID,
               appState.timeProfiles.contains(where: { $0.id == currentSourceID }) {
                print("   ⏰ Time window ended, deactivating time profile")
                Task {
                    await deactivateTimeProfiles()
                }
            } else {
                print("   ℹ️ No active profiles and nothing to deactivate")
            }
        }
    }
    
    // MARK: - Activation/Deactivation
    
    @MainActor
    private func activateProfile(_ profile: TimeProfile) async {
        print("⏰ Activating time profile: \(profile.name)")
        
        // Check if profile has apps linked
        guard selectionManager.hasSelection(for: profile.id) else {
            print("⚠️ Profile has no apps/selections configured")
            return
        }
        
        // Get the selection
        guard let selection = selectionManager.getSelection(for: profile.id) else {
            print("⚠️ Could not retrieve selection")
            return
        }
        
        // Apply the shield
        let success = await screenTimeController.blockApps(selection: selection, sourceID: profile.id)
        
        if success {
            print("✅ Time profile activated successfully")
            
            // Update active profile in app state
            let blockingProfile = BlockingProfile(
                name: profile.name,
                blockedAppTokens: profile.linkedAppTokens,
                blockedCategoryTokens: profile.linkedCategoryTokens,
                isActive: true
            )
            appState.activeProfile = blockingProfile
            appState.setBlockingState(isActive: true)
        } else {
            print("❌ Failed to activate time profile")
        }
    }
    
    @MainActor
    private func deactivateTimeProfiles() async {
        print("⏰ Deactivating time profiles")
        
        // Deactivate blocking
        screenTimeController.unblockAll()
        
        // Clear active profile
        appState.activeProfile = nil
        appState.setBlockingState(isActive: false)
        
        // Force UI update by triggering objectWillChange
        appState.objectWillChange.send()
        
        print("✅ Time profile deactivated successfully")
    }
}
