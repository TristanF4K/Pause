# Background Tasks Setup für Zeitprofile

## Problem
Zeitprofile aktivieren sich erst, wenn die App geöffnet wird, weil der Timer nur im Vordergrund läuft.

## Lösung
Implementation von Background Tasks und Notifications, um Zeitprofile auch im Hintergrund zu aktivieren.

## Bereits implementierte Code-Änderungen

### ✅ TimeProfileController.swift
- Import von `BackgroundTasks` und `UserNotifications`
- Background Task Registrierung
- Notification Scheduling für kommende Aktivierungen
- Background Refresh alle 15 Minuten

### ✅ TimeProfile.swift
- Neue Funktion `nextActivationDate(after:)` zum Berechnen der nächsten Aktivierungszeit

### ✅ PauseApp.swift
- Import von `BackgroundTasks`
- `onAppear` Handler zum Prüfen von Profilen beim App-Start

## 📋 Notwendige manuelle Schritte

### 1. Info.plist konfigurieren

Füge folgendes zu deiner `Info.plist` hinzu:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.pause.timeprofile.check</string>
</array>

<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
    <string>remote-notification</string>
</array>
```

**Alternativ in Xcode:**
1. Öffne dein Projekt in Xcode
2. Wähle dein App-Target aus
3. Gehe zu "Signing & Capabilities"
4. Klicke auf "+ Capability"
5. Füge "Background Modes" hinzu
6. Aktiviere folgende Checkboxen:
   - ✅ Background processing
   - ✅ Remote notifications (optional, für zukünftige Features)

7. Dann zu "Info" Tab:
8. Füge einen neuen Key hinzu: `BGTaskSchedulerPermittedIdentifiers`
9. Type: Array
10. Füge ein Item hinzu: `com.pause.timeprofile.check`

### 2. Notification Permissions

Die App fragt automatisch nach Notification-Berechtigung beim ersten Start. Der Benutzer sollte dies erlauben, um Benachrichtigungen zu erhalten, wenn ein Zeitprofil aktiviert wird.

## 🎯 Wie es funktioniert

### Im Vordergrund
- Timer prüft alle 5 Sekunden, ob ein Zeitprofil aktiviert werden soll
- Sofortige Aktivierung/Deaktivierung

### Im Hintergrund
1. **Background Refresh**: iOS führt die App alle ~15 Minuten im Hintergrund aus
2. **Notifications**: Benutzer wird benachrichtigt, wenn ein Profil aktiviert wird
3. **Automatische Aktivierung**: Profil wird im Hintergrund aktiviert

### Einschränkungen
iOS Background Tasks haben Einschränkungen:
- Nicht garantiert genau zur geplanten Zeit
- Kann von iOS verzögert werden (Batterie, System-Load)
- Funktioniert am besten, wenn App regelmäßig benutzt wird
- **Wichtig**: Benutzer sollte Background App Refresh aktiviert haben (Einstellungen → Allgemein → Hintergrundaktualisierung)

## 🧪 Testen

### Simulator Testing
Im Simulator kannst du Background Tasks manuell auslösen:

```bash
# Simuliere Background App Refresh
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.pause.timeprofile.check"]
```

Oder über Xcode:
1. App starten
2. App in Hintergrund senden (Home Button)
3. In Xcode: Debug → Simulate Background Fetch

### Device Testing
1. Erstelle ein Zeitprofil mit naher Startzeit (z.B. in 5 Minuten)
2. Aktiviere das Profil
3. Schließe die App komplett
4. Warte bis zur Startzeit
5. Die App sollte automatisch aktivieren und eine Notification senden

**Wichtig**: 
- Background App Refresh muss aktiviert sein (Einstellungen → Allgemein → Hintergrundaktualisierung)
- Gerät sollte aufgeladen sein oder gute Batterie haben
- App sollte kürzlich benutzt worden sein

## 🔧 Troubleshooting

### "Background task didn't run"
- Prüfe ob Background Modes in Capabilities aktiviert sind
- Prüfe ob `BGTaskSchedulerPermittedIdentifiers` korrekt in Info.plist ist
- iOS kann Background Tasks verzögern, besonders bei niedriger Batterie
- App sollte nicht zu oft im Hintergrund geschlossen werden

### "Notification doesn't appear"
- Prüfe Notification-Berechtigung in iOS Einstellungen
- Prüfe ob "Do Not Disturb" aktiviert ist
- Prüfe ob die App Notifications erlaubt sind

### "Profile activates late"
- Background Tasks sind nicht präzise timed
- iOS optimiert für Batterie und System-Performance
- Für sofortige Aktivierung muss App im Vordergrund sein

## ⚡ Performance

- Timer läuft nur bei aktivierten Profilen
- Background Task wird nur scheduled wenn nötig
- Notifications werden nur für zukünftige Aktivierungen geplant
- Minimaler Batterie-Verbrauch durch iOS-optimierte Background Execution

## 📝 Nächste Schritte

Optional könntest du noch hinzufügen:
1. **Silent Notifications**: Push von Server für garantierte Aktivierung
2. **Location-Based**: Aktivierung basierend auf Standort (z.B. "Bei der Arbeit")
3. **Intent Extensions**: Siri Shortcuts für Zeitprofile
4. **Widgets**: Anzeige aktiver/kommender Profile

## ✅ Fertig!

Nach dem Hinzufügen der Info.plist Einträge sollten Zeitprofile auch im Hintergrund funktionieren!
