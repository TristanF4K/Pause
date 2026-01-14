//
//  UserDefaultsKeys.swift
//  Pause
//
//  Created on 14.01.2026
//  Centralized UserDefaults key management with type-safety
//

import Foundation

// MARK: - UserDefaults Keys

/// Centralized management of all UserDefaults keys in the app
/// All keys use a consistent naming convention: "pause.category.property"
enum UserDefaultsKeys {
    // MARK: - Authorization
    
    /// Indicates if the user has been authorized for Screen Time API access
    static let hasBeenAuthorized = "pause.authorization.hasBeenAuthorized"
    
    /// Stores whether authorization is currently granted
    static let authorizationGranted = "pause.authorization.isGranted"
    
    /// Timestamp of the last successful authorization
    static let lastSuccessfulAuth = "pause.authorization.lastSuccessful"
    
    // MARK: - Blocking State
    
    /// Indicates if blocking is currently active
    static let blockingState = "pause.blocking.isActive"
    
    /// UUID string of the currently active tag or time profile
    static let activeSourceID = "pause.blocking.activeSourceID"
}

// MARK: - Type-Safe Property Wrapper

/// Property wrapper for type-safe UserDefaults access
///
/// Example usage:
/// ```swift
/// @UserDefault(key: UserDefaultsKeys.hasBeenAuthorized, defaultValue: false)
/// var hasBeenAuthorized: Bool
/// ```
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    let userDefaults: UserDefaults
    
    init(key: String, defaultValue: T, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }
    
    var wrappedValue: T {
        get {
            return userDefaults.object(forKey: key) as? T ?? defaultValue
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}

// MARK: - Convenience Extensions

extension UserDefaults {
    /// Type-safe getters and setters for app-specific values
    
    // MARK: Authorization
    
    var hasBeenAuthorized: Bool {
        get { bool(forKey: UserDefaultsKeys.hasBeenAuthorized) }
        set { set(newValue, forKey: UserDefaultsKeys.hasBeenAuthorized) }
    }
    
    var authorizationGranted: Bool {
        get { bool(forKey: UserDefaultsKeys.authorizationGranted) }
        set { set(newValue, forKey: UserDefaultsKeys.authorizationGranted) }
    }
    
    var lastSuccessfulAuth: Date? {
        get { object(forKey: UserDefaultsKeys.lastSuccessfulAuth) as? Date }
        set { set(newValue, forKey: UserDefaultsKeys.lastSuccessfulAuth) }
    }
    
    // MARK: Blocking State
    
    var blockingState: Bool {
        get { bool(forKey: UserDefaultsKeys.blockingState) }
        set { set(newValue, forKey: UserDefaultsKeys.blockingState) }
    }
    
    var activeSourceID: UUID? {
        get {
            guard let uuidString = string(forKey: UserDefaultsKeys.activeSourceID) else {
                return nil
            }
            return UUID(uuidString: uuidString)
        }
        set {
            set(newValue?.uuidString, forKey: UserDefaultsKeys.activeSourceID)
        }
    }
}
