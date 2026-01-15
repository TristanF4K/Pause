//
//  TagController.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls
import Combine
import OSLog

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
class TagController: ObservableObject {
    // Injected dependencies
    weak var appState: AppState?
    weak var screenTimeController: ScreenTimeController?
    weak var selectionManager: SelectionManager?
    weak var timeProfileController: TimeProfileController?
    
    // Public initializer for DI
    init(appState: AppState? = nil, 
         screenTimeController: ScreenTimeController? = nil,
         selectionManager: SelectionManager? = nil,
         timeProfileController: TimeProfileController? = nil ) {
        self.appState = appState
        self.screenTimeController = screenTimeController
        self.selectionManager = selectionManager
        self.timeProfileController = timeProfileController
    }
    
    // MARK: - Dependency Accessors
    
    private var state: AppState {
        guard let appState else {
            fatalError("AppState not injected - check PauseApp dependency setup")
        }
        return appState
    }
    
    private var screenTime: ScreenTimeController {
        guard let screenTimeController else {
            fatalError("ScreenTimeController not injected - check PauseApp dependency setup")
        }
        return screenTimeController
    }
    
    private var selection: SelectionManager {
        guard let selectionManager else {
            fatalError("SelectionManager not injected - check PauseApp dependency setup")
        }
        return selectionManager
    }
    
    private var timeProfile: TimeProfileController {  // ✅ ACCESSOR
        guard let timeProfileController else {
            fatalError("TimeProfileController not injected - check PauseApp dependency setup")
        }
        return timeProfileController
    }
    
    // MARK: - Tag Management
    func registerTag(name: String, identifier: String) -> NFCTag {
        let tag = NFCTag(
            name: name,
            tagIdentifier: identifier
        )
        state.addTag(tag)
        
        return tag
    }
    
    // MARK: - Modern API with FamilyActivitySelection
    
    func linkAppsToTag(tag: NFCTag, selection: FamilyActivitySelection) {
        // SECURITY: Cannot change app selection while tag is currently active
        if tag.isActive {
            AppLogger.tags.warning("🚫 Cannot change app selection while tag is active")
            return
        }
        
        // Store selection in SelectionManager
        self.selection.setSelection(selection, for: tag.id)
        
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
        
        state.updateTag(updatedTag)
        
        AppLogger.tags.info("✅ Linked \(selection.applicationTokens.count) apps and \(selection.categoryTokens.count) categories to tag '\(tag.name)'")
    }
    
    func handleTagScan(identifier: String) async -> TagScanResult {
        AppLogger.tags.info("🏷️ handleTagScan called with identifier: \(identifier)")
        
        // Normalize identifier for comparison
        let normalizedScannedId = identifier.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
        
        AppLogger.tags.debug("Normalized identifier: \(normalizedScannedId)")
        
        // Find tag with this identifier (with normalized comparison)
        guard let tag = state.registeredTags.first(where: { registeredTag in
            let normalizedRegisteredId = registeredTag.tagIdentifier.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: ":", with: "")
            return normalizedRegisteredId == normalizedScannedId
        }) else {
            AppLogger.tags.warning("⚠️ No tag found with this identifier")
            return .notRegistered
        }
        
        AppLogger.tags.info("✅ Found tag '\(tag.name)' (ID: \(tag.id))")
        
        // Check if tag has apps linked
        guard selection.hasSelection(for: tag.id) else {
            AppLogger.tags.warning("⚠️ Tag '\(tag.name)' has no apps/selections configured")
            return .noAppsLinked(tagName: tag.name)
        }
        
        let selectionInfo = selection.selectionInfo(for: tag.id)
        AppLogger.tags.debug("Selection: \(selectionInfo.apps) apps, \(selectionInfo.categories) categories")
        
        // SECURITY CHECK: Prevent activating a different tag when another is active
        if !tag.isActive && state.hasOtherActiveTag(than: tag.id) {
            if let activeTag = state.getActiveTag() {
                AppLogger.tags.warning("🚫 Cannot activate '\(tag.name)' - '\(activeTag.name)' is currently active")
                return .blockedByOtherTag(activeTagName: activeTag.name, attemptedTagName: tag.name)
            }
        }
        
        // SECURITY CHECK: Prevent activating tag when a time profile is active
        if !tag.isActive {
            let activeTimeProfiles = state.timeProfiles.filter { profile in
                profile.isCurrentlyBlocking(appState: state, screenTimeController: screenTime)
            }
            if let activeProfile = activeTimeProfiles.first {
                AppLogger.tags.warning("🚫 Cannot activate '\(tag.name)' - Time profile '\(activeProfile.name)' is currently active")
                return .blockedByTimeProfile(profileName: activeProfile.name, attemptedTagName: tag.name)
            }
        }
        
        // Remember the state before toggling
        let wasActiveBefore = tag.isActive
        
        // Toggle blocking state via ScreenTimeController
        AppLogger.tags.debug("Calling toggleBlocking for tag '\(tag.name)'...")
        let success = await screenTime.toggleBlocking(for: tag.id)
        
        guard success else {
            AppLogger.tags.error("❌ toggleBlocking failed for tag '\(tag.name)'")
            return .failed
        }
        
        AppLogger.tags.info("✅ toggleBlocking succeeded for tag '\(tag.name)'")
        
        // Update UI state
        var updatedTag = tag
        updatedTag.isActive = screenTime.isCurrentlyBlocking && screenTime.activeTagID == tag.id
        state.updateTag(updatedTag)
        state.setBlockingState(isActive: updatedTag.isActive)
        
        AppLogger.tags.debug("Updated tag state: isActive=\(updatedTag.isActive)")
        
        // Update active profile for UI
        if updatedTag.isActive {
            let profile = BlockingProfile(
                name: tag.name,
                blockedAppTokens: tag.linkedAppTokens,
                blockedCategoryTokens: tag.linkedCategoryTokens,
                isActive: true
            )
            state.activeProfile = profile
            AppLogger.tags.info("Set active profile: \(tag.name)")
        } else {
            state.activeProfile = nil
            AppLogger.tags.info("Cleared active profile")
            
            // IMPORTANT: After deactivating a tag, check if a time profile should take over
            AppLogger.tags.debug("Checking if time profile should activate now...")
            timeProfile.checkAndUpdateProfiles()
        }
        
        return .success(tag: updatedTag, wasActivated: !wasActiveBefore)
    }
    
    func deleteTag(tag: NFCTag) {
        // If this tag is currently active, unblock first
        if tag.isActive {
            screenTime.unblockAll()
            state.setBlockingState(isActive: false)
        }
        
        // Remove selection from memory
        selection.removeSelection(for: tag.id)
        
        // Remove tag from app state
        state.deleteTag(tag)
    }
    
    // MARK: - Legacy API (deprecated)
    
    @available(*, deprecated, message: "Use linkAppsToTag(tag:selection:) with FamilyActivitySelection instead")
    func linkAppsToTag(tag: NFCTag, appTokens: Set<String>, categoryTokens: Set<String>) {
        var updatedTag = tag
        updatedTag.linkedAppTokens = appTokens
        updatedTag.linkedCategoryTokens = categoryTokens
        state.updateTag(updatedTag)
    }
}
