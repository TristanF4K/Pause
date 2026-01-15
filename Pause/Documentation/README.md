# Pause. 🔒

Eine iOS App, die NFC-Tags nutzt, um Apps über Apples Screen Time API zu blockieren und zu entsperren.

## Übersicht

Pause. ermöglicht es dir, deine Bildschirmzeit selbst zu kontrollieren, indem du NFC-Tags verwendest, um Apps zu blockieren oder zu entsperren. Tippe einfach dein iPhone an einen registrierten NFC-Tag, und die verknüpften Apps werden automatisch gesperrt oder freigegeben.

## Features

- ✅ **NFC Tag Integration** - Verwende NFC-Tags zur Kontrolle deiner App-Nutzung
- ✅ **Screen Time API** - Native Integration mit Apple's Screen Time
- ✅ **Tag-Verwaltung** - Registriere und verwalte mehrere NFC-Tags
- ✅ **App-Auswahl** - Wähle aus, welche Apps blockiert werden sollen
- ✅ **Toggle-Funktion** - Ein Tag-Scan aktiviert/deaktiviert die Blockierung
- ✅ **Status-Dashboard** - Sieh auf einen Blick, ob Apps blockiert sind

## Architektur

### MVC Pattern

```
Pause./
├── Models/
│   ├── NFCTag.swift              # NFC Tag Datenmodell
│   ├── BlockingProfile.swift     # Blockier-Profil
│   └── AppState.swift            # App-weiter State
│
├── Views/
│   ├── ContentView.swift         # Tab-Navigation
│   ├── Home/
│   │   └── HomeView.swift        # Dashboard
│   ├── Tags/
│   │   ├── TagListView.swift    # Tag-Liste
│   │   ├── AddTagView.swift     # Tag hinzufügen
│   │   └── TagDetailView.swift  # Tag bearbeiten
│   ├── Scan/
│   │   └── ScanView.swift       # NFC Scan Interface
│   ├── Settings/
│   │   └── SettingsView.swift   # Einstellungen
│   └── Components/
│       ├── StatusCardView.swift # Status-Anzeige
│       ├── TagCard.swift        # Tag-Karte
│       └── EmptyStateView.swift # Empty States
│
└── Controllers/
    ├── NFCController.swift           # NFC-Verwaltung
    ├── ScreenTimeController.swift    # Screen Time API
    ├── TagController.swift           # Tag-Logik
    └── PersistenceController.swift   # Datenspeicherung
```

## Technologie-Stack

- **SwiftUI** - Moderne, deklarative UI
- **Core NFC** - NFC Tag lesen/schreiben
- **FamilyControls** - Screen Time Autorisierung
- **ManagedSettings** - App-Beschränkungen
- **Combine** - Reaktive Programmierung

## Anforderungen

- iOS 16.0+ (iOS 18+ für Individual Authorization empfohlen)
- Xcode 15.0+
- iPhone 7 oder neuer (für NFC)
- Physisches Gerät (Simulator unterstützt kein NFC)
- Apple Developer Account (für Capabilities)

## Setup

Siehe [SETUP_GUIDE.md](SETUP_GUIDE.md) für detaillierte Anweisungen.

### Schnellstart

1. **Projekt öffnen** in Xcode
2. **Capabilities aktivieren**:
   - Family Controls
   - Near Field Communication Tag Reading
3. **Info.plist aktualisieren** (siehe SETUP_GUIDE.md)
4. **Auf physischem Gerät testen**

## Verwendung

### 1. Tag registrieren
1. Öffne Pause.
2. Tippe auf "Tag hinzufügen"
3. Scanne einen NFC-Tag
4. Gib dem Tag einen Namen
5. Wähle Apps zum Blockieren aus

### 2. Apps blockieren
1. Tippe dein iPhone an den registrierten Tag
2. Apps werden sofort blockiert
3. Status wird auf dem Dashboard angezeigt

### 3. Apps entsperren
1. Tippe dein iPhone erneut an denselben Tag
2. Blockierung wird aufgehoben
3. Apps sind wieder nutzbar

## Code-Struktur

### Models

**NFCTag**
```swift
struct NFCTag {
    let id: UUID
    var name: String
    var tagIdentifier: String
    var linkedAppTokens: Set<String>
    var linkedCategoryTokens: Set<String>
    var isActive: Bool
}
```

**AppState**
```swift
@MainActor
class AppState: ObservableObject {
    @Published var isAuthorized: Bool
    @Published var registeredTags: [NFCTag]
    @Published var isBlocking: Bool
}
```

### Controllers

**NFCController**
- Verwaltet NFC-Sessions
- Liest Tag-IDs aus
- Behandelt Fehler und Abbrüche

**ScreenTimeController**
- Verwaltet Screen Time Autorisierung
- Blockiert/entsperrt Apps
- Verwendet ManagedSettingsStore

**TagController**
- Tag-Registrierung
- Tag-App-Verknüpfung
- Scan-Logik (Toggle)

## Erweiterungsmöglichkeiten

### Phase 2
- [ ] Mehrere Profile pro Tag
- [ ] Zeitbasierte Regeln
- [ ] Widgets für Quick Actions
- [ ] DeviceActivity Reports
- [ ] iCloud Sync

### Phase 3
- [ ] Onboarding-Flow
- [ ] Erweiterte Animationen
- [ ] Lokalisierung (EN/FR/ES)
- [ ] Website-Blocking
- [ ] Statistiken und Reports

## Bekannte Einschränkungen

1. **NFC-Hintergrund**: Scanning funktioniert nur im Vordergrund
2. **System-Apps**: Manche System-Apps können nicht blockiert werden
3. **User-Kontrolle**: Nutzer kann Screen Time in Einstellungen deaktivieren
4. **Token-Persistenz**: ApplicationTokens können nicht direkt gespeichert werden

## Fehlerbehebung

### NFC funktioniert nicht
- Physisches Gerät verwenden (kein Simulator)
- Info.plist NFCReaderUsageDescription prüfen
- Capability aktiviert?
- Kompatiblen Tag verwenden (NTAG213/215/216)

### Screen Time Authorization schlägt fehl
- Settings > Screen Time aktivieren
- "Apps with Screen Time Access" prüfen
- iOS-Version überprüfen (16+)

## Lizenz

Dieses Projekt ist ein Beispiel-/Lernprojekt. Verwende es nach Belieben.

## Support

Bei Fragen oder Problemen:
- Siehe [SETUP_GUIDE.md](SETUP_GUIDE.md)
- Apple Developer Dokumentation
- Screen Time API Referenz

## Autor

Created by Tristan Srebot, Januar 2026

---

**Hinweis**: Diese App verwendet Apple's Screen Time API, die Nutzer jederzeit in den Einstellungen deaktivieren können. Pause. ist ein Tool zur Selbstkontrolle, keine absolute Sperre.
