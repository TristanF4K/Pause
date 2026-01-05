//
//  ScreenTimeController.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls
import ManagedSettings

enum ScreenTimeError: Error, LocalizedError {
    case authorizationDenied
    case notAuthorized
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Screen Time Zugriff wurde verweigert"
        case .notAuthorized:
            return "Nicht autorisiert"
        case .unknownError:
            return "Ein unbekannter Fehler ist aufgetreten"
        }
    }
}

@MainActor
class ScreenTimeController {
    static let shared = ScreenTimeController()
    
    private let store = ManagedSettingsStore()
    private let authCenter = AuthorizationCenter.shared
    
    private init() {}
    
    var authorizationStatus: AuthorizationStatus {
        authCenter.authorizationStatus
    }
    
    func requestAuthorization() async throws {
        do {
            try await authCenter.requestAuthorization(for: .individual)
        } catch {
            throw ScreenTimeError.authorizationDenied
        }
    }
    
    func blockApps(profile: BlockingProfile) {
        // Convert string tokens back to ApplicationToken and ActivityCategoryToken
        // Note: In production, you'd need proper token conversion
        // For now, we'll use the ManagedSettings API directly
        
        store.shield.applications = nil // Will be set when we have proper tokens
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    func unblockAll() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    func toggleBlocking(for tag: NFCTag) {
        if tag.isActive {
            // Currently blocking, so unblock
            unblockAll()
        } else {
            // Not blocking, so block
            // blockApps with tag's linked apps
            // This will be implemented when we properly handle ApplicationTokens
        }
    }
}
