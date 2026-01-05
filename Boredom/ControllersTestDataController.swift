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
                tagIdentifier: "TEST_TAG_\(index + 1)_\(UUID().uuidString.prefix(8))",
                name: "\(tagData.emoji) \(tagData.name)",
                registeredAt: Date()
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
        let appState = AppState.shared
        
        guard let tag = appState.registeredTags.first(where: { $0.tagIdentifier == tagIdentifier }) else {
            print("❌ Tag nicht gefunden: \(tagIdentifier)")
            return
        }
        
        print("🏷️ Simuliere Scan für Tag: \(tag.name)")
        
        // Toggle the tag's active state
        if tag.isActive {
            // Deactivate the tag
            TagController.shared.deactivateTag(tag)
            print("🔓 Tag deaktiviert: \(tag.name)")
        } else {
            // Activate the tag
            TagController.shared.activateTag(tag)
            print("🔒 Tag aktiviert: \(tag.name)")
        }
    }
    
    // MARK: - Cleanup
    
    /// Removes all registered tags
    func clearAllTags() {
        let appState = AppState.shared
        
        // Deactivate any active tags first
        if let activeTag = appState.registeredTags.first(where: { $0.isActive }) {
            TagController.shared.deactivateTag(activeTag)
        }
        
        // Clear all tags
        appState.registeredTags.removeAll()
        PersistenceController.shared.saveTags([])
        
        print("🗑️ Alle Tags gelöscht")
    }
}
#endif
