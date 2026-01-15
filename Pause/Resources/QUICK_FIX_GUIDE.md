# 🚀 Quick Fix Guide - Singleton zu DI Migration

## Problem: "Type 'X' has no member 'shared'"

### ❌ Alter Code (funktioniert nicht mehr)
```swift
struct MyView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var tagController = TagController.shared
    
    var body: some View {
        Text("Hello")
    }
}
```

### ✅ Neuer Code (funktioniert)
```swift
struct MyView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var tagController: TagController
    
    var body: some View {
        Text("Hello")
    }
}
```

---

## Problem: "Invalid redeclaration of 'SectionHeader'"

### Ursache
`SectionHeader` war in zwei Files definiert:
- `DesignSystem.swift` (alte Version)
- `Components/Layout/SectionHeader.swift` (neue Version)

### ✅ Lösung
Die alte Version wurde bereits aus `DesignSystem.swift` entfernt. Falls der Fehler noch auftritt:

1. **Clean Build:**
   ```
   Cmd + Shift + K (Clean Build Folder)
   Cmd + Option + Shift + K (Clean Derived Data)
   ```

2. **Xcode neu starten**

3. **Project neu öffnen**

---

## Problem: "Extraneous argument label 'title:' in call"

### Ursache
Dieser Fehler entstand durch die doppelte `SectionHeader` Deklaration.

### ✅ Korrekte Verwendung
```swift
// Standard Header
SectionHeader(title: "Mein Titel")

// Mit Subtitle
SectionHeader(title: "Mein Titel", subtitle: "Details")

// Mit Icon
SectionHeader(icon: "tag.fill", title: "Meine Tags")

// Mit Action Button
SectionHeaderWithAction(
    title: "Tags",
    actionTitle: "Neu",
    actionIcon: "plus"
) {
    // Action
}
```

---

## Welche Controller brauchen DI?

### ✅ Diese über @EnvironmentObject injizieren:
- `AppState`
- `ScreenTimeController`
- `TagController`
- `TimeProfileController`

### ✅ Diese können .shared bleiben:
- `SelectionManager.shared` (legitimer Singleton)
- `NFCController.shared` (Hardware-Controller)
- `PersistenceController.shared` (Persistence-Layer)
- `AuthorizationCenter.shared` (Apple Framework)

---

## Schnelle Migration: View-by-View

### 1. Finde die betroffene View
```bash
grep -n "\.shared" MyView.swift
```

### 2. Ersetze @StateObject mit @EnvironmentObject
```swift
// Vorher
@StateObject private var appState = AppState.shared

// Nachher
@EnvironmentObject private var appState: AppState
```

### 3. Entferne direkte .shared Calls
```swift
// Vorher
Button("Delete") {
    TagController.shared.deleteTag(tag)
}

// Nachher - Füge zuerst hinzu:
@EnvironmentObject private var tagController: TagController

// Dann verwende:
Button("Delete") {
    tagController.deleteTag(tag)
}
```

### 4. Teste die View
- App starten
- Zu der View navigieren
- Funktionalität testen

---

## Häufige Fehler und Lösungen

### Fehler: "No ObservableObject of type AppState found"
**Ursache:** View erhält kein Environment Object

**Lösung:** Stelle sicher, dass die Parent-View die Environment Objects weitergibt:
```swift
NavigationLink {
    MyDetailView()
        .environmentObject(appState)
        .environmentObject(tagController)
}
```

Oder nutze die bereits injizierte Environment (aus `PauseApp.swift`):
```swift
NavigationLink {
    MyDetailView()  // Erbt automatisch von ContentView
}
```

---

### Fehler: View erstellt neue Controller-Instanzen
**Problem:**
```swift
@StateObject private var controller = TagController()  // ❌ Neue Instanz!
```

**Lösung:**
```swift
@EnvironmentObject private var controller: TagController  // ✅ Nutzt injizierte
```

---

### Fehler: State synchronisiert nicht zwischen Views
**Ursache:** Mehrere Instanzen desselben Controllers

**Lösung:** Nutze immer `@EnvironmentObject` für geteilte State

---

## Cheat Sheet: Property Wrappers

| Wrapper | Wann verwenden | Beispiel |
|---------|----------------|----------|
| `@State` | Lokaler View-State | `@State private var isShowing = false` |
| `@StateObject` | View besitzt ObservableObject | `@StateObject private var viewModel = MyViewModel()` |
| `@ObservedObject` | View beobachtet fremdes Object | `@ObservedObject var data: MyData` |
| `@EnvironmentObject` | App-weite geteilte Objects | `@EnvironmentObject private var appState: AppState` |

**Für unsere DI-Architektur:**
- Zentrale Controller (AppState, ScreenTimeController, etc.) → `@EnvironmentObject`
- View-spezifische ViewModels → `@StateObject`
- Lokale UI-States → `@State`

---

## Testing Checklist

Nach jeder Migration:

- [ ] App startet ohne Crashes
- [ ] View lädt korrekt
- [ ] State-Updates funktionieren
- [ ] Navigation funktioniert
- [ ] Keine Console-Warnings

---

## Support & Weitere Infos

**Detaillierte Docs:**
- `ISSUES_FIXED.md` - Alle behobenen Issues mit Details
- `SINGLETON_REMOVAL_COMPLETE.md` - Komplette Migration-Overview
- `MIGRATION_GUIDE_DI.md` - Step-by-step Guide

**Bei Problemen:**
1. Check `ISSUES_FIXED.md` für ähnliche Probleme
2. Clean Build durchführen
3. Überprüfe dass alle Dependencies in `PauseApp.swift` korrekt injiziert sind

---

**Letzte Aktualisierung:** 15. Januar 2026
