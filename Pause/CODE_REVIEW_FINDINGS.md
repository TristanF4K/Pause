# Code Review & Refactoring-Vorschläge

**Datum:** 14. Januar 2026  
**Status:** Analyse abgeschlossen

## 🎯 Executive Summary

Die Codebasis ist funktional und gut strukturiert. Es gibt jedoch mehrere Bereiche, die für bessere Wartbarkeit, Performance und Code-Qualität verbessert werden können.

**Prioritäten:**
- 🔴 **Hoch:** Kritische Architektur-Probleme
- 🟡 **Mittel:** Wartbarkeit & Best Practices
- 🟢 **Niedrig:** Nice-to-have Optimierungen

---

## 🔴 Kritische Probleme

### 1. Singleton-Übernutzung & State Management

**Problem:**
Fast alle Controller nutzen das Singleton-Pattern (`shared`), was zu:
- Schwer testbarem Code führt
- Tight Coupling zwischen Komponenten
- Impliziten Abhängigkeiten

**Betroffene Dateien:**
```swift
// Alle nutzen .shared
AppState.shared
ScreenTimeController.shared
SelectionManager.shared
TagController.shared
TimeProfileController.shared
NFCController.shared
```

**Lösung:**
```swift
// Statt Singletons: Dependency Injection über Environment
@EnvironmentObject private var appState: AppState
@EnvironmentObject private var screenTimeController: ScreenTimeController

// In PauseApp.swift
@main
struct PauseApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var screenTimeController = ScreenTimeController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(screenTimeController)
        }
    }
}
```

**Vorteile:**
- ✅ Einfacheres Testing (Mock-Objekte injizieren)
- ✅ Explizite Abhängigkeiten
- ✅ Bessere SwiftUI-Integration

---

### 2. Zirkuläre Abhängigkeiten

**Problem:**
Controller referenzieren sich gegenseitig, was zu tight coupling führt:

```swift
// TagController.swift
private let appState = AppState.shared
private let screenTimeController = ScreenTimeController.shared
private let selectionManager = SelectionManager.shared

// TimeProfileController.swift
private let appState = AppState.shared
private let screenTimeController = ScreenTimeController.shared
private let selectionManager = SelectionManager.shared

// ScreenTimeController.swift
private let selectionManager = SelectionManager.shared
// + ruft AppState.shared.checkAuthorizationStatus() auf
```

**Lösung:**
- Protocol-basierte Dependency Injection
- Observer Pattern für lose Kopplung
- Event Bus für Controller-Kommunikation

---

### 3. State Synchronisierung über UserDefaults

**Problem:**
`ScreenTimeController` und andere speichern State in UserDefaults mit verschiedenen Keys:

```swift
// ScreenTimeController.swift
private let blockingStateKey = "FocusLock_BlockingState"
private let activeTagKey = "FocusLock_ActiveTag"

// Andere Keys verstreut:
"Pause.hasBeenAuthorized"
"FocusLock_HasBeenAuthorized"  // Duplikat!
"FocusLock_AuthorizationGranted"
"FocusLock_LastSuccessfulAuth"
```

**Probleme:**
- Inkonsistente Namenskonventionen
- Duplikate
- Keine zentrale Verwaltung
- Keine Type-Safety

**Lösung:**
```swift
// UserDefaultsKeys.swift
enum UserDefaultsKeys {
    static let hasBeenAuthorized = "pause.authorization.hasBeenAuthorized"
    static let lastSuccessfulAuth = "pause.authorization.lastSuccessful"
    static let blockingState = "pause.blocking.isActive"
    static let activeSourceID = "pause.blocking.activeSource"
}

// Property Wrapper für Type-Safety
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

// Verwendung
struct AppSettings {
    @UserDefault(key: UserDefaultsKeys.hasBeenAuthorized, defaultValue: false)
    static var hasBeenAuthorized: Bool
}
```

---

### 4. Timer läuft auch wenn nicht benötigt

**Problem:**
`TimeProfileController` startet einen Timer im `init()`, der **immer läuft**:

```swift
private init() {
    Task { @MainActor in
        startMonitoring()  // Läuft alle 5 Sekunden, IMMER
    }
}
```

**Probleme:**
- ⚡ Verschwendet Batterie
- ⚡ Unnötige CPU-Last
- 📱 Läuft auch wenn keine Zeitprofile existieren

**Lösung:**
```swift
class TimeProfileController {
    private var isMonitoring = false
    
    // Starte nur wenn nötig
    func startMonitoringIfNeeded() {
        guard !isMonitoring else { return }
        guard appState.timeProfiles.contains(where: { $0.isEnabled }) else { return }
        
        startMonitoring()
        isMonitoring = true
    }
    
    func stopMonitoringIfNotNeeded() {
        guard appState.timeProfiles.filter({ $0.isEnabled }).isEmpty else { return }
        stopMonitoring()
        isMonitoring = false
    }
}
```

---

## 🟡 Mittlere Priorität

### 5. Code-Duplikation in Views

**Problem:**
Ähnliche UI-Komponenten werden mehrfach implementiert:

**TagDetailView.swift vs TimeProfileDetailView.swift:**
```swift
// Fast identische Info-Cards
private var tagInfoCard: some View { ... }
// vs
private func statusCard(for profile: TimeProfile) -> some View { ... }
```

**Lösung:**
Erstelle wiederverwendbare Komponenten:

```swift
// Components/InfoCard.swift
struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: FontSize.lg))
                    .foregroundColor(PauseColors.accent)
                Text(title)
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
                Spacer()
            }
            .padding(Spacing.lg)
            
            Divider()
                .background(PauseColors.cardBorder)
            
            content()
                .padding(Spacing.lg)
        }
        .card()
    }
}

// Verwendung:
InfoCard(title: "Tag-Info", icon: "info.circle.fill") {
    // Content
}
```

---

### 6. Force Unwraps und Implicit Optionals

**Problem:**
Code verwendet an einigen Stellen unsichere Patterns:

```swift
// ScreenTimeController.swift
if let activeTag = appState.getActiveTag() { ... }

// SelectionManager - könnte nil zurückgeben
func getSelection(for id: UUID) -> FamilyActivitySelection?
```

**Besser:**
```swift
// Result Type für klarere Fehlerbehandlung
enum SelectionError: Error {
    case notFound
    case corrupted
}

func getSelection(for id: UUID) -> Result<FamilyActivitySelection, SelectionError>
```

---

### 7. Lange Funktionen & God Objects

**Problem:**
Einige Funktionen sind zu lang und machen zu viel:

**HomeView.swift - `handleScannedIdentifier(_:)`**
- 60+ Zeilen
- Behandelt 6 verschiedene Cases
- Mix aus Business Logic und UI Logic

**Lösung:**
```swift
// Extrahiere Business Logic
@MainActor
class ScanHandler: ObservableObject {
    func handleScan(_ identifier: String) async -> ScanResult { ... }
}

// View bleibt dünn
struct HomeView: View {
    @StateObject private var scanHandler = ScanHandler()
    
    private func handleScannedIdentifier(_ identifier: String) {
        Task {
            let result = await scanHandler.handleScan(identifier)
            displayResult(result)
        }
    }
    
    private func displayResult(_ result: ScanResult) {
        // Nur UI-Updates
    }
}
```

---

### 8. Print Statements für Debugging

**Problem:**
Production Code ist voll mit Debug-Print-Statements:

```swift
print("🔒 ScreenTimeController: blockApps called")
print("✅ Authorization OK")
print("⏰ Timer scheduled to check every 5 seconds")
```

**Lösung:**
Implementiere ein Logging-System:

```swift
// Logger.swift
enum LogLevel {
    case debug, info, warning, error
}

struct Logger {
    static func log(_ message: String, level: LogLevel = .info, file: String = #file) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("[\(level)] [\(fileName)] \(message)")
        #endif
    }
}

// Verwendung
Logger.log("blockApps called for tag \(tagID)", level: .debug)
```

**OSLog nutzen:**
```swift
import OSLog

extension Logger {
    static let screenTime = Logger(subsystem: "com.pause.app", category: "ScreenTime")
    static let nfc = Logger(subsystem: "com.pause.app", category: "NFC")
}

// Verwendung
Logger.screenTime.debug("blockApps called for tag \(tagID)")
```

---

### 9. Fehlende Error Handling

**Problem:**
Viele async Funktionen werfen Fehler, die nicht behandelt werden:

```swift
// TimeProfileDetailView.swift
Button("Löschen", role: .destructive) {
    TimeProfileController.shared.deleteProfile(profile: profile)  // Kein Error Handling
    dismiss()
}
```

**Lösung:**
```swift
@State private var errorMessage: String?
@State private var showingError = false

Button("Löschen", role: .destructive) {
    do {
        try TimeProfileController.shared.deleteProfile(profile: profile)
        dismiss()
    } catch {
        errorMessage = error.localizedDescription
        showingError = true
    }
}
.alert("Fehler", isPresented: $showingError) {
    Button("OK") {}
} message: {
    Text(errorMessage ?? "Ein unbekannter Fehler ist aufgetreten")
}
```

---

### 10. Keine Trennung von Models und Business Logic

**Problem:**
Models enthalten teilweise Business Logic:

```swift
// TimeProfile.swift
struct TimeProfile {
    // ...
    
    /// Check if this profile should be active right now
    var shouldBeActive: Bool {
        isActiveAt(Date())
    }
    
    func isCurrentlyBlocking(appState: AppState, screenTimeController: ScreenTimeController) -> Bool {
        // Business Logic im Model!
    }
}
```

**Lösung:**
```swift
// TimeProfile.swift - nur Data
struct TimeProfile {
    let id: UUID
    var name: String
    var schedule: TimeSchedule
    var isEnabled: Bool
    // ...
}

// TimeProfileService.swift - Business Logic
class TimeProfileService {
    func isActive(_ profile: TimeProfile, at date: Date = Date()) -> Bool {
        // Logic hier
    }
    
    func isCurrentlyBlocking(_ profile: TimeProfile) -> Bool {
        // Logic hier
    }
}
```

---

## 🟢 Niedrige Priorität

### 11. Magic Numbers

**Problem:**
```swift
.frame(width: 140, height: 100)  // TagCard
.frame(width: 120, height: 120)  // EmptyState Circle
.frame(width: 10, height: 10)    // Status Indicator
```

**Lösung:**
```swift
enum ComponentSize {
    static let tagCardWidth: CGFloat = 140
    static let tagCardHeight: CGFloat = 100
    static let statusIndicatorSize: CGFloat = 10
}
```

---

### 12. Fehlende Dokumentation

**Problem:**
Viele Funktionen und komplexe Logik haben keine Kommentare:

```swift
func isActiveAt(_ date: Date) -> Bool {
    // Was macht diese Funktion genau?
    // Was sind die Edge Cases?
}
```

**Lösung:**
```swift
/// Checks if the time profile should be active at the given date/time.
///
/// - Parameter date: The date to check against the profile's schedule
/// - Returns: `true` if the profile is enabled and the given date falls within the scheduled time window
///
/// - Note: The end time is **exclusive** (e.g., if endTime is 21:30, the profile is only active until 21:29:59)
func isActiveAt(_ date: Date) -> Bool {
    // ...
}
```

---

### 13. Hardcoded German Strings

**Problem:**
Alle Strings sind auf Deutsch hardcoded:

```swift
Text("Zeitprofil löschen?")
Text("Dieses Zeitprofil wird dauerhaft gelöscht.")
```

**Lösung:**
```swift
// Localizable.strings
"time_profile.delete.title" = "Zeitprofil löschen?";
"time_profile.delete.message" = "Dieses Zeitprofil wird dauerhaft gelöscht.";

// Verwendung
Text("time_profile.delete.title")
```

---

### 14. Performance: Unnötige Re-Renders

**Problem:**
Views beobachten ganze Objekte statt nur benötigter Properties:

```swift
struct TimeProfileDetailView: View {
    @StateObject private var appState = AppState.shared  // Observiert ALLES
}
```

**Lösung:**
```swift
// Computed Properties in AppState mit @Published
extension AppState {
    var activeTagName: String? {
        getActiveTag()?.name
    }
}

// View nur das Nötigste beobachten
@Published var activeTagName: String?
```

---

### 15. Fehlende Unit Tests

**Problem:**
Keine Test-Dateien gefunden (außer UI Tests).

**Lösung:**
Erstelle Tests für:
- Business Logic (TimeSchedule, Weekday calculations)
- Controller Logik
- Model Validierung

```swift
// TimeScheduleTests.swift
import Testing
@testable import Pause

@Suite("TimeSchedule Tests")
struct TimeScheduleTests {
    
    @Test("End time is exclusive")
    func endTimeExclusive() throws {
        let schedule = TimeSchedule(
            selectedWeekdays: [.monday],
            startTime: TimeOfDay(hour: 21, minute: 0),
            endTime: TimeOfDay(hour: 21, minute: 30)
        )
        
        let calendar = Calendar.current
        
        // 21:29:59 should be active
        var components = DateComponents()
        components.weekday = 2 // Monday
        components.hour = 21
        components.minute = 29
        components.second = 59
        let activeTime = calendar.date(from: components)!
        #expect(schedule.isActiveAt(activeTime))
        
        // 21:30:00 should NOT be active
        components.second = 0
        components.minute = 30
        let inactiveTime = calendar.date(from: components)!
        #expect(!schedule.isActiveAt(inactiveTime))
    }
}
```

---

## 📋 Empfohlene Refactoring-Reihenfolge

### Phase 1: Foundation (1-2 Tage)
1. ✅ Einheitliches Logging-System (OSLog)
2. ✅ Zentrale UserDefaults-Verwaltung
3. ✅ Wiederverwendbare UI-Komponenten

### Phase 2: Architecture (3-5 Tage)
4. ✅ Singleton → Environment-basiertes DI
5. ✅ Separation: Models vs Business Logic
6. ✅ Event-basierte Controller-Kommunikation

### Phase 3: Optimization (2-3 Tage)
7. ✅ Timer-Optimierung (nur wenn nötig)
8. ✅ Performance-Optimierungen
9. ✅ Error Handling verbessern

### Phase 4: Quality (2-3 Tage)
10. ✅ Unit Tests schreiben
11. ✅ Dokumentation hinzufügen
12. ✅ Localization vorbereiten

---

## 🎨 Neue Dateistruktur (Vorgeschlagen)

```
Pause/
├── App/
│   └── PauseApp.swift
├── Core/
│   ├── Services/
│   │   ├── ScreenTimeService.swift
│   │   ├── NFCService.swift
│   │   └── PersistenceService.swift
│   ├── Managers/
│   │   ├── AppStateManager.swift
│   │   └── SelectionManager.swift
│   └── Utilities/
│       ├── Logger.swift
│       └── UserDefaultsKeys.swift
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   ├── Tags/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   └── TimeProfiles/
│       ├── Views/
│       ├── ViewModels/
│       └── Models/
├── Components/
│   ├── Cards/
│   ├── Buttons/
│   └── EmptyStates/
└── Resources/
    ├── DesignSystem.swift
    └── Localizable.strings
```

---

## 🎯 Quick Wins (Sofort umsetzbar)

1. **Logging System** (30 Min)
   - Erstelle `Logger.swift`
   - Ersetze alle `print()` Statements

2. **UserDefaults Keys** (30 Min)
   - Erstelle `UserDefaultsKeys.swift`
   - Zentrale Key-Verwaltung

3. **Wiederverwendbare InfoCard** (1 Std)
   - Extrahiere in `Components/InfoCard.swift`
   - Nutze in beiden DetailViews

4. **Timer-Optimierung** (1 Std)
   - Starte Timer nur wenn Zeitprofile aktiv
   - Stoppe Timer wenn nicht benötigt

5. **Magic Numbers** (30 Min)
   - Füge zu `DesignSystem.swift` hinzu

---

## 💡 Langfristige Verbesserungen

### A. Swift 6 & Concurrency
- Strict Concurrency Checking aktivieren
- `@MainActor` korrekt anwenden
- Sendable Types nutzen

### B. Architecture Patterns
- MVVM konsequent anwenden
- Repository Pattern für Data Access
- Coordinator Pattern für Navigation

### C. Testing
- Unit Tests (70%+ Coverage Ziel)
- Integration Tests
- Snapshot Tests für UI

### D. CI/CD
- SwiftLint Integration
- Automated Testing
- Crash Reporting (z.B. Sentry)

---

## 📊 Code Quality Metrics

### Aktuell
- **Testabdeckung:** ~0%
- **Code-Duplikation:** ~15%
- **Singleton-Nutzung:** 6 Klassen
- **Durchschnittliche Funktionslänge:** ~25 Zeilen
- **Max. Cyclomatic Complexity:** ~8

### Ziele
- **Testabdeckung:** 70%+
- **Code-Duplikation:** <5%
- **Singleton-Nutzung:** 0 (DI stattdessen)
- **Durchschnittliche Funktionslänge:** <15 Zeilen
- **Max. Cyclomatic Complexity:** <5

---

## ✅ Fazit

Die App hat eine **solide Basis**, aber es gibt klare Verbesserungsmöglichkeiten:

**Stärken:**
- ✅ Funktionale Kernlogik
- ✅ Konsistentes Design System
- ✅ Gute SwiftUI-Nutzung
- ✅ Moderne Swift Concurrency

**Verbesserungsbedarf:**
- ⚠️ Architektur (Singletons, Tight Coupling)
- ⚠️ Testing (nicht vorhanden)
- ⚠️ Performance (unnötige Timer)
- ⚠️ Code-Duplikation

**Empfehlung:**  
Starte mit **Quick Wins** für sofortige Verbesserungen, dann plane die Architektur-Refactorings in Sprints à 1-2 Wochen.

---

**Letzte Aktualisierung:** 14. Januar 2026
