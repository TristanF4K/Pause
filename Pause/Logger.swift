//
//  Logger.swift
//  Pause.
//
//  Created by Tristan Srebot on 14.01.26.
//

import Foundation
import OSLog

/// Centralized logging system using OSLog for performance and system integration
/// 
/// Usage:
/// ```swift
/// AppLogger.general.info("App started")
/// AppLogger.screenTime.debug("Checking authorization status")
/// AppLogger.nfc.error("Failed to scan tag: \(error)")
/// ```
///
/// Benefits:
/// - Performance optimized (OSLog is very efficient)
/// - Integrated with Console.app
/// - Automatic log levels in production
/// - Filterable by subsystem and category
enum AppLogger {
    
    // MARK: - Subsystem
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.pause.app"
    
    // MARK: - Loggers by Category
    
    /// General app lifecycle and state changes
    static let general = Logger(subsystem: subsystem, category: "General")
    
    /// Screen Time API interactions (authorization, blocking, unblocking)
    static let screenTime = Logger(subsystem: subsystem, category: "ScreenTime")
    
    /// NFC tag scanning and management
    static let nfc = Logger(subsystem: subsystem, category: "NFC")
    
    /// Tag management (CRUD operations, activation/deactivation)
    static let tags = Logger(subsystem: subsystem, category: "Tags")
    
    /// Time profile management and scheduling
    static let timeProfiles = Logger(subsystem: subsystem, category: "TimeProfiles")
    
    /// App selection and FamilyActivitySelection management
    static let selection = Logger(subsystem: subsystem, category: "Selection")
    
    /// Data persistence (UserDefaults, JSON storage)
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    
    /// UI-related logging
    static let ui = Logger(subsystem: subsystem, category: "UI")
}

// MARK: - Helper Extensions

extension Logger {
    
    /// Log with emoji prefix for better readability in development
    /// - Parameters:
    ///   - level: Log level (info, debug, error, fault)
    ///   - emoji: Emoji prefix (e.g., "✅", "⚠️", "❌")
    ///   - message: Log message
    func log(_ level: OSLogType = .default, emoji: String = "", _ message: String) {
        let formattedMessage = emoji.isEmpty ? message : "\(emoji) \(message)"
        self.log(level: level, "\(formattedMessage, privacy: .public)")
    }
}

// MARK: - Migration Helper (for gradual migration from print statements)

#if DEBUG
/// Temporary helper to gradually migrate from print() to Logger
/// This can be used during migration and removed later
func logDebug(_ message: String, category: String = "Debug") {
    print("[\(category)] \(message)")
}
#endif
