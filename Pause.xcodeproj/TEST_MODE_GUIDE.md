# Test-Modus Dokumentation

## Übersicht

Der Test-Modus ermöglicht es Ihnen, die FocusLock-App ohne physische NFC-Tags zu testen. Dies ist besonders nützlich während der Entwicklung und für UI-Tests.

## Zugriff auf den Test-Modus

1. **Debug-Build erforderlich**: Der Test-Modus ist nur in Debug-Builds verfügbar (nicht in Release-Builds)
2. **Hammer-Symbol**: In der HomeView sehen Sie oben rechts ein oranges Hammer-Symbol 🔨
3. **Tippen Sie darauf**, um den Test-Modus zu öffnen

## Funktionen

### Test-Tags erstellen

- Erstellt 4 vordefinierte Test-Tags:
  - 🏢 Büro
  - 🏠 Zuhause
  - 🎯 Fokus-Zeit
  - 😴 Schlafzimmer
- Diese Tags haben spezielle Test-Identifikatoren (TEST-OFFICE-001, etc.)
- Funktioniert nur, wenn noch keine Tags existieren

### Tag-Scan simulieren

- Liste aller registrierten Tags
- Tippen Sie auf einen Tag, um einen NFC-Scan zu simulieren
- Aktiviert/Deaktiviert das Blocking genau wie ein echter Scan
- Gibt haptisches Feedback
- Zeigt Status mit grünem Häkchen an

### Alle Tags löschen

- Löscht alle registrierten Tags auf einmal
- Nützlich zum Zurücksetzen der Test-Umgebung
- Warnt vor dem Löschen

### Debug-Informationen

Zeigt aktuelle Status-Informationen:
- Blocking-Status (🔒 Blockiert / 🔓 Entsperrt)
- Aktives Profil
- Anzahl blockierter Apps
- Anzahl registrierter Tags

## Workflow für Tests

### 1. Erste Einrichtung

```
1. Öffnen Sie die App auf Ihrem iPhone
2. Tippen Sie auf das Hammer-Symbol 🔨
3. Tippen Sie auf "Test-Tags erstellen"
4. Bestätigen Sie mit "Erstellen"
```

### 2. Apps zu Test-Tags verknüpfen

```
1. Gehen Sie zum "Tags" Tab
2. Wählen Sie einen Test-Tag (z.B. "🏢 Büro")
3. Tippen Sie auf "Apps auswählen"
4. Wählen Sie die Apps, die blockiert werden sollen
5. Speichern Sie die Auswahl
```

### 3. Blocking testen

```
1. Öffnen Sie den Test-Modus (Hammer-Symbol)
2. Unter "Scan simulieren" tippen Sie auf einen Tag
3. Die App sollte nun blockieren (🔒 Symbol wird angezeigt)
4. Tippen Sie erneut auf denselben Tag, um zu deaktivieren
```

### 4. Verschiedene Szenarien testen

```
- Wechseln Sie zwischen verschiedenen Tags
- Überprüfen Sie, ob die richtigen Apps blockiert werden
- Testen Sie mit verschiedenen App-Kombinationen
- Überprüfen Sie die UI-Änderungen in der HomeView
```

## Unterschiede zu echten NFC-Tags

### Was funktioniert:
✅ Blocking aktivieren/deaktivieren
✅ App-Verknüpfungen
✅ UI-Updates
✅ Status-Anzeigen
✅ Haptic Feedback

### Was nicht simuliert wird:
❌ NFC-Hardware-Erkennung
❌ Physische Tag-Nähe
❌ NFC-Fehlermeldungen
❌ Tag-Schreibvorgänge

## Zurücksetzen

Um die Test-Umgebung zurückzusetzen:

```
1. Öffnen Sie den Test-Modus
2. Tippen Sie auf "Alle Tags löschen"
3. Bestätigen Sie mit "Löschen"
4. Erstellen Sie bei Bedarf neue Test-Tags
```

## Hinweise

- Der Test-Modus ist automatisch **nur in Debug-Builds** aktiv
- In Release-Builds erscheint der Hammer-Button nicht
- Test-Tags haben den Präfix `TEST-` in ihrer Identifier
- Sie können Test-Tags und echte NFC-Tags nicht gleichzeitig verwenden
- Alle Test-Daten werden normal in UserDefaults gespeichert

## Troubleshooting

**Problem**: Hammer-Symbol wird nicht angezeigt
- **Lösung**: Stellen Sie sicher, dass Sie einen Debug-Build verwenden

**Problem**: "Test-Tags erstellen" ist deaktiviert
- **Lösung**: Löschen Sie zuerst alle vorhandenen Tags

**Problem**: Blocking funktioniert nicht
- **Lösung**: Überprüfen Sie, ob Screen Time Autorisierung erteilt wurde

**Problem**: Keine Apps verknüpft
- **Lösung**: Gehen Sie zur Tag-Detail-Ansicht und wählen Sie Apps aus
