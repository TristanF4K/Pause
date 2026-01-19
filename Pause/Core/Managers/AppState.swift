//
//  AppState.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls
import Combine
import OSLog

@MainActor
class AppState: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var registeredTags: [NFCTag] = []
    @Published var timeProfiles: [TimeProfile] = []
    @Published var activeProfile: BlockingProfile?
    @Published var isBlocking: Bool = false
    
    private let persistenceController = PersistenceController.shared
    
    // Reference to ScreenTimeController - will be injected
    weak var screenTimeController: ScreenTimeController?
    
    // Public initializer for DI
    init(screenTimeController: ScreenTimeController? = nil) {
        self.screenTimeController = screenTimeController
        loadData()
        // Check authorization status immediately
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    func loadData() {
        registeredTags = persistenceController.loadTags()
        timeProfiles = persistenceController.loadTimeProfiles()
        activeProfile = persistenceController.loadActiveProfile()
        
        // IMPORTANT: Sync blocking state from ScreenTimeController
        // This ensures the UI reflects the actual blocking state after app restart
        guard let controller = screenTimeController else {
            AppLogger.general.warning("⚠️ ScreenTimeController not injected, cannot sync blocking state")
            return
        }
        
        isBlocking = controller.isCurrentlyBlocking
        
        // Sync tag active states with actual blocking status
        syncTagStatesWithBlockingState()
    }
    
    /// Synchronizes tag isActive states with the actual blocking state from ScreenTimeController
    /// This ensures that after app restart, tags reflect the correct active/inactive state
    private func syncTagStatesWithBlockingState() {
        guard let controller = screenTimeController else {
            AppLogger.general.warning("⚠️ ScreenTimeController not injected, cannot sync tag states")
            return
        }
        
        let activeTagID = controller.activeTagID
        let isBlocking = controller.isCurrentlyBlocking
        
        // Update all tags: only the active tag should be marked as active
        for i in registeredTags.indices {
            let shouldBeActive = isBlocking && registeredTags[i].id == activeTagID
            
            if registeredTags[i].isActive != shouldBeActive {
                registeredTags[i].isActive = shouldBeActive
            }
            
            // If this tag is the active one, restore the active profile
            if shouldBeActive {
                let tag = registeredTags[i]
                activeProfile = BlockingProfile(
                    name: tag.name,
                    blockedAppTokens: tag.linkedAppTokens,
                    blockedCategoryTokens: tag.linkedCategoryTokens,
                    isActive: true
                )
            }
        }
        
        // If no tag is active, clear the active profile
        if !isBlocking {
            activeProfile = nil
        }
        
        // Save the corrected state
        if activeTagID != nil {
            saveData()
        }
    }
    
    func saveData() {
        persistenceController.saveTags(registeredTags)
        persistenceController.saveTimeProfiles(timeProfiles)
        if let activeProfile = activeProfile {
            persistenceController.saveActiveProfile(activeProfile)
        }
        AppLogger.general.debug("Data saved successfully")
    }
    
    func checkAuthorizationStatus() async {
        let center = AuthorizationCenter.shared
        
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
            // Store that we have been authorized before
            UserDefaults.standard.hasBeenAuthorized = true
        case .denied:
            isAuthorized = false
            // Clear the flag if explicitly denied
            UserDefaults.standard.hasBeenAuthorized = false
        case .notDetermined:
            // Check if we've been authorized before
            let hasBeenAuthorized = UserDefaults.standard.hasBeenAuthorized
            
            if hasBeenAuthorized {
                // We've been authorized before, probably just app restart
                // Don't show banner, authorization will work when needed
                isAuthorized = true
            } else {
                // First time, need authorization
                isAuthorized = false
            }
        @unknown default:
            isAuthorized = false
        }
    }
    
    func addTag(_ tag: NFCTag) {
        registeredTags.append(tag)
        saveData()
    }
    
    func updateTag(_ tag: NFCTag) {
        guard let index = registeredTags.firstIndex(where: { $0.id == tag.id }) else {
            AppLogger.general.warning("⚠️ Attempted to update non-existent tag: \(tag.name)")
            return
        }
        
        registeredTags[index] = tag
        saveData()
    }
    
    func deleteTag(_ tag: NFCTag) {
        registeredTags.removeAll { $0.id == tag.id }
        saveData()
    }
    
    func setBlockingState(isActive: Bool) {
        // Only update if state actually changed to prevent unnecessary saves
        guard isBlocking != isActive else {
            AppLogger.general.debug("Blocking state unchanged (\(isActive)), skipping update")
            return
        }
        
        isBlocking = isActive
        
        // Safely update activeProfile if it exists
        if var profile = activeProfile {
            profile.isActive = isActive
            activeProfile = profile
        }
        
        saveData()
        
        AppLogger.general.info("Blocking state updated to: \(isActive)")
    }
    
    /// Returns the currently active tag, if any
    func getActiveTag() -> NFCTag? {
        return registeredTags.first(where: { $0.isActive })
    }
    
    /// Checks if a different tag than the provided one is currently active
    func hasOtherActiveTag(than tagID: UUID) -> Bool {
        return registeredTags.contains(where: { $0.isActive && $0.id != tagID })
    }
    
    // MARK: - TimeProfile Management
    
    func addTimeProfile(_ profile: TimeProfile) {
        timeProfiles.append(profile)
        saveData()
    }
    
    func updateTimeProfile(_ profile: TimeProfile) {
        if let index = timeProfiles.firstIndex(where: { $0.id == profile.id }) {
            timeProfiles[index] = profile
            saveData()
        }
    }
    
    func deleteTimeProfile(_ profile: TimeProfile) {
        timeProfiles.removeAll { $0.id == profile.id }
        saveData()
    }
}
