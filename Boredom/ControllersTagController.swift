//
//  TagController.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls

@MainActor
class TagController {
    static let shared = TagController()
    
    private let appState = AppState.shared
    private let screenTimeController = ScreenTimeController.shared
    
    private init() {}
    
    func registerTag(name: String, identifier: String) -> NFCTag {
        let tag = NFCTag(
            name: name,
            tagIdentifier: identifier
        )
        appState.addTag(tag)
        return tag
    }
    
    func linkAppsToTag(tag: NFCTag, appTokens: Set<String>, categoryTokens: Set<String>) {
        var updatedTag = tag
        updatedTag.linkedAppTokens = appTokens
        updatedTag.linkedCategoryTokens = categoryTokens
        appState.updateTag(updatedTag)
    }
    
    func handleTagScan(identifier: String) {
        // Find tag with this identifier
        guard let index = appState.registeredTags.firstIndex(where: { $0.tagIdentifier == identifier }) else {
            print("Tag nicht registriert: \(identifier)")
            return
        }
        
        var tag = appState.registeredTags[index]
        
        // Toggle blocking state
        let newState = !tag.isActive
        tag.isActive = newState
        
        appState.updateTag(tag)
        appState.setBlockingState(isActive: newState)
        
        // Apply or remove restrictions
        if newState {
            // Create profile from tag and block
            let profile = BlockingProfile(
                name: tag.name,
                blockedAppTokens: tag.linkedAppTokens,
                blockedCategoryTokens: tag.linkedCategoryTokens,
                isActive: true
            )
            appState.activeProfile = profile
            screenTimeController.blockApps(profile: profile)
        } else {
            screenTimeController.unblockAll()
            appState.activeProfile = nil
        }
    }
    
    func deleteTag(tag: NFCTag) {
        // If this tag is currently active, unblock first
        if tag.isActive {
            screenTimeController.unblockAll()
            appState.setBlockingState(isActive: false)
        }
        appState.deleteTag(tag)
    }
}
