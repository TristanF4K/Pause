//
//  TimeProfileController.swift
//  Pause.
//
//  Created by Tristan Srebot on 14.01.26.
//

import Foundation
import FamilyControls
import Combine
import OSLog

class TimeProfileController: ObservableObject {
    // DEPRECATED: Use Environment-based injection instead
    // This will be removed in a future version
    static let shared = TimeProfileController()
    
    // Injected dependencies
    weak var appState: AppState?
    weak var screenTimeController: ScreenTimeController?
    weak var selectionManager: SelectionManager?
    
    /// Timer for checking time profiles
    private var checkTimer: Timer?
    
    /// Flag to track if monitoring is active
    private var isMonitoring = false
    
    // Public initializer for DI
    init(appState: AppState? = nil,
         screenTimeController: ScreenTimeController? = nil,
         selectionManager: SelectionManager? = nil) {
        self.appState = appState
        self.screenTimeController = screenTimeController
        self.selectionManager = selectionManager
        
        // Don't start monitoring immediately - wait until there are enabled profiles
        Task { @MainActor in
            startMonitoringIfNeeded()
        }
    }
    
    // Legacy private init for .shared
    private convenience init() {
        self.init(appState: nil, screenTimeController: nil, selectionManager: nil)
    }
    
    // MARK: - Dependency Accessors (with fallback to .shared)
    
    private var state: AppState {
        appState ?? AppState.shared
    }
    
    private var screenTime: ScreenTimeController {
        screenTimeController ?? ScreenTimeController.shared
    }
    
    private var selection: SelectionManager {
        selectionManager ?? SelectionManager.shared
    }
    
    deinit {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    // MARK: - Profile Management
    
    @MainActor
    func createProfile(name: String) -> TimeProfile {
        let profile = TimeProfile(name: name)
        state.addTimeProfile(profile)
        
        // Check if monitoring should start
        startMonitoringIfNeeded()
        
        return profile
    }
    
    @MainActor
    func linkAppsToProfile(profile: TimeProfile, selection: FamilyActivitySelection) {
        // Store selection in SelectionManager
        self.selection.setSelection(selection, for: profile.id)
        
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
        
        state.updateTimeProfile(updatedProfile)
    }
    
    @MainActor
    func updateSchedule(profile: TimeProfile, schedule: TimeSchedule) {
        var updatedProfile = profile
        updatedProfile.schedule = schedule
        state.updateTimeProfile(updatedProfile)
        
        // Re-evaluate if any profiles should be active now
        checkAndUpdateProfiles()
    }
    
    @MainActor
    func toggleEnabled(profile: TimeProfile) {
        // Check if a tag is currently active
        if state.getActiveTag() != nil && !profile.isEnabled {
            AppLogger.timeProfiles.warning("⚠️ Cannot enable time profile '\(profile.name)' - a tag is currently active")
            return
        }
        
        var updatedProfile = profile
        updatedProfile.isEnabled = !updatedProfile.isEnabled
        state.updateTimeProfile(updatedProfile)
        
        AppLogger.timeProfiles.info("\(updatedProfile.isEnabled ? "✅ Enabled" : "⏸️ Disabled") time profile '\(profile.name)'")
        
        // Re-evaluate profiles
        checkAndUpdateProfiles()
        
        // Start or stop monitoring based on whether any profiles are enabled
        startMonitoringIfNeeded()
    }
    
    @MainActor
    func deleteProfile(profile: TimeProfile) {
        // SECURITY: Cannot delete profile while it's currently blocking
        if profile.isCurrentlyBlocking(appState: state, screenTimeController: screenTime) {
            AppLogger.timeProfiles.warning("🚫 Cannot delete time profile '\(profile.name)' while it's currently active and blocking")
            return
        }
        
        // Remove selection from memory
        selection.removeSelection(for: profile.id)
        
        // Remove profile from app state
        state.deleteTimeProfile(profile)
        
        AppLogger.timeProfiles.info("🗑️ Deleted time profile '\(profile.name)'")
        
        // Re-evaluate profiles
        checkAndUpdateProfiles()
        
        // Stop monitoring if no enabled profiles remain
        stopMonitoringIfNotNeeded()
    }
    
    // MARK: - Monitoring
    
    /// Start monitoring only if there are enabled time profiles
    @MainActor
    private func startMonitoringIfNeeded() {
        // Don't start if already monitoring
        guard !isMonitoring else { return }
        
        // Only start if there are enabled profiles
        let hasEnabledProfiles = state.timeProfiles.contains(where: { $0.isEnabled })
        guard hasEnabledProfiles else {
            AppLogger.timeProfiles.debug("⏰ No enabled time profiles, skipping monitoring")
            return
        }
        
        let enabledCount = state.timeProfiles.filter { $0.isEnabled }.count
        AppLogger.timeProfiles.info("⏰ Starting monitoring (\(enabledCount) enabled profile\(enabledCount == 1 ? "" : "s"))")
        startMonitoring()
        isMonitoring = true
    }
    
    /// Stop monitoring if there are no enabled time profiles
    @MainActor
    private func stopMonitoringIfNotNeeded() {
        // Don't stop if not monitoring
        guard isMonitoring else { return }
        
        // Only stop if there are no enabled profiles
        let hasEnabledProfiles = state.timeProfiles.contains(where: { $0.isEnabled })
        guard !hasEnabledProfiles else { return }
        
        AppLogger.timeProfiles.info("⏰ No enabled time profiles remaining, stopping monitoring")
        stopMonitoring()
        isMonitoring = false
    }
    
    @MainActor
    private func startMonitoring() {
        // Check immediately
        checkAndUpdateProfiles()
        
        // Check every 5 seconds for responsive activation/deactivation
        // This ensures profiles activate/deactivate within seconds of the scheduled time
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAndUpdateProfiles()
            }
        }
        
        AppLogger.timeProfiles.debug("Timer scheduled to check every 5 seconds")
    }
    
    @MainActor
    private func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
        AppLogger.timeProfiles.debug("Monitoring stopped")
    }
    
    /// Check all time profiles and activate/deactivate as needed
    @MainActor
    func checkAndUpdateProfiles() {
        AppLogger.timeProfiles.debug("⏰ Checking profiles")
        
        let now = Date()
        let activeProfiles = self.state.timeProfiles.filter { $0.isActiveAt(now) }
        
        AppLogger.timeProfiles.debug("Found \(activeProfiles.count) active profile(s), current blocking state: \(self.state.isBlocking)")
        if let activeSource = self.screenTime.activeTagID {
            AppLogger.timeProfiles.debug("Active source ID: \(activeSource)")
        }
        
        // If any tag is currently active, don't override with time profiles
        if self.state.getActiveTag() != nil {
            AppLogger.timeProfiles.debug("⚠️ Tag is active, skipping time profile activation")
            return
        }
        
        // Check if we should activate a profile
        if let activeProfile = activeProfiles.first {
            // Check if this profile is already active
            if let currentSourceID = self.screenTime.activeTagID,
               currentSourceID == activeProfile.id {
                AppLogger.timeProfiles.debug("ℹ️ Profile '\(activeProfile.name)' is already active, no action needed")
                return
            }
            
            AppLogger.timeProfiles.info("✅ Activating profile: \(activeProfile.name)")
            Task {
                await self.activateProfile(activeProfile)
            }
        } else {
            // No active profiles - check if we need to deactivate
            if self.state.isBlocking,
               let currentSourceID = self.screenTime.activeTagID,
               self.state.timeProfiles.contains(where: { $0.id == currentSourceID }) {
                AppLogger.timeProfiles.info("⏰ Time window ended, deactivating time profile")
                Task {
                    await self.deactivateTimeProfiles()
                }
            } else {
                AppLogger.timeProfiles.debug("ℹ️ No active profiles and nothing to deactivate")
            }
        }
    }
    
    // MARK: - Activation/Deactivation
    
    @MainActor
    private func activateProfile(_ profile: TimeProfile) async {
        AppLogger.timeProfiles.info("⏰ Activating time profile: \(profile.name)")
        
        // Check if profile has apps linked
        guard selection.hasSelection(for: profile.id) else {
            AppLogger.timeProfiles.warning("⚠️ Profile '\(profile.name)' has no apps/selections configured")
            return
        }
        
        // Get the selection
        guard let profileSelection = selection.getSelection(for: profile.id) else {
            AppLogger.timeProfiles.error("❌ Could not retrieve selection for profile '\(profile.name)'")
            return
        }
        
        // Apply the shield
        let success = await screenTime.blockApps(selection: profileSelection, sourceID: profile.id)
        
        if success {
            AppLogger.timeProfiles.info("✅ Time profile '\(profile.name)' activated successfully")
            
            // Update active profile in app state
            let blockingProfile = BlockingProfile(
                name: profile.name,
                blockedAppTokens: profile.linkedAppTokens,
                blockedCategoryTokens: profile.linkedCategoryTokens,
                isActive: true
            )
            state.activeProfile = blockingProfile
            state.setBlockingState(isActive: true)
        } else {
            AppLogger.timeProfiles.error("❌ Failed to activate time profile '\(profile.name)'")
        }
    }
    
    @MainActor
    private func deactivateTimeProfiles() async {
        AppLogger.timeProfiles.info("⏰ Deactivating time profiles")
        
        // Deactivate blocking
        screenTime.unblockAll()
        
        // Clear active profile
        state.activeProfile = nil
        state.setBlockingState(isActive: false)
        
        // Force UI update by triggering objectWillChange
        state.objectWillChange.send()
        
        AppLogger.timeProfiles.info("✅ Time profile deactivated successfully")
    }
}
