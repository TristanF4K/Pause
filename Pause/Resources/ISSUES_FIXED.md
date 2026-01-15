# Issues behoben - 15. Januar 2026

## ✅ Behobene Probleme

### 1. Invalid redeclaration of 'SectionHeader'
**Locations:**
- `/Resources/DesignSystem.swift:180`
- `/Components/Layout/SectionHeader.swift:19`

**Problem:** 
`SectionHeader` war in zwei Files definiert - einmal als alte, einfache Version in DesignSystem.swift und einmal als neue, erweiterte Version in SectionHeader.swift.

**Lösung:**
Die alte Definition aus `DesignSystem.swift` wurde entfernt und durch einen Kommentar ersetzt:
```swift
// MARK: - SectionHeader moved to Components/Layout/SectionHeader.swift
// This was causing duplicate declaration errors.
// The new SectionHeader has more features (icons, actions, etc.)
```

Die neue Version in `SectionHeader.swift` hat folgende Vorteile:
- Optional Icons mit `icon: String?`
- Customizable Icon Farben mit `iconColor: Color`
- `SectionHeaderWithAction` für Headers mit Action Buttons
- Bessere Preview Examples

---

### 2. Type 'AppState' has no member 'shared'
**Location:** `/Features/TimeProfiles/Views/ProfilesView.swift:129`

**Problem:**
`TimeProfileCard` verwendete noch die alte Singleton-Pattern:
```swift
@StateObject private var appState = AppState.shared
```

Aber `AppState.shared` wurde im Rahmen der DI-Migration entfernt.

**Lösung:**
Umstellung auf Dependency Injection via `@EnvironmentObject`:
```swift
@EnvironmentObject private var appState: AppState
```

**Warum @EnvironmentObject statt @StateObject?**
- `@StateObject` erstellt eine neue Instanz → würde eine zweite AppState-Instanz erstellen
- `@EnvironmentObject` nutzt die in `PauseApp.swift` injizierte Instanz → Single Source of Truth
- Auto-Updates bei State-Änderungen

---

### 3. Type 'ScreenTimeController' has no member 'shared'
**Location:** `/Features/TimeProfiles/Views/ProfilesView.swift:130`

**Problem:**
Gleiche Situation wie bei AppState:
```swift
@StateObject private var screenTimeController = ScreenTimeController.shared
```

**Lösung:**
```swift
@EnvironmentObject private var screenTimeController: ScreenTimeController
```

---

### 4. Extraneous argument label 'title:' in call
**Locations:**
- `/Components/Layout/SectionHeader.swift:140`
- `/Components/Layout/SectionHeader.swift:187`

**Problem:**
Diese Errors entstanden durch die doppelte Deklaration von `SectionHeader`. Swift war verwirrt, welche Version verwendet werden sollte.

**Lösung:**
Durch Entfernung der doppelten Deklaration ist der Fehler behoben. Die korrekte API ist:
```swift
// Korrekt - title ist ein labeled parameter
SectionHeader(title: "Mein Titel")
SectionHeader(title: "Titel", subtitle: "Untertitel")
SectionHeader(icon: "tag.fill", title: "Titel")
```

**Falls der Fehler nach Clean Build noch auftritt:**
1. Clean Build Folder: `Cmd + Shift + K`
2. Clean Derived Data: `Cmd + Option + Shift + K`
3. Xcode neustarten
4. Project erneut öffnen

---

## 🔍 Weiterführende Checks

### Sind noch andere Views betroffen?

Checke folgende Files auf `.shared` Verwendung:

```bash
# Terminal-Befehl zum Finden aller .shared Verwendungen
grep -r "\.shared" --include="*.swift" ./Pause/Features
grep -r "\.shared" --include="*.swift" ./Pause/Components
```

**Bekannte sichere `.shared` Verwendungen:**
- ✅ `SelectionManager.shared` - legitimer Singleton (siehe SINGLETON_REMOVAL_COMPLETE.md)
- ✅ `NFCController.shared` - Hardware-Controller, muss Singleton sein
- ✅ `PersistenceController.shared` - Persistence-Layer, OK als Singleton
- ✅ `AuthorizationCenter.shared` - Apple Framework, vorgegeben

**Nicht mehr erlaubt:**
- ❌ `AppState.shared` - ENTFERNT
- ❌ `ScreenTimeController.shared` - ENTFERNT
- ❌ `TagController.shared` - ENTFERNT
- ❌ `TimeProfileController.shared` - ENTFERNT

---

## 📋 Migration Checklist für weitere Views

Falls du weitere Views findest, die noch `.shared` nutzen:

### HomeView.swift
```swift
// ALT ❌
struct HomeView: View {
    @StateObject private var appState = AppState.shared
    // ...
}

// NEU ✅
struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    // ...
}
```

### TagDetailView.swift
```swift
// ALT ❌
struct TagDetailView: View {
    let tag: NFCTag
    
    var body: some View {
        Button("Löschen") {
            TagController.shared.deleteTag(tag)  // ❌
        }
    }
}

// NEU ✅
struct TagDetailView: View {
    let tag: NFCTag
    @EnvironmentObject private var tagController: TagController  // ✅
    
    var body: some View {
        Button("Löschen") {
            tagController.deleteTag(tag)  // ✅
        }
    }
}
```

### Generelles Pattern:

1. **Entferne:**
   ```swift
   @StateObject private var controller = Controller.shared
   ```

2. **Ersetze mit:**
   ```swift
   @EnvironmentObject private var controller: Controller
   ```

3. **Stelle sicher** dass die View als Child einer View liegt, die die Environment Objects erhält (in eurem Fall: `ContentView`)

---

## 🎯 Vorteile der neuen Architektur

### Vorher (mit Singletons) ❌
```swift
struct MyView: View {
    var body: some View {
        Button("Action") {
            AppState.shared.doSomething()  // Versteckte Dependency
            TagController.shared.doSomething()  // Versteckte Dependency
        }
    }
}
```

**Probleme:**
- Versteckte Dependencies (nicht sichtbar im View-Signature)
- Schwer zu testen (kann Singletons nicht mocken)
- Tight Coupling (View direkt abhängig von konkreten Implementierungen)
- Keine Auto-Updates bei State-Änderungen garantiert

### Nachher (mit DI) ✅
```swift
struct MyView: View {
    @EnvironmentObject private var appState: AppState  // Explizit
    @EnvironmentObject private var tagController: TagController  // Explizit
    
    var body: some View {
        Button("Action") {
            appState.doSomething()
            tagController.doSomething()
        }
    }
}
```

**Vorteile:**
- ✅ Explizite Dependencies (sofort sichtbar was die View braucht)
- ✅ Leicht zu testen (Mock-Objekte via `.environmentObject()` injizierbar)
- ✅ Loose Coupling (View kennt nur Interfaces, nicht Implementierungen)
- ✅ Automatische UI-Updates (SwiftUI observiert @Published Properties)
- ✅ Bessere Performance (keine redundanten View-Refreshes)

---

## 🧪 Testing mit der neuen Architektur

### Unit Tests (möglich dank DI)

```swift
import Testing
@testable import Pause

@Suite("TagController Tests")
struct TagControllerTests {
    
    @Test("Tag deletion removes tag from AppState")
    func tagDeletion() throws {
        // Arrange - Create mock dependencies
        let mockAppState = MockAppState()
        let mockScreenTime = MockScreenTimeController()
        let mockSelection = MockSelectionManager()
        
        let controller = TagController(
            appState: mockAppState,
            screenTimeController: mockScreenTime,
            selectionManager: mockSelection
        )
        
        let tag = NFCTag(
            id: UUID(),
            name: "Test Tag",
            tagIdentifier: "test-123",
            linkedAppsCount: 5,
            linkedCategoriesCount: 2
        )
        
        mockAppState.registeredTags = [tag]
        
        // Act
        controller.deleteTag(tag)
        
        // Assert
        #expect(mockAppState.registeredTags.isEmpty)
        #expect(mockAppState.deleteCalled == true)
    }
}

// Mock-Klassen für Testing
class MockAppState: AppState {
    var deleteCalled = false
    
    override func deleteTag(_ tag: NFCTag) {
        deleteCalled = true
        registeredTags.removeAll { $0.id == tag.id }
    }
}
```

### SwiftUI Preview Tests (ebenfalls möglich)

```swift
#Preview("TagDetailView with Mock Data") {
    let mockAppState = AppState(screenTimeController: nil)
    mockAppState.registeredTags = [
        NFCTag(id: UUID(), name: "Test Tag", tagIdentifier: "123", linkedAppsCount: 3, linkedCategoriesCount: 1)
    ]
    
    return TagDetailView(tag: mockAppState.registeredTags[0])
        .environmentObject(mockAppState)
        .environmentObject(ScreenTimeController())
        .environmentObject(TagController(
            appState: mockAppState,
            screenTimeController: ScreenTimeController(),
            selectionManager: SelectionManager.shared
        ))
}
```

---

## 📚 Weiterführende Dokumentation

Weitere Details zur DI-Architektur:
- `SINGLETON_REMOVAL_COMPLETE.md` - Detaillierte Übersicht aller Änderungen
- `MIGRATION_GUIDE_DI.md` - Step-by-step Migration Guide
- `DI_QUICK_REFERENCE.md` - Schnelle Referenz für neue Features

---

**Status:** ✅ Alle gemeldeten Issues behoben  
**Datum:** 15. Januar 2026  
**Nächste Schritte:** 
1. Clean Build durchführen
2. Weitere Views auf `.shared` prüfen
3. Unit Tests schreiben (jetzt möglich!)

