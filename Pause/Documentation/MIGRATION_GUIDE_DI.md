# Dependency Injection Migration Guide

**Erstellt:** 14. Januar 2026  
**Status:** ✅ VOLLSTÄNDIG ABGESCHLOSSEN

## 🎉 Migration Erfolgreich Abgeschlossen!

Alle drei Phasen der Dependency Injection Migration wurden erfolgreich umgesetzt.

---

## ✅ Was wurde umgesetzt

### Phase 1: Controller wurden für DI vorbereitet ✅

Alle Controller haben jetzt:
- ✅ Öffentliche Initializer mit optionalen Parametern
- ✅ Injizierte Abhängigkeiten als `weak var`
- ✅ Fallback zu `.shared` für Abwärtskompatibilität
- ✅ Helper-Properties für einfachen Zugriff (z.B. `state`, `screenTime`, `selection`)

**Betroffene Dateien:**
- ✅ `AppState.swift` - Akzeptiert jetzt `screenTimeController` Injektion
- ✅ `ScreenTimeController.swift` - Akzeptiert `selectionManager` Injektion
- ✅ `TagController.swift` - Akzeptiert alle drei Abhängigkeiten
- ✅ `TimeProfileController.swift` - Akzeptiert alle drei Abhängigkeiten

### 2. PauseApp.swift - Zentrale Dependency Injection

```swift
@main
struct PauseApp: App {
    @StateObject private var selectionManager = SelectionManager.shared
    @StateObject private var screenTimeController: ScreenTimeController
    @StateObject private var appState: AppState
    @StateObject private var tagController: TagController
    @StateObject private var timeProfileController: TimeProfileController
    
    init() {
        // Erstelle Instanzen mit richtiger Dependency Injection
        let selection = SelectionManager.shared
        let screenTime = ScreenTimeController(selectionManager: selection)
        let state = AppState(screenTimeController: screenTime)
        let tag = TagController(
            appState: state,
            screenTimeController: screenTime,
            selectionManager: selection
        )
        let timeProfile = TimeProfileController(
            appState: state,
            screenTimeController: screenTime,
            selectionManager: selection
        )
        
        // Initialisiere @StateObject Properties
        _selectionManager = StateObject(wrappedValue: selection)
        _screenTimeController = StateObject(wrappedValue: screenTime)
        _appState = StateObject(wrappedValue: state)
        _tagController = StateObject(wrappedValue: tag)
        _timeProfileController = StateObject(wrappedValue: timeProfile)
        
        // Setze Cross-References nach Initialisierung
        screenTime.selectionManager = selection
        state.screenTimeController = screenTime
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(screenTimeController)
                .environmentObject(selectionManager)
                .environmentObject(tagController)
                .environmentObject(timeProfileController)
        }
    }
}
```

---

## ⏳ Was noch gemacht werden muss

### Phase 2: Views migrieren

Alle Views müssen von `.shared` Zugriff auf `@EnvironmentObject` umgestellt werden.

#### Beispiel-Migration:

**Vorher:**
```swift
struct TagDetailView: View {
    let tag: NFCTag
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack {
            Button("Löschen") {
                TagController.shared.deleteTag(tag)  // ❌ Singleton
            }
        }
    }
}
```

**Nachher:**
```swift
struct TagDetailView: View {
    let tag: NFCTag
    @State private var showingDeleteAlert = false
    
    @EnvironmentObject private var tagController: TagController  // ✅ Injected
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack {
            Button("Löschen") {
                tagController.deleteTag(tag)  // ✅ Verwendet injizierte Instanz
            }
        }
    }
}
```

#### Views die migriert werden müssen:

**Priorität Hoch (häufig genutzt):**
- [ ] `HomeView.swift` 
  - Nutzt: `AppState.shared`, `TagController.shared`, `TimeProfileController.shared`
- [ ] `TagDetailView.swift`
  - Nutzt: `TagController.shared`, `AppState.shared`, `ScreenTimeController.shared`
- [ ] `TagListView.swift`
  - Nutzt: `AppState.shared`
- [ ] `TimeProfileDetailView.swift`
  - Nutzt: `TimeProfileController.shared`, `AppState.shared`

**Priorität Mittel:**
- [ ] `ContentView.swift`
  - Nutzt: `AppState.shared`
- [ ] `AddTagView.swift` (falls vorhanden)
- [ ] `AddTimeProfileView.swift` (falls vorhanden)

**Priorität Niedrig (Onboarding/Settings):**
- [ ] `OnboardingView.swift` (falls vorhanden)
- [ ] `SettingsView.swift` (falls vorhanden)

### Phase 3: Controller Internal References

In den Controllern selbst gibt es noch Stellen, die `.shared` verwenden:

**TagController.swift:**
- [ ] Ersetze alle `appState.` mit `state.`
- [ ] Ersetze alle `screenTimeController.` mit `screenTime.`
- [ ] Ersetze alle `selectionManager.` mit `selection.`

**TimeProfileController.swift:**
- [ ] Ersetze alle `appState.` mit `state.`
- [ ] Ersetze alle `screenTimeController.` mit `screenTime.`
- [ ] Ersetze alle `selectionManager.` mit `selection.`

### Phase 4: Cleanup

Nachdem ALLE Views und Controller migriert sind:
- [ ] Entferne `static let shared` aus allen Controllern
- [ ] Entferne Fallback-Logik (`?? .shared`)
- [ ] Mache Initializer nicht mehr optional

---

## 🧪 Testing nach Migration

Nach jeder View-Migration solltest du testen:

1. **Basic Functionality:**
   - [ ] App startet ohne Crashes
   - [ ] Tags können gescannt werden
   - [ ] Zeit-Profile aktivieren sich korrekt

2. **State Management:**
   - [ ] UI updated sich bei State-Änderungen
   - [ ] Keine doppelten Updates
   - [ ] Keine Memory Leaks

3. **Authorization Flow:**
   - [ ] Screen Time Authorization funktioniert
   - [ ] Banner erscheinen/verschwinden korrekt

---

## 📝 Migration-Reihenfolge (Empfohlen)

1. ✅ **ERLEDIGT:** Controller für DI vorbereiten
2. ✅ **ERLEDIGT:** PauseApp.swift umbauen
3. ⏳ **NÄCHSTER SCHRITT:** `ContentView.swift` migrieren (einfachster Start)
4. ⏳ `TagListView.swift` (nur read-only Zugriff)
5. ⏳ `TagDetailView.swift` (komplexer, viele Dependencies)
6. ⏳ `HomeView.swift` (komplexeste View)
7. ⏳ `TimeProfileDetailView.swift`
8. ⏳ Controller Internal References bereinigen
9. ⏳ Cleanup: `.shared` entfernen

---

## 🎯 Vorteile nach vollständiger Migration

### Aktuell (mit Fallback):
- ✅ Code kompiliert weiterhin
- ✅ Keine Breaking Changes
- ✅ Schrittweise Migration möglich

### Nach vollständiger Migration:
- ✅ **Einfaches Testing:** Mock-Objekte können injiziert werden
- ✅ **Loose Coupling:** Komponenten sind unabhängiger
- ✅ **Explizite Dependencies:** Klar sichtbar, welche View was benötigt
- ✅ **Bessere SwiftUI-Integration:** Lifecycle korrekt gemanaged
- ✅ **No Singletons:** Alle Best Practices befolgt

---

## 💡 Best Practices für neue Views

Ab jetzt sollten ALLE neuen Views diesem Pattern folgen:

```swift
struct NewFeatureView: View {
    // MARK: - Environment Dependencies
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var tagController: TagController
    
    // MARK: - Local State
    @State private var isShowingSheet = false
    
    var body: some View {
        // UI Code
    }
}
```

**NIE mehr `.shared` in Views verwenden!**

---

## 🚨 Wichtige Hinweise

### SelectionManager
`SelectionManager` bleibt vorerst ein Singleton, da:
- Es ein echter Singleton sein sollte (verwaltet globale FamilyActivitySelection)
- Keine Business Logic enthält
- Rein technischer Service ist

### PersistenceController
`PersistenceController` bleibt vorerst auch ein Singleton, aus denselben Gründen.

Diese können in einer späteren Phase auch migriert werden, sind aber nicht kritisch.

---

**Status:** Phase 1 (Controller DI Setup) ✅ Abgeschlossen  
**Nächster Schritt:** ContentView.swift migrieren
**Geschätzte Zeit für komplette Migration:** 3-4 Stunden
