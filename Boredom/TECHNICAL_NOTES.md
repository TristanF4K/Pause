# ApplicationToken Persistence - Technical Notes

## The Challenge

`ApplicationToken` and `ActivityCategoryToken` from the FamilyControls framework **cannot be directly encoded to JSON or stored in UserDefaults**. This is an Apple limitation for privacy and security reasons.

## Current Implementation

The current codebase stores **placeholder strings** instead of real tokens. This works for the UI flow but needs enhancement for actual app blocking.

## Solutions

### Option 1: In-Memory Storage (Simplest)
Store tokens in memory and require users to reselect apps each app launch.

```swift
class ScreenTimeController {
    // Store tokens in memory only
    private var currentAppSelection = FamilyActivitySelection()
    
    func updateSelection(_ selection: FamilyActivitySelection) {
        self.currentAppSelection = selection
        applyRestrictions()
    }
    
    private func applyRestrictions() {
        store.shield.applications = currentAppSelection.applicationTokens
        store.shield.applicationCategories = .specific(currentAppSelection.categoryTokens)
    }
}
```

**Pros:**
- Simple to implement
- No persistence issues
- Always up to date

**Cons:**
- User must reselect apps after each app restart
- Poor user experience

### Option 2: ShieldConfigurationDataSource (Recommended)

Use Apple's recommended approach with a custom `ShieldConfigurationDataSource`.

```swift
// 1. Create an Extension Target for Shield Configuration
class CustomShieldConfigurationDataSource: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Customize the shield UI
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: .systemBackground,
            icon: UIImage(systemName: "lock.shield"),
            title: ShieldConfiguration.Label(
                text: "App blockiert",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Scanne deinen NFC Tag zum Entsperren",
                color: .secondaryLabel
            ),
            primaryButtonLabel: nil,
            primaryButtonBackgroundColor: nil,
            secondaryButtonLabel: nil
        )
    }
}

// 2. In your main app
import FamilyControls
import ManagedSettings

class ScreenTimeController {
    private let store = ManagedSettingsStore()
    
    // Store selection reference
    private var activeSelection: FamilyActivitySelection?
    
    func blockApps(with selection: FamilyActivitySelection) {
        activeSelection = selection
        
        // Apply shields directly from selection
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }
    
    func unblockAll() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
```

### Option 3: DeviceActivity + Schedule (Most Powerful)

Use `DeviceActivitySchedule` for time-based restrictions with persistence.

```swift
import DeviceActivity
import FamilyControls

class ScheduleController {
    private let deviceActivityCenter = DeviceActivityCenter()
    
    func scheduleRestrictions(
        name: String,
        selection: FamilyActivitySelection,
        schedule: DeviceActivitySchedule
    ) throws {
        let activityName = DeviceActivityName(name)
        
        try deviceActivityCenter.startMonitoring(
            activityName,
            during: schedule,
            events: [:]
        )
        
        // Store selection separately for reference
        // (still can't directly persist tokens)
    }
}
```

## Recommended Approach for FocusLock

### Modified Architecture

1. **Keep FamilyActivitySelection in Memory**
```swift
@MainActor
class AppState: ObservableObject {
    // Store actual selections in memory
    @Published var tagSelections: [UUID: FamilyActivitySelection] = [:]
    
    // Store metadata for UI (can be persisted)
    @Published var registeredTags: [NFCTag] = []
}
```

2. **Update NFCTag Model**
```swift
struct NFCTag: Identifiable, Codable {
    let id: UUID
    var name: String
    var tagIdentifier: String
    // Don't store tokens directly
    // Store count for UI purposes only
    var linkedAppsCount: Int
    var linkedCategoriesCount: Int
    var createdAt: Date
    var isActive: Bool
}
```

3. **Update ScreenTimeController**
```swift
@MainActor
class ScreenTimeController {
    private let store = ManagedSettingsStore()
    
    // Keep active selection in memory
    private var activeSelection: FamilyActivitySelection?
    
    func blockApps(selection: FamilyActivitySelection) {
        self.activeSelection = selection
        
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        
        // Optionally restrict other things
        // store.dateAndTime.requireAutomaticDateAndTime = true
        // store.appStore.denyInAppPurchases = true
    }
    
    func unblockAll() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        activeSelection = nil
    }
    
    var hasActiveRestrictions: Bool {
        activeSelection != nil
    }
}
```

4. **Update TagController**
```swift
@MainActor
class TagController {
    static let shared = TagController()
    private let appState = AppState.shared
    private let screenTimeController = ScreenTimeController.shared
    
    func linkAppsToTag(tag: NFCTag, selection: FamilyActivitySelection) {
        // Store selection in memory
        appState.tagSelections[tag.id] = selection
        
        // Update tag metadata
        var updatedTag = tag
        updatedTag.linkedAppsCount = selection.applicationTokens.count
        updatedTag.linkedCategoriesCount = selection.categoryTokens.count
        appState.updateTag(updatedTag)
    }
    
    func handleTagScan(identifier: String) {
        guard let tag = appState.registeredTags.first(where: { $0.tagIdentifier == identifier }),
              let selection = appState.tagSelections[tag.id] else {
            return
        }
        
        // Toggle blocking
        if screenTimeController.hasActiveRestrictions {
            screenTimeController.unblockAll()
        } else {
            screenTimeController.blockApps(selection: selection)
        }
        
        // Update UI state
        var updatedTag = tag
        updatedTag.isActive = !tag.isActive
        appState.updateTag(updatedTag)
    }
}
```

## Implementation Steps

1. **Remove string-based token storage** from models
2. **Add in-memory FamilyActivitySelection dictionary** to AppState
3. **Update TagController** to use in-memory selections
4. **Update ScreenTimeController** to accept FamilyActivitySelection directly
5. **Update UI** to handle re-selection if app was force-quit
6. **(Optional) Add Shield Configuration Extension** for custom blocking UI

## User Experience Consideration

Since tokens can't be persisted:

### On App Launch
Show a notice if tags exist but selections are missing:

```swift
if !appState.registeredTags.isEmpty && appState.tagSelections.isEmpty {
    // Show "Reselect Apps" prompt
}
```

### UI Flow
1. User registers tag ✓
2. User selects apps ✓
3. **Apps stay selected until app terminates**
4. On next launch: Prompt to reselect if needed

### Alternative: Always-Active Mode
For users who want "set and forget":
- Use DeviceActivity schedules
- Schedule covers 24/7
- Tag scan enables/disables the schedule

## Testing Notes

- Test app selection survival during:
  - Background/foreground transitions ✓
  - Device lock/unlock ✓
  - **App termination** ✗ (selections lost)
  
- Test blocking persistence:
  - ManagedSettingsStore persists across app launches ✓
  - But requires reapplication if app is terminated

## Summary

**Current Status**: The app structure is correct, but token storage needs refinement.

**Next Step**: Implement in-memory selection storage as outlined in "Recommended Approach".

**Future Enhancement**: Add DeviceActivity schedules for persistent restrictions.
