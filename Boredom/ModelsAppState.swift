//
//  AppState.swift
//  FocusLock
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
    @Published var activeProfile: BlockingProfile?
    @Published var isBlocking: Bool = false
    
    private let persistenceController = PersistenceController.shared
    
    private init() {
        loadData()
    }
    
    func loadData() {
        registeredTags = persistenceController.loadTags()
        activeProfile = persistenceController.loadActiveProfile()
        isBlocking = activeProfile?.isActive ?? false
    }
    
    func saveData() {
        persistenceController.saveTags(registeredTags)
        if let activeProfile = activeProfile {
            persistenceController.saveActiveProfile(activeProfile)
        }
    }
    
    func checkAuthorizationStatus() async {
        let center = AuthorizationCenter.shared
        
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied, .notDetermined:
            isAuthorized = false
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
}
