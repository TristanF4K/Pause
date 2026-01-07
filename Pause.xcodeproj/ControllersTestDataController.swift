//
//  TestDataController.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls

/// Controller für Test-Daten während der Entwicklung
@MainActor
class TestDataController {
    static let shared = TestDataController()
    
    private let appState = AppState.shared
    private let tagController = TagController.shared
    
    private init() {}
    
    /// Erstellt Test-Tags ohne NFC-Scan
    func createTestTags() {
        // Überprüfe ob bereits Test-Tags existieren
        guard appState.registeredTags.isEmpty else {
            print("⚠️ Tags bereits vorhanden. Lösche erst alle Tags, um neue Test-Daten zu erstellen.")
            return
        }
        
        let testTags: [(name: String, identifier: String)] = [
            ("🏢 Büro", "TEST-OFFICE-001"),
            ("🏠 Zuhause", "TEST-HOME-002"),
            ("🎯 Fokus-Zeit", "TEST-FOCUS-003"),
            ("😴 Schlafzimmer", "TEST-SLEEP-004")
        ]
        
        for (name, identifier) in testTags {
            let tag = tagController.registerTag(name: name, identifier: identifier)
            print("✓ Test-Tag erstellt: \(name) (\(identifier))")
        }
        
        print("✅ \(testTags.count) Test-Tags erstellt")
    }
    
    /// Simuliert einen NFC-Scan mit einem bestimmten Tag
    func simulateTagScan(tagIdentifier: String) {
        guard let tag = appState.registeredTags.first(where: { $0.tagIdentifier == tagIdentifier }) else {
            print("⚠️ Tag nicht gefunden: \(tagIdentifier)")
            return
        }
        
        print("🔄 Simuliere Scan von: \(tag.name)")
        tagController.handleTagScan(identifier: tagIdentifier)
        
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Löscht alle Test-Tags
    func clearAllTags() {
        let allTags = appState.registeredTags
        for tag in allTags {
            tagController.deleteTag(tag: tag)
        }
        print("✓ Alle Tags gelöscht (\(allTags.count))")
    }
    
    /// Gibt alle registrierten Tags aus
    func listAllTags() -> [NFCTag] {
        return appState.registeredTags
    }
    
    /// Überprüft ob Test-Modus aktiv ist (identifiziert anhand von TEST- Prefix)
    var isTestMode: Bool {
        return appState.registeredTags.contains(where: { $0.tagIdentifier.hasPrefix("TEST-") })
    }
}
