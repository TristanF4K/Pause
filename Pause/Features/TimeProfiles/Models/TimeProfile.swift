//
//  TimeProfile.swift
//  Pause.
//
//  Created by Tristan Srebot on 14.01.26.
//

import Foundation
import FamilyControls

/// A time-based blocking profile that activates automatically on specific days and times
struct TimeProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var linkedAppTokens: Set<String> // Stored as strings for Codable
    var linkedCategoryTokens: Set<String> // Stored as strings for Codable
    var schedule: TimeSchedule
    var isEnabled: Bool // Whether the profile is enabled (can be toggled on/off)
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        linkedAppTokens: Set<String> = [],
        linkedCategoryTokens: Set<String> = [],
        schedule: TimeSchedule = TimeSchedule(),
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.linkedAppTokens = linkedAppTokens
        self.linkedCategoryTokens = linkedCategoryTokens
        self.schedule = schedule
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
    
    /// Check if this profile should be active at the given date/time (based on schedule only)
    func isActiveAt(_ date: Date) -> Bool {
        guard isEnabled else { return false }
        return schedule.isActiveAt(date)
    }
    
    /// Check if this profile should be active right now (based on schedule only)
    var shouldBeActive: Bool {
        isActiveAt(Date())
    }
    
    /// Check if this profile is ACTUALLY blocking right now (checks real blocking state)
    func isCurrentlyBlocking(appState: AppState, screenTimeController: ScreenTimeController) -> Bool {
        // Must be in the right time window
        guard shouldBeActive else { return false }
        
        // Must be the active source
        guard let activeSourceID = screenTimeController.activeTagID,
              activeSourceID == self.id else {
            return false
        }
        
        // Blocking must be active
        return appState.isBlocking
    }
}

/// Schedule configuration for a time profile
struct TimeSchedule: Codable, Hashable {
    var selectedWeekdays: Set<Weekday>
    var startTime: TimeOfDay
    var endTime: TimeOfDay
    
    init(
        selectedWeekdays: Set<Weekday> = [],
        startTime: TimeOfDay = TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay = TimeOfDay(hour: 17, minute: 0)
    ) {
        self.selectedWeekdays = selectedWeekdays
        self.startTime = startTime
        self.endTime = endTime
    }
    
    /// Check if the schedule is active at the given date/time
    func isActiveAt(_ date: Date) -> Bool {
        let calendar = Calendar.current
        
        // Check if today is one of the selected weekdays
        let weekdayComponent = calendar.component(.weekday, from: date)
        guard let currentWeekday = Weekday(calendarWeekday: weekdayComponent),
              selectedWeekdays.contains(currentWeekday) else {
            return false
        }
        
        // Get current time
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentTime = TimeOfDay(hour: hour, minute: minute)
        
        // Check if current time is within the schedule
        // Note: endTime is EXCLUSIVE (profile ends at endTime, not including endTime)
        return currentTime >= startTime && currentTime < endTime
    }
    
    /// Find the next activation date/time after the given date
    func nextActivationDate(after date: Date) -> Date? {
        guard !selectedWeekdays.isEmpty else { return nil }
        
        let calendar = Calendar.current
        
        // Check each of the next 7 days
        for daysAhead in 0..<7 {
            guard let checkDate = calendar.date(byAdding: .day, value: daysAhead, to: date) else { continue }
            
            let weekdayComponent = calendar.component(.weekday, from: checkDate)
            guard let weekday = Weekday(calendarWeekday: weekdayComponent),
                  selectedWeekdays.contains(weekday) else {
                continue
            }
            
            // Create the activation date with start time
            var components = calendar.dateComponents([.year, .month, .day], from: checkDate)
            components.hour = startTime.hour
            components.minute = startTime.minute
            components.second = 0
            
            guard let activationDate = calendar.date(from: components) else { continue }
            
            // If this is today, check if the start time hasn't passed yet
            if daysAhead == 0 {
                if activationDate > date {
                    return activationDate
                }
            } else {
                return activationDate
            }
        }
        
        return nil
    }
}

/// Represents a day of the week
enum Weekday: Int, Codable, Hashable, CaseIterable {
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    case sunday = 1
    
    var name: String {
        switch self {
        case .monday: return "Montag"
        case .tuesday: return "Dienstag"
        case .wednesday: return "Mittwoch"
        case .thursday: return "Donnerstag"
        case .friday: return "Freitag"
        case .saturday: return "Samstag"
        case .sunday: return "Sonntag"
        }
    }
    
    var shortName: String {
        switch self {
        case .monday: return "Mo"
        case .tuesday: return "Di"
        case .wednesday: return "Mi"
        case .thursday: return "Do"
        case .friday: return "Fr"
        case .saturday: return "Sa"
        case .sunday: return "So"
        }
    }
    
    init?(calendarWeekday: Int) {
        self.init(rawValue: calendarWeekday)
    }
    
    static var allCasesSorted: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
}

/// Represents a time of day (hour and minute)
struct TimeOfDay: Codable, Hashable, Comparable {
    var hour: Int
    var minute: Int
    
    init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
    
    init(from date: Date) {
        let calendar = Calendar.current
        self.hour = calendar.component(.hour, from: date)
        self.minute = calendar.component(.minute, from: date)
    }
    
    var formattedString: String {
        String(format: "%02d:%02d", hour, minute)
    }
    
    var asDate: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }
    
    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        if lhs.hour != rhs.hour {
            return lhs.hour < rhs.hour
        }
        return lhs.minute < rhs.minute
    }
}
