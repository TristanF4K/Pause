# Test-Modus - Schnellstart

## 🚀 So nutzen Sie den Test-Modus

Der Test-Modus ist perfekt, um die App ohne physische NFC-Tags zu testen!

### Schritt 1: Test-Modus öffnen
- Oben rechts in der Home-View finden Sie ein **oranges Hammer-Symbol** 🔨
- Tippen Sie darauf

### Schritt 2: Test-Tags erstellen
- Tippen Sie auf **"Test-Tags erstellen"**
- Bestätigen Sie mit **"Erstellen"**
- 4 Test-Tags werden automatisch angelegt:
  - 🏢 Büro
  - 🏠 Zuhause
  - 🎯 Fokus-Zeit
  - 😴 Schlafzimmer

### Schritt 3: Apps mit einem Tag verknüpfen
- Gehen Sie zum **"Tags"** Tab (unten in der Navigation)
- Wählen Sie einen Tag aus (z.B. "🏢 Büro")
- Tippen Sie auf **"Apps auswählen"**
- Wählen Sie die Apps, die blockiert werden sollen
- Speichern Sie die Auswahl

### Schritt 4: Tag-Scan simulieren
- Öffnen Sie wieder den Test-Modus (Hammer-Symbol 🔨)
- Unter **"Scan simulieren"** sehen Sie alle Ihre Tags
- **Tippen Sie auf einen Tag**, um einen Scan zu simulieren
- Das Blocking wird aktiviert 🔒
- Tippen Sie erneut, um es zu deaktivieren 🔓

## 📋 Features

✅ Test-Tags erstellen ohne NFC-Chip
✅ Tag-Scans manuell simulieren
✅ Blocking aktivieren/deaktivieren
✅ Debug-Informationen anzeigen
✅ Alle Tags auf einmal löschen

## ⚙️ Wichtige Hinweise

- Der Test-Modus ist **nur in Debug-Builds** sichtbar
- Sie können keine Test-Tags erstellen, wenn bereits Tags existieren
- Test-Tags haben spezielle IDs (beginnen mit "TEST-")
- Funktioniert genau wie echte NFC-Tags, nur ohne Hardware

## 🎯 Typischer Test-Workflow

```
1. Test-Tags erstellen
2. Apps mit Tags verknüpfen (über Tag-Detail-View)
3. Im Test-Modus auf einen Tag tippen
4. Überprüfen, ob das Blocking funktioniert
5. Verschiedene Tags ausprobieren
6. Bei Bedarf: Alle Tags löschen und neu starten
```

## 💡 Tipp

Wenn Sie zwischen Test-Tags und echten NFC-Tags wechseln möchten:
1. Öffnen Sie den Test-Modus
2. Tippen Sie auf "Alle Tags löschen"
3. Jetzt können Sie entweder neue Test-Tags erstellen ODER echte NFC-Tags scannen

Viel Spaß beim Testen! 🎉
