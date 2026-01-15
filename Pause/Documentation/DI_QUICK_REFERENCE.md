# 🚀 Dependency Injection - Quick Reference

**Für Entwickler:** Schnellreferenz für die neue DI-Architektur

---

## 📦 Verfügbare Services & Controller

### Controller (via @EnvironmentObject)
```swift
@EnvironmentObject private var appState: AppState
@EnvironmentObject private var screenTimeController: ScreenTimeController
@EnvironmentObject private var tagController: TagController
@EnvironmentObject private var timeProfileController: TimeProfileController
@EnvironmentObject private var selectionManager: SelectionManager
```

### Hardware-Controller (via Singleton - OK)
```swift
@StateObject private var nfcController = NFCController.shared
```

---

## ✅ DO: Richtige Verwendung

### In SwiftUI Views
```swift
struct MyView: View {
    // ✅ RICHTIG: Verwende @EnvironmentObject
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var tagController: TagController
    
    var body: some View {
        // Direkte Verwendung
        Text(appState.isBlocking ? "Blocking" : "Active")
        
        Button("Scan Tag") {
            // Controller-Methoden aufrufen
            tagController.scanTag(identifier: "...")
        }
    }
}
```

### Neue Views hinzufügen
```swift
// Wenn du eine neue View erstellst, vergiss nicht:
NavigationLink {
    MyNewView()
        .environmentObject(appState)      // ✅ Weiterleiten
        .environmentObject(tagController)  // ✅ Weiterleiten
}
```

### In ViewModels (wenn benötigt)
```swift
@MainActor
class MyViewModel: ObservableObject {
    // ✅ RICHTIG: Dependencies über init injizieren
    weak var appState: AppState?
    weak var tagController: TagController?
    
    init(appState: AppState?, tagController: TagController?) {
        self.appState = appState
        self.tagController = tagController
    }
}

// In der View:
struct MyView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var tagController: TagController
    
    @StateObject private var viewModel: MyViewModel
    
    init() {
        // Inject dependencies
        let vm = MyViewModel(
            appState: appState,
            tagController: tagController
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
}
```

---

## ❌ DON'T: Falsche Verwendung

### ❌ Keine .shared Aufrufe mehr!
```swift
// ❌ FALSCH - Wird nicht kompilieren!
AppState.shared.updateTag(...)
ScreenTimeController.shared.blockApps(...)
TagController.shared.scanTag(...)
TimeProfileController.shared.createProfile(...)

// ✅ RICHTIG - Verwende injizierte Instanzen
@EnvironmentObject private var appState: AppState
@EnvironmentObject private var screenTimeController: ScreenTimeController

// Dann:
appState.updateTag(...)
screenTimeController.blockApps(...)
```

### ❌ Keine optionalen Dependencies
```swift
// ❌ FALSCH
weak var appState: AppState?  // Optional

func doSomething() {
    if let state = appState {  // ❌ Unsicher
        state.update()
    }
}

// ✅ RICHTIG
weak var appState: AppState?  // Optional declaration OK

private var state: AppState {
    guard let appState else {
        fatalError("AppState not injected")  // ✅ Fail fast
    }
    return appState
}

func doSomething() {
    state.update()  // ✅ Safe
}
```

---

## 🧪 Testing mit DI

### Unit Tests
```swift
import Testing
@testable import Pause

@Suite("MyController Tests")
struct MyControllerTests {
    
    @Test("Test with mocked dependencies")
    func testWithMocks() throws {
        // ✅ Erstelle Mock-Objekte
        let mockAppState = MockAppState()
        let mockScreenTime = MockScreenTimeController()
        
        // ✅ Injiziere Mocks
        let controller = TagController(
            appState: mockAppState,
            screenTimeController: mockScreenTime,
            selectionManager: nil
        )
        
        // ✅ Teste
        controller.scanTag(identifier: "test")
        
        // ✅ Verify
        #expect(mockAppState.updatedTags.count == 1)
    }
}

// Mock Classes
class MockAppState: AppState {
    var updatedTags: [NFCTag] = []
    
    override func updateTag(_ tag: NFCTag) {
        updatedTags.append(tag)
    }
}
```

---

## 🔧 Neue Controller hinzufügen

### 1. Controller erstellen
```swift
@MainActor
class MyNewController: ObservableObject {
    // Dependencies
    weak var appState: AppState?
    weak var screenTimeController: ScreenTimeController?
    
    // Init mit DI
    init(appState: AppState?, screenTimeController: ScreenTimeController?) {
        self.appState = appState
        self.screenTimeController = screenTimeController
    }
    
    // Safe accessors
    private var state: AppState {
        guard let appState else {
            fatalError("AppState not injected")
        }
        return appState
    }
    
    private var screenTime: ScreenTimeController {
        guard let screenTimeController else {
            fatalError("ScreenTimeController not injected")
        }
        return screenTimeController
    }
}
```

### 2. In PauseApp.swift registrieren
```swift
@main
struct PauseApp: App {
    // ...existing controllers...
    @StateObject private var myNewController: MyNewController
    
    init() {
        // ...existing setup...
        
        // Create new controller with dependencies
        let myNew = MyNewController(
            appState: state,
            screenTimeController: screenTime
        )
        
        _myNewController = StateObject(wrappedValue: myNew)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // ...existing environmentObjects...
                .environmentObject(myNewController)  // ✅ Hinzufügen
        }
    }
}
```

### 3. In Views verwenden
```swift
struct MyView: View {
    @EnvironmentObject private var myNewController: MyNewController
    
    var body: some View {
        // Verwende Controller
    }
}
```

---

## 🐛 Fehlerbehandlung

### Wenn du "not injected" Fehler siehst
```
Fatal error: AppState not injected - check PauseApp dependency setup
```

**Ursachen:**
1. ❌ Controller wurde nicht in `PauseApp.init()` erstellt
2. ❌ `.environmentObject()` fehlt in View-Hierarchie
3. ❌ Preview vergessen (siehe unten)

**Lösung:**
```swift
// 1. Prüfe PauseApp.swift
init() {
    let myController = MyController(appState: state, ...)
    _myController = StateObject(wrappedValue: myController)
}

// 2. Prüfe ContentView
ContentView()
    .environmentObject(appState)
    .environmentObject(myController)  // ✅ Hinzufügen

// 3. Prüfe Previews (siehe unten)
```

---

## 🎨 SwiftUI Previews

### Preview mit injizierten Dependencies
```swift
#Preview {
    // ✅ RICHTIG: Erstelle Test-Instanzen
    let selection = SelectionManager.shared
    let screenTime = ScreenTimeController(selectionManager: selection, appState: nil)
    let appState = AppState(screenTimeController: screenTime)
    screenTime.appState = appState
    
    let tagController = TagController(
        appState: appState,
        screenTimeController: screenTime,
        selectionManager: selection
    )
    
    return HomeView()
        .environmentObject(appState)
        .environmentObject(screenTime)
        .environmentObject(tagController)
}
```

### Preview Helper (optional)
```swift
// PreviewHelper.swift
struct PreviewDependencies {
    let appState: AppState
    let screenTimeController: ScreenTimeController
    let tagController: TagController
    let timeProfileController: TimeProfileController
    let selectionManager: SelectionManager
    
    static func create() -> PreviewDependencies {
        let selection = SelectionManager.shared
        let screenTime = ScreenTimeController(selectionManager: selection, appState: nil)
        let appState = AppState(screenTimeController: screenTime)
        screenTime.appState = appState
        
        let tag = TagController(
            appState: appState,
            screenTimeController: screenTime,
            selectionManager: selection
        )
        
        let timeProfile = TimeProfileController(
            appState: appState,
            screenTimeController: screenTime,
            selectionManager: selection
        )
        
        return PreviewDependencies(
            appState: appState,
            screenTimeController: screenTime,
            tagController: tag,
            timeProfileController: timeProfile,
            selectionManager: selection
        )
    }
}

// Verwendung:
#Preview {
    let deps = PreviewDependencies.create()
    
    return MyView()
        .environmentObject(deps.appState)
        .environmentObject(deps.tagController)
}
```

---

## 🔗 Dependency Graph

```
PauseApp
  ├─ SelectionManager (Singleton, legitimate)
  │
  ├─ ScreenTimeController
  │   ├─ selectionManager: SelectionManager
  │   └─ appState: AppState (weak, circular)
  │
  ├─ AppState
  │   └─ screenTimeController: ScreenTimeController (weak, circular)
  │
  ├─ TagController
  │   ├─ appState: AppState (weak)
  │   ├─ screenTimeController: ScreenTimeController (weak)
  │   └─ selectionManager: SelectionManager (weak)
  │
  └─ TimeProfileController
      ├─ appState: AppState (weak)
      ├─ screenTimeController: ScreenTimeController (weak)
      └─ selectionManager: SelectionManager (weak)
```

**Circular Dependencies:**
- `AppState` ↔ `ScreenTimeController` (resolved manually in PauseApp.init)

---

## 📚 Weitere Ressourcen

- `SINGLETON_REMOVAL_COMPLETE.md` - Vollständige Dokumentation
- `CODE_REVIEW_FINDINGS.md` - Ursprüngliche Analyse
- `MIGRATION_GUIDE_DI.md` - Migration Guide (falls vorhanden)

---

## ❓ FAQ

### Q: Warum ist SelectionManager noch ein Singleton?
**A:** `SelectionManager` ist ein **legitimes** Singleton, da es die zentrale Verwaltung aller FamilyActivitySelections und ManagedSettingsStores übernimmt. Es ist ein Service-Layer, kein Business-Logic-Controller.

### Q: Warum weak var für Dependencies?
**A:** `weak var` verhindert Retain Cycles, besonders wichtig bei zirkulären Abhängigkeiten (AppState ↔ ScreenTimeController).

### Q: Warum fatalError statt optional chaining?
**A:** `fatalError` zwingt zu korrekter DI während der Entwicklung. Fehler werden sofort entdeckt, nicht erst zur Laufzeit mit Silent Failures.

### Q: Kann ich neue Singletons erstellen?
**A:** Nur für **legitime Cases**:
- ✅ Hardware-Controller (NFC, Location, etc.)
- ✅ Persistenz-Layer
- ✅ System-Services
- ❌ Nicht für Business Logic!

---

**Stand:** 15. Januar 2026  
**Version:** 2.0 (DI-Architecture)
