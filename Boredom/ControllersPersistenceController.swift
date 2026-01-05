//
//  PersistenceController.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    private let tagsKey = "focuslock.tags"
    private let activeProfileKey = "focuslock.activeProfile"
    
    private init() {}
    
    // MARK: - Tags
    
    func saveTags(_ tags: [NFCTag]) {
        if let encoded = try? JSONEncoder().encode(tags) {
            UserDefaults.standard.set(encoded, forKey: tagsKey)
        }
    }
    
    func loadTags() -> [NFCTag] {
        guard let data = UserDefaults.standard.data(forKey: tagsKey),
              let tags = try? JSONDecoder().decode([NFCTag].self, from: data) else {
            return []
        }
        return tags
    }
    
    // MARK: - Active Profile
    
    func saveActiveProfile(_ profile: BlockingProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: activeProfileKey)
        }
    }
    
    func loadActiveProfile() -> BlockingProfile? {
        guard let data = UserDefaults.standard.data(forKey: activeProfileKey),
              let profile = try? JSONDecoder().decode(BlockingProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    func clearActiveProfile() {
        UserDefaults.standard.removeObject(forKey: activeProfileKey)
    }
}
