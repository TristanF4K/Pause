//
//  AppState.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isAuthorized: Bool = false
    @Published var registeredTags: [NFCTag] = []
    @Published var timeProfiles: [TimeProfile] = []
    @Published var activeProfile: BlockingProfile?
    @Published var isBlocking: Bool = false
    
    private let persistenceController = PersistenceController.shared
    
    private init() {
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
        isBlocking = ScreenTimeController.shared.isCurrentlyBlocking
        
        // Sync tag active states with actual blocking status
        syncTagStatesWithBlockingState()
    }
    
    /// Synchronizes tag isActive states with the actual blocking state from ScreenTimeController
    /// This ensures that after app restart, tags reflect the correct active/inactive state
    private func syncTagStatesWithBlockingState() {
        let screenTimeController = ScreenTimeController.shared
        let activeTagID = screenTimeController.activeTagID
        let isBlocking = screenTimeController.isCurrentlyBlocking
        
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
    }
    
    func checkAuthorizationStatus() async {
        let center = AuthorizationCenter.shared
        
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
            // Store that we have been authorized before
            UserDefaults.standard.set(true, forKey: "Pause.hasBeenAuthorized")
        case .denied:
            isAuthorized = false
            // Clear the flag if explicitly denied
            UserDefaults.standard.set(false, forKey: "Pause.hasBeenAuthorized")
        case .notDetermined:
            // Check if we've been authorized before
            let hasBeenAuthorized = UserDefaults.standard.bool(forKey: "Pause.hasBeenAuthorized")
            
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
        if let index = registeredTags.firstIndex(where: { $0.id == tag.id }) {
            registeredTags[index] = tag
            saveData()
        }
    }
    
    func deleteTag(_ tag: NFCTag) {
        registeredTags.removeAll { $0.id == tag.id }
        saveData()
    }
    
    func setBlockingState(isActive: Bool) {
        isBlocking = isActive
        activeProfile?.isActive = isActive
        saveData()
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
