//
//  SelectionManager.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI
import Combine
@preconcurrency import FamilyControls
import ManagedSettings

// MARK: - ManagedSettingsStore Extension for Complete Clearing

extension ManagedSettingsStore {
    /// Clears ALL possible settings from this store
    func clearAllSettings() {
        // Shield settings
        self.shield.applications = nil
        self.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.none
        self.shield.webDomains = nil
        self.shield.webDomainCategories = nil
        
        // Application settings
        self.application.denyAppInstallation = false
        self.application.denyAppRemoval = false
        
        // Date and Time
        self.dateAndTime.requireAutomaticDateAndTime = false
        
        // Game Center
        self.gameCenter.denyMultiplayerGaming = false
        
        // Media
        self.media.denyExplicitContent = false
        
        // Passcode
        self.passcode.lockPasscode = false
        
        // Cellular
        self.cellular.lockAppCellularData = false
        
        // Account
        self.account.lockAccounts = false
    }
}

// MARK: - Serializable Selection Storage

/// A codable wrapper for FamilyActivitySelection tokens
/// This allows us to save selections WITHOUT activating ManagedSettingsStore
struct SerializableSelection: Codable {
    let applicationTokensData: [Data]
    let categoryTokensData: [Data]
    let webDomainTokensData: [Data]
    
    init(from selection: FamilyActivitySelection) {
        let encoder = JSONEncoder()
        
        self.applicationTokensData = selection.applicationTokens.compactMap { token in
            try? encoder.encode(token)
        }
        
        self.categoryTokensData = selection.categoryTokens.compactMap { token in
            try? encoder.encode(token)
        }
        
        self.webDomainTokensData = selection.webDomainTokens.compactMap { token in
            try? encoder.encode(token)
        }
    }
    
    func toFamilyActivitySelection() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        let decoder = JSONDecoder()
        
        selection.applicationTokens = Set(applicationTokensData.compactMap { data in
            try? decoder.decode(ApplicationToken.self, from: data)
        })
        
        selection.categoryTokens = Set(categoryTokensData.compactMap { data in
            try? decoder.decode(ActivityCategoryToken.self, from: data)
        })
        
        selection.webDomainTokens = Set(webDomainTokensData.compactMap { data in
            try? decoder.decode(WebDomainToken.self, from: data)
        })
        
        return selection
    }
}

/// Manages FamilyActivitySelection per tag
/// Key insight: Selections are stored in UserDefaults (NOT in ManagedSettingsStore)
/// Only the ACTIVE tag's selection is copied to the blockingStore
/// This prevents automatic blocking when just configuring tags
@MainActor
class SelectionManager: ObservableObject {
    static let shared = SelectionManager()
    
    // Track which tags have selections configured
    @Published private(set) var configuredTags: Set<UUID> = []
    
    // Track which tag is currently active (blocking)
    @Published private(set) var activeTagID: UUID? = nil
    
    // Store selections in memory (backed by UserDefaults)
    private var tagSelections: [UUID: FamilyActivitySelection] = [:]
    
    // Main blocking store - this is the ONLY store that actually blocks apps
    private let blockingStore = ManagedSettingsStore(named: .init("active_blocking"))
    
    // UserDefaults keys for persistence
    private let selectionsKey = "pause.tag_selections"
    private let configuredTagsKey = "pause.configured_tags"
    private let activeTagIDKey = "pause.active_tag_id"
    
    private init() {
        // CRITICAL: Always start with COMPLETELY clean blocking state
        blockingStore.clearAllSettings()
        
        // MIGRATION: Check for old-style tag stores and migrate them
        migrateOldTagStores()
        
        // Restore saved selections from UserDefaults
        restoreSelectionsFromUserDefaults()
        
        // Optionally restore active blocking state (only if user had an active session)
        restoreActiveState()
    }
    
    // MARK: - Migration from old architecture
    
    private func migrateOldTagStores() {
        // Check if we have old-style configured tags
        guard let oldTagIDStrings = UserDefaults.standard.stringArray(forKey: configuredTagsKey),
              !oldTagIDStrings.isEmpty else {
            return
        }
        
        for tagIDString in oldTagIDStrings {
            guard let tagID = UUID(uuidString: tagIDString) else { continue }
            
            // Try to read from old ManagedSettingsStore
            let storeName = ManagedSettingsStore.Name("tag_\(tagID.uuidString)")
            let oldStore = ManagedSettingsStore(named: storeName)
            
            // Extract selection from old store
            var selection = FamilyActivitySelection()
            
            if let apps = oldStore.shield.applications, !apps.isEmpty {
                selection.applicationTokens = apps
            }
            
            if case let .specific(categories, except: _) = oldStore.shield.applicationCategories, !categories.isEmpty {
                selection.categoryTokens = categories
            }
            
            if let webDomains = oldStore.shield.webDomains, !webDomains.isEmpty {
                selection.webDomainTokens = webDomains
            }
            
            // Only migrate if we found content
            if !selection.applicationTokens.isEmpty || 
               !selection.categoryTokens.isEmpty || 
               !selection.webDomainTokens.isEmpty {
                
                // Store in new format (memory)
                tagSelections[tagID] = selection
                configuredTags.insert(tagID)
                
                // Clear the old store to prevent automatic blocking
                oldStore.clearAllSettings()
            }
        }
        
        if !tagSelections.isEmpty {
            // Save migrated data in new format
            saveSelectionsToUserDefaults()
        }
    }
    
    // MARK: - Persistence
    
    private func restoreSelectionsFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: selectionsKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let savedSelections = try decoder.decode([String: SerializableSelection].self, from: data)
            
            for (tagIDString, serializableSelection) in savedSelections {
                guard let tagID = UUID(uuidString: tagIDString) else { continue }
                
                let selection = serializableSelection.toFamilyActivitySelection()
                
                // Store in memory
                tagSelections[tagID] = selection
                configuredTags.insert(tagID)
            }
        } catch {
            // Silently fail - first launch or corrupted data
        }
    }
    
    private func saveSelectionsToUserDefaults() {
        var serializableSelections: [String: SerializableSelection] = [:]
        
        for (tagID, selection) in tagSelections {
            serializableSelections[tagID.uuidString] = SerializableSelection(from: selection)
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(serializableSelections)
            UserDefaults.standard.set(data, forKey: selectionsKey)
            
            // Also save configured tags list
            let tagIDStrings = Array(configuredTags.map { $0.uuidString })
            UserDefaults.standard.set(tagIDStrings, forKey: configuredTagsKey)
        } catch {
            // Silently fail
        }
    }
    
    private func restoreActiveState() {
        // Check if we had an active tag when app was closed
        if let activeTagIDString = UserDefaults.standard.string(forKey: activeTagIDKey),
           let tagID = UUID(uuidString: activeTagIDString),
           configuredTags.contains(tagID) {
            
            // Restore the blocking state for this tag
            activateBlocking(for: tagID)
        } else {
            // No active tag found or tag no longer exists - ensure everything is clean
            deactivateBlocking()
        }
    }
    
    // MARK: - Selection Management
    
    /// Sets the app selection for a specific tag
    /// This stores the selection in UserDefaults (NOT in ManagedSettingsStore)
    /// Apps will NOT be blocked until activateBlocking(for:) is called
    func setSelection(_ selection: FamilyActivitySelection, for tagID: UUID) {
        // Store in memory
        tagSelections[tagID] = selection
        
        // Mark this tag as configured
        configuredTags.insert(tagID)
        
        // Save to UserDefaults (NOT to ManagedSettingsStore!)
        saveSelectionsToUserDefaults()
    }
    
    /// Gets the current selection for a tag from memory
    func getSelection(for tagID: UUID) -> FamilyActivitySelection? {
        return tagSelections[tagID]
    }
    
    /// Removes a tag's selection
    func removeSelection(for tagID: UUID) {
        // Remove from memory
        tagSelections.removeValue(forKey: tagID)
        configuredTags.remove(tagID)
        
        // Save to UserDefaults
        saveSelectionsToUserDefaults()
        
        // If this was the active tag, deactivate blocking
        if activeTagID == tagID {
            deactivateBlocking()
        }
    }
    
    func hasSelection(for tagID: UUID) -> Bool {
        return tagSelections[tagID] != nil
    }
    
    // MARK: - Blocking Operations
    
    /// Activates blocking by COPYING the tag's selection to the blocking store
    /// This is the ONLY time we write to ManagedSettingsStore
    func activateBlocking(for tagID: UUID) {
        guard let selection = getSelection(for: tagID) else {
            print("⚠️ SelectionManager: No selection found for tag \(tagID)")
            return
        }
        
        print("✅ SelectionManager: Activating blocking for tag \(tagID)")
        print("   - Apps: \(selection.applicationTokens.count)")
        print("   - Categories: \(selection.categoryTokens.count)")
        print("   - Web Domains: \(selection.webDomainTokens.count)")
        
        // Copy the selection to the blocking store (this activates the restrictions)
        blockingStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        
        if !selection.categoryTokens.isEmpty {
            blockingStore.shield.applicationCategories = .specific(selection.categoryTokens, except: Set())
        } else {
            blockingStore.shield.applicationCategories = .specific([], except: [])
        }
        
        blockingStore.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        
        activeTagID = tagID
        UserDefaults.standard.set(tagID.uuidString, forKey: activeTagIDKey)
        
        print("✅ SelectionManager: Blocking activated successfully")
    }
    
    /// Deactivates blocking by clearing the blocking store
    func deactivateBlocking() {
        print("🔓 SelectionManager: Deactivating blocking")
        
        // Clear the blocking store (this removes all restrictions)
        blockingStore.clearAllSettings()
        
        activeTagID = nil
        UserDefaults.standard.removeObject(forKey: activeTagIDKey)
        
        print("✅ SelectionManager: Blocking deactivated successfully")
    }
    
    // MARK: - Helper Methods
    
    func selectionInfo(for tagID: UUID) -> (apps: Int, categories: Int, webDomains: Int) {
        guard let selection = getSelection(for: tagID) else {
            return (0, 0, 0)
        }
        
        return (
            selection.applicationTokens.count,
            selection.categoryTokens.count,
            selection.webDomainTokens.count
        )
    }
    
    func clearAllSelections() {
        // Clear memory
        tagSelections.removeAll()
        configuredTags.removeAll()
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: selectionsKey)
        UserDefaults.standard.removeObject(forKey: configuredTagsKey)
        
        // Clear blocking
        deactivateBlocking()
    }
    
    func debugPrintSelections() {
        print("=== SelectionManager Debug ===")
        print("Configured tags: \(configuredTags.count)")
        print("Currently blocking: \(activeTagID?.uuidString ?? "none")")
        
        // Check blocking store status
        let blockingHasApps = blockingStore.shield.applications?.isEmpty == false
        let blockingHasCategories: Bool = {
            if case .specific(let cats, except: _) = blockingStore.shield.applicationCategories {
                return !cats.isEmpty
            }
            return false
        }()
        let blockingHasWebDomains = blockingStore.shield.webDomains?.isEmpty == false
        
        print("Blocking store active: apps=\(blockingHasApps), categories=\(blockingHasCategories), web=\(blockingHasWebDomains)")
        
        for tagID in configuredTags {
            let info = selectionInfo(for: tagID)
            print("  Tag \(tagID): \(info.apps) apps, \(info.categories) categories, \(info.webDomains) web domains")
        }
        print("=============================")
    }
}
