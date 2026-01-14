//
//  TagController.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls

/// Result of a tag scan operation
enum TagScanResult {
    case success(tag: NFCTag, wasActivated: Bool)
    case notRegistered
    case noAppsLinked(tagName: String)
    case blockedByOtherTag(activeTagName: String, attemptedTagName: String)
    case blockedByTimeProfile(profileName: String, attemptedTagName: String)
    case failed
    
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

@MainActor
class TagController {
    static let shared = TagController()
    
    private let appState = AppState.shared
    private let screenTimeController = ScreenTimeController.shared
    private let selectionManager = SelectionManager.shared
    
    private init() {}
    
    func registerTag(name: String, identifier: String) -> NFCTag {
        let tag = NFCTag(
            name: name,
            tagIdentifier: identifier
        )
        appState.addTag(tag)
        
        return tag
    }
    
    // MARK: - Modern API with FamilyActivitySelection
    
    func linkAppsToTag(tag: NFCTag, selection: FamilyActivitySelection) {
        // SECURITY: Cannot change app selection while tag is currently active
        if tag.isActive {
            print("🚫 Cannot change app selection while tag is active")
            return
        }
        
        // Store selection in SelectionManager
        selectionManager.setSelection(selection, for: tag.id)
        
        // Update tag metadata for UI purposes
        var updatedTag = tag
        
        // Encode tokens as base64 strings for storage
        let encoder = JSONEncoder()
        updatedTag.linkedAppTokens = Set(selection.applicationTokens.compactMap { token in
            try? encoder.encode(token).base64EncodedString()
        })
        updatedTag.linkedCategoryTokens = Set(selection.categoryTokens.compactMap { token in
            try? encoder.encode(token).base64EncodedString()
        })
        
        appState.updateTag(updatedTag)
    }
    
    func handleTagScan(identifier: String) async -> TagScanResult {
        print("🏷️ TagController: handleTagScan called with identifier: \(identifier)")
        
        // Normalize identifier for comparison
        let normalizedScannedId = identifier.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
        
        print("   Normalized: \(normalizedScannedId)")
        
        // Find tag with this identifier (with normalized comparison)
        guard let tag = appState.registeredTags.first(where: { registeredTag in
            let normalizedRegisteredId = registeredTag.tagIdentifier.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: ":", with: "")
            return normalizedRegisteredId == normalizedScannedId
        }) else {
            print("⚠️ TagController: No tag found with this identifier")
            return .notRegistered
        }
        
        print("✅ TagController: Found tag '\(tag.name)' (ID: \(tag.id))")
        
        // Check if tag has apps linked
        guard selectionManager.hasSelection(for: tag.id) else {
            print("⚠️ TagController: Tag has no apps/selections configured")
            return .noAppsLinked(tagName: tag.name)
        }
        
        let selectionInfo = selectionManager.selectionInfo(for: tag.id)
        print("   Selection: \(selectionInfo.apps) apps, \(selectionInfo.categories) categories")
        
        // SECURITY CHECK: Prevent activating a different tag when another is active
        if !tag.isActive && appState.hasOtherActiveTag(than: tag.id) {
            if let activeTag = appState.getActiveTag() {
                print("🚫 TagController: Cannot activate '\(tag.name)' - '\(activeTag.name)' is currently active")
                return .blockedByOtherTag(activeTagName: activeTag.name, attemptedTagName: tag.name)
            }
        }
        
        // SECURITY CHECK: Prevent activating tag when a time profile is active
        if !tag.isActive {
            let activeTimeProfiles = appState.timeProfiles.filter { profile in
                profile.isCurrentlyBlocking(appState: appState, screenTimeController: screenTimeController)
            }
            if let activeProfile = activeTimeProfiles.first {
                print("🚫 TagController: Cannot activate '\(tag.name)' - Time profile '\(activeProfile.name)' is currently active")
                return .blockedByTimeProfile(profileName: activeProfile.name, attemptedTagName: tag.name)
            }
        }
        
        // Remember the state before toggling
        let wasActiveBefore = tag.isActive
        
        // Toggle blocking state via ScreenTimeController
        print("   Calling toggleBlocking...")
        let success = await screenTimeController.toggleBlocking(for: tag.id)
        
        guard success else {
            print("⚠️ TagController: toggleBlocking failed")
            return .failed
        }
        
        print("✅ TagController: toggleBlocking succeeded")
        
        // Update UI state
        var updatedTag = tag
        updatedTag.isActive = screenTimeController.isCurrentlyBlocking && screenTimeController.activeTagID == tag.id
        appState.updateTag(updatedTag)
        appState.setBlockingState(isActive: updatedTag.isActive)
        
        print("   Updated tag state: isActive=\(updatedTag.isActive)")
        
        // Update active profile for UI
        if updatedTag.isActive {
            let profile = BlockingProfile(
                name: tag.name,
                blockedAppTokens: tag.linkedAppTokens,
                blockedCategoryTokens: tag.linkedCategoryTokens,
                isActive: true
            )
            appState.activeProfile = profile
            print("   Set active profile: \(tag.name)")
        } else {
            appState.activeProfile = nil
            print("   Cleared active profile")
            
            // IMPORTANT: After deactivating a tag, check if a time profile should take over
            print("   Checking if time profile should activate now...")
            TimeProfileController.shared.checkAndUpdateProfiles()
        }
        
        return .success(tag: updatedTag, wasActivated: !wasActiveBefore)
    }
    
    func deleteTag(tag: NFCTag) {
        // If this tag is currently active, unblock first
        if tag.isActive {
            screenTimeController.unblockAll()
            appState.setBlockingState(isActive: false)
        }
        
        // Remove selection from memory
        selectionManager.removeSelection(for: tag.id)
        
        // Remove tag from app state
        appState.deleteTag(tag)
    }
    
    // MARK: - Legacy API (deprecated)
    
    @available(*, deprecated, message: "Use linkAppsToTag(tag:selection:) with FamilyActivitySelection instead")
    func linkAppsToTag(tag: NFCTag, appTokens: Set<String>, categoryTokens: Set<String>) {
        var updatedTag = tag
        updatedTag.linkedAppTokens = appTokens
        updatedTag.linkedCategoryTokens = categoryTokens
        appState.updateTag(updatedTag)
    }
}
