# 🏗️ Architecture Update: Fixed Premature App Blocking

## Problem Description

**Issue:** Apps were being blocked immediately when added to a tag's configuration, even when the tag was not active. This happened because `ManagedSettingsStore` automatically activates restrictions as soon as data is written to it.

**Root Cause:** The previous architecture stored each tag's selection in its own named `ManagedSettingsStore` (e.g., `tag_{uuid}`). This caused iOS to immediately enforce the restrictions, regardless of whether the tag was "active" or not.

## Solution Overview

The new architecture separates **configuration storage** from **active blocking**:

1. **Tag configurations** are stored in `UserDefaults` as serialized data (NOT in ManagedSettingsStore)
2. **Active blocking** only happens in the `blockingStore` when a tag is explicitly activated
3. **Migration** from old architecture is automatic and seamless

## Architecture Changes

### Before (Old Architecture)

```
Tag Configuration Storage:
├── tag_uuid1 (ManagedSettingsStore) ← BLOCKS IMMEDIATELY! ❌
├── tag_uuid2 (ManagedSettingsStore) ← BLOCKS IMMEDIATELY! ❌
└── active_blocking (ManagedSettingsStore)
```

**Problem:** All tag stores were active simultaneously, blocking all configured apps.

### After (New Architecture)

```
Tag Configuration Storage:
├── UserDefaults["focuslock.tag_selections"] ← Just data, no blocking ✅
│   └── { uuid1: SerializableSelection, uuid2: SerializableSelection, ... }
│
Active Blocking:
└── active_blocking (ManagedSettingsStore) ← ONLY ONE active store ✅
```

**Solution:** Only the `active_blocking` store contains actual restrictions. Tag configurations are passive data.

## Key Components

### 1. `SerializableSelection` (New)

A Codable wrapper for `FamilyActivitySelection` that allows persistence without using ManagedSettingsStore:

```swift
struct SerializableSelection: Codable {
    let applicationTokensData: [Data]
    let categoryTokensData: [Data]
    let webDomainTokensData: [Data]
    
    init(from selection: FamilyActivitySelection)
    func toFamilyActivitySelection() -> FamilyActivitySelection
}
```

### 2. `SelectionManager` (Redesigned)

**Changed:**
- ❌ Removed: `tagStores: [UUID: ManagedSettingsStore]`
- ✅ Added: `tagSelections: [UUID: FamilyActivitySelection]` (in-memory)
- ✅ Added: UserDefaults-based persistence
- ✅ Added: Automatic migration from old architecture

**Key Methods:**
- `setSelection(_:for:)` - Saves to UserDefaults only (NO blocking)
- `activateBlocking(for:)` - Copies selection to blockingStore (STARTS blocking)
- `deactivateBlocking()` - Clears blockingStore (STOPS blocking)

### 3. Migration Strategy

The system automatically detects and migrates old-style tag stores:

```swift
private func migrateOldTagStores() {
    // 1. Read data from old ManagedSettingsStore instances
    // 2. Convert to new UserDefaults format
    // 3. Clear old stores to prevent blocking
    // 4. Log migration success
}
```

## Behavior Changes

### Setting a Selection (Configuration)

**Before:**
```swift
setSelection(selection, for: tagID)
// ❌ Apps are IMMEDIATELY blocked (unwanted!)
```

**After:**
```swift
setSelection(selection, for: tagID)
// ✅ Selection saved, but apps are NOT blocked yet
// 💡 Must call activateBlocking(for: tagID) to block
```

### Activating a Tag

**Before:**
```swift
activateBlocking(for: tagID)
// Copies from tag's store to blocking store
// (But tag's store was already blocking anyway)
```

**After:**
```swift
activateBlocking(for: tagID)
// Reads from UserDefaults, writes to blockingStore
// ✅ This is the ONLY time blocking starts
```

### Deactivating a Tag

**Before & After (Same):**
```swift
deactivateBlocking()
// Clears blockingStore completely
// ✅ All apps are unlocked
```

## API Compatibility

All public APIs remain the same:

- ✅ `setSelection(_:for:)` - Still works, just stores differently
- ✅ `getSelection(for:)` - Still returns FamilyActivitySelection
- ✅ `activateBlocking(for:)` - Same interface
- ✅ `deactivateBlocking()` - Same interface
- ✅ `hasSelection(for:)` - Same interface
- ✅ `removeSelection(for:)` - Same interface

**Result:** No changes needed in UI code or view controllers!

## Migration Process

When the app launches for the first time with the new architecture:

1. **Detection**: Check UserDefaults for old configured tags list
2. **Reading**: Read selections from old ManagedSettingsStore instances
3. **Conversion**: Convert to SerializableSelection format
4. **Storage**: Save to UserDefaults
5. **Cleanup**: Clear old stores to prevent unwanted blocking
6. **Logging**: Report migration success

```
🔄 Migrating old tag stores...
✅ Migrated tag 123e4567-e89b-12d3: 5 apps, 2 categories
✅ Migrated tag 789abcde-f012-34f5: 3 apps, 1 categories
🎉 Migration complete: 2 tags migrated
```

## Testing Checklist

### Scenario 1: New Tag Configuration
1. Create new tag
2. Add apps to configuration
3. **Verify:** Apps are NOT blocked yet ✅
4. Scan/activate tag
5. **Verify:** Apps are NOW blocked ✅
6. Scan/deactivate tag
7. **Verify:** Apps are unlocked ✅

### Scenario 2: App Restart (Active Tag)
1. Configure and activate tag
2. Close app
3. Reopen app
4. **Verify:** Tag is still active, apps are blocked ✅

### Scenario 3: App Restart (Inactive Tag)
1. Configure tag (don't activate)
2. Close app
3. Reopen app
4. **Verify:** Configuration saved, apps NOT blocked ✅

### Scenario 4: Migration from Old Architecture
1. Use old version to configure tags
2. Update to new version
3. Launch app
4. **Verify:** All configurations migrated ✅
5. **Verify:** No unwanted blocking ✅

## Benefits

✅ **Correct Behavior:** Apps only block when tag is active
✅ **Better UX:** Users can configure tags without side effects
✅ **Cleaner Architecture:** Clear separation of config vs. active state
✅ **Easier Testing:** Can test configuration without triggering blocks
✅ **Better Performance:** Less ManagedSettingsStore overhead
✅ **Easier Debugging:** Clear logging shows when blocking starts/stops

## Technical Notes

### Why UserDefaults Instead of ManagedSettingsStore?

1. **ManagedSettingsStore is for enforcement, not storage**
   - Writing to it activates restrictions immediately
   - Can't "save for later" without triggering blocks

2. **UserDefaults is perfect for configuration**
   - Passive storage only
   - Easy serialization with Codable
   - Survives app restarts and updates

3. **Tokens are serializable**
   - ApplicationToken, ActivityCategoryToken, WebDomainToken
   - All conform to Codable
   - Can be encoded/decoded safely

### Emergency Clear Function

Added `emergencyClearAllStores()` that:
- Clears the blocking store
- Clears the default store
- Clears any legacy named stores
- Useful for debugging and troubleshooting

### Extensions

Added `ManagedSettingsStore.clearAllSettings()` that:
- Clears all shield settings
- Clears all restriction settings
- Sets everything to default/off
- Used in multiple places for consistency

## Files Changed

1. **UtilitiesSelectionManager.swift** - Complete redesign
2. **ControllersScreenTimeController.swift** - Added extension, minor updates
3. **ViewsSettingsSettingsView.swift** - Added emergency clear button

## Backwards Compatibility

✅ Automatic migration on first launch
✅ Old configurations are preserved
✅ No user action required
✅ Legacy stores are cleaned up

## Future Improvements

- [ ] Add analytics for blocking sessions
- [ ] Add scheduling (time-based blocking)
- [ ] Add quick toggle for temporary unblock
- [ ] Add family sharing support

---

**Implementation Date:** January 5, 2026
**Author:** Tristan Srebot
**Status:** ✅ Implemented and Tested
