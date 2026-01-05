//
//  SelectionManager.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls

/// Manager for FamilyActivitySelection that can't be directly persisted
@MainActor
class SelectionManager: ObservableObject {
    static let shared = SelectionManager()
    
    // Store selections in memory, keyed by tag ID
    @Published private(set) var tagSelections: [UUID: FamilyActivitySelection] = [:]
    
    private init() {}
    
    // MARK: - Selection Management
    
    func setSelection(_ selection: FamilyActivitySelection, for tagID: UUID) {
        tagSelections[tagID] = selection
    }
    
    func getSelection(for tagID: UUID) -> FamilyActivitySelection? {
        return tagSelections[tagID]
    }
    
    func removeSelection(for tagID: UUID) {
        tagSelections.removeValue(forKey: tagID)
    }
    
    func hasSelection(for tagID: UUID) -> Bool {
        guard let selection = tagSelections[tagID] else { return false }
        return !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }
    
    func clearAllSelections() {
        tagSelections.removeAll()
    }
    
    // MARK: - Selection Info
    
    func selectionInfo(for tagID: UUID) -> (apps: Int, categories: Int, webDomains: Int) {
        guard let selection = tagSelections[tagID] else {
            return (0, 0, 0)
        }
        
        return (
            selection.applicationTokens.count,
            selection.categoryTokens.count,
            selection.webDomainTokens.count
        )
    }
}
