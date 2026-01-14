//
//  TestDataController.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

#if DEBUG
import Foundation

/// Controller for managing test data in DEBUG builds
@MainActor
class TestDataController {
    static let shared = TestDataController()
    
    private init() {}
    
    // MARK: - Test Tag Creation
    
    /// Creates sample test tags for development and testing
    func createTestTags() {
        let appState = AppState.shared
        
        // Create 4 test tags with different profiles
        let testTags: [(name: String, emoji: String)] = [
            ("Arbeit", "💼"),
            ("Freizeit", "🎮"),
            ("Lernen", "📚"),
            ("Schlafen", "😴")
        ]
        
        for (index, tagData) in testTags.enumerated() {
            let tag = NFCTag(
                name: "\(tagData.emoji) \(tagData.name)",
                tagIdentifier: "TEST_TAG_\(index + 1)_\(UUID().uuidString.prefix(8))"
            )
            appState.registeredTags.append(tag)
        }
        
        // Save the changes
        PersistenceController.shared.saveTags(appState.registeredTags)
        
        print("✅ Test-Tags erstellt: \(testTags.count) Tags")
    }
    
    // MARK: - Test Tag Scanning
    
    /// Simulates scanning a tag without requiring a physical NFC chip
    /// - Parameter tagIdentifier: The identifier of the tag to simulate
    func simulateTagScan(tagIdentifier: String) {
        guard let tag = AppState.shared.registeredTags.first(where: { $0.tagIdentifier == tagIdentifier }) else {
            print("❌ Tag nicht gefunden: \(tagIdentifier)")
            return
        }
        
        print("🏷️ Simuliere Scan für Tag: \(tag.name)")
        
        // Use the TagController's handleTagScan method which toggles the state
        Task {
            let scanResult = await TagController.shared.handleTagScan(identifier: tagIdentifier)
            
            // Log the result
            switch scanResult {
            case .success(let scannedTag, let wasActivated):
                if wasActivated {
                    print("🔒 Tag wurde aktiviert: \(scannedTag.name)")
                } else {
                    print("🔓 Tag wurde deaktiviert: \(scannedTag.name)")
                }
            case .notRegistered:
                print("❌ Tag nicht registriert")
            case .noAppsLinked:
                print("⚠️ Tag hat keine Apps verknüpft")
            case .blockedByOtherTag(let activeTagName, _):
                print("🚫 Blockiert durch aktiven Tag: \(activeTagName)")
            case .blockedByTimeProfile(let profileName, _):
                print("🚫 Blockiert durch aktives Zeitprofil: \(profileName)")
            case .failed:
                print("❌ Blockierung fehlgeschlagen")
            }
        }
    }
    
    // MARK: - Cleanup
    
    /// Removes all registered tags
    func clearAllTags() {
        let appState = AppState.shared
        let screenTimeController = ScreenTimeController.shared
        
        // If any tag is currently blocking, unblock everything first
        if appState.isBlocking {
            screenTimeController.unblockAll()
            appState.setBlockingState(isActive: false)
            appState.activeProfile = nil
        }
        
        // Clear all tags
        appState.registeredTags.removeAll()
        PersistenceController.shared.saveTags([])
        
        print("🗑️ Alle Tags gelöscht")
    }
}
#endif
