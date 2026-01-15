# 🚀 App Store Deployment Checkliste - Pause.

**Status**: Pre-Launch  
**Version**: 1.0.0  
**Erstellt**: 07.01.2026  
**Letzte Aktualisierung**: 07.01.2026

---

## 📱 App-Grundlagen

### ✅ Bereits vorhanden
- [x] App-Name definiert: "Pause."
- [x] Grundfunktionalität implementiert (NFC + Screen Time)
- [x] SwiftUI moderne UI
- [x] iOS 16+ Zielversion
- [x] MVC Architektur

### ❌ Noch zu erledigen

#### App-Icons & Assets
- [x] **App Icon erstellen** (alle erforderlichen Größen)
  - [x] 1024x1024px (App Store)
  - [x] 180x180px (iPhone)
  - [x] 120x120px (iPhone)
  - [x] 87x87px (Settings)
  - [x] 60x60px (Spotlight)
  - [x] 40x40px (Notifications)
  - **Tool-Empfehlung**: [AppIconizer](https://appicon.co/) oder Sketch/Figma
  
- [ ] **Launch Screen optimieren**
  - [ ] Schöne Splash-Screen mit Logo
  - [ ] Dark Mode Unterstützung
  - [ ] Animation (optional)

- [ ] **App Screenshots erstellen** (für App Store)
  - [ ] iPhone 6.9" (iPhone 16 Pro Max): mindestens 3
  - [ ] iPhone 6.7" (iPhone 16 Plus): mindestens 3
  - [ ] iPhone 6.5" (iPhone 15 Pro Max): mindestens 3
  - [ ] Optional: iPad Screenshots
  - **Content**: Zeige Hauptfunktionen (Tag hinzufügen, Scannen, Dashboard)

---

## 📝 App Store Connect

### Apple Developer Account
- [x] **Apple Developer Program Mitgliedschaft** (99€/Jahr)
  - Registrierung: [developer.apple.com](https://developer.apple.com)
  - Wichtig: Ohne Membership keine App Store Veröffentlichung!

### App Store Connect Setup
- [ ] **App erstellen** in App Store Connect
  - [ ] Bundle Identifier festlegen (z.B. `com.tristansrebot.pause`)
  - [ ] SKU vergeben
  - [ ] Primary Language: Deutsch (oder Englisch)

### App-Informationen
- [ ] **App-Name** im Store (max. 30 Zeichen)
  - Aktuell: "Pause."
  - Alternative: "Pause - NFC App Control"

- [ ] **Untertitel** (max. 30 Zeichen)
  - Vorschlag: "Apps mit NFC Tags steuern"
  - Alternative: "NFC-basierte App-Sperre"

- [ ] **Beschreibung** schreiben (max. 4000 Zeichen)
  - [ ] Was macht die App?
  - [ ] Wie funktioniert sie?
  - [ ] Hauptfunktionen auflisten
  - [ ] NFC + Screen Time Anforderungen erwähnen
  - **Template im Anhang** ⬇️

- [ ] **Keywords** definieren (max. 100 Zeichen)
  - Vorschlag: `NFC,ScreenTime,Focus,Productivity,AppBlock,Tags,Digital Wellbeing,Distraction,Concentration`

- [ ] **Kategorie** wählen
  - Primär: **Productivity** (Produktivität)
  - Sekundär: **Lifestyle** oder **Utilities**

- [ ] **Preis festlegen**
  - [x] Kostenlos
  - [ ] Oder Preis (z.B. 2,99€)
  - [ ] In-App Purchases? (aktuell nicht implementiert)

### Werbematerial
- [ ] **Promotional Text** (max. 170 Zeichen)
  - Vorschlag: "Steuere deine Bildschirmzeit mit NFC-Tags! Blockiere ablenkende Apps mit einem Tap."

- [ ] **App Preview Video** (optional, empfohlen)
  - [ ] 15-30 Sekunden Demo-Video
  - [ ] Zeige: Tag scannen → Apps blockiert → erneut scannen → entsperrt
  - **Tool**: QuickTime Screen Recording + iMovie

---

## 🔐 Berechtigungen & Privacy

### Info.plist Updates
- [ ] **Privacy Strings vervollständigen**
  ```xml
  <key>NFCReaderUsageDescription</key>
  <string>Pause. verwendet NFC, um Tags zu scannen und deine Apps zu steuern.</string>
  
  <key>NSPrivacyTracking</key>
  <false/>
  
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <!-- Aktuell: Keine Daten gesammelt -->
  </array>
  ```

- [ ] **App Tracking Transparency** (falls zutreffend)
  - Aktuell nicht nötig: Keine Tracking

### Privacy Policy
- [ ] **Datenschutzerklärung erstellen**
  - [ ] Welche Daten werden gesammelt? (Aktuell: nur lokal)
  - [ ] Wo werden sie gespeichert? (On-Device)
  - [ ] Werden Daten an Dritte weitergegeben? (Nein)
  - [ ] Link zur Website/Privacy Policy
  - **Template**: [App Privacy Policy Generator](https://app-privacy-policy-generator.firebaseapp.com/)

- [ ] **Privacy Policy URL** in App Store Connect hinterlegen
  - Hosting: GitHub Pages, Notion, oder eigene Website

### Support & Marketing URLs
- [ ] **Support URL** erstellen
  - Mindestens eine Kontakt-Email oder FAQ-Seite
  - Vorschlag: GitHub Issues oder Support-Email

- [ ] **Marketing URL** (optional)
  - Produktseite oder Landing Page

---

## 🧪 Testing & Quality Assurance

### Funktionale Tests
- [ ] **Alle Features testen**
  - [x] NFC Tag scannen (funktioniert ✅)
  - [x] Tag registrieren
  - [x] Apps auswählen
  - [x] Apps blockieren/entsperren
  - [ ] Error-Handling überprüfen
  - [ ] Edge Cases testen (z.B. leere Listen)

- [ ] **Verschiedene Geräte testen**
  - [ ] iPhone mit NFC (iPhone 7+)
  - [ ] Verschiedene iOS Versionen (iOS 16, 17, 18)
  - [ ] Verschiedene Bildschirmgrößen

### Beta Testing (empfohlen)
- [ ] **TestFlight Setup**
  - [ ] Beta-Tester einladen (Freunde/Familie)
  - [ ] Feedback sammeln
  - [ ] Bugs fixen
  - **Dauer**: Mindestens 1-2 Wochen

### Performance & Crashes
- [ ] **Memory Leaks prüfen** (Instruments)
- [ ] **App-Größe optimieren** (<50MB ideal)
- [ ] **Crash-free Rate** sicherstellen (99%+)
- [ ] **Battery Usage** testen (kein Hintergrund-Drain)

---

## 📄 Rechtliches & Compliance

### Apple Guidelines
- [ ] **App Store Review Guidelines** durchlesen
  - Besonders: [Section 2.5 - Software Requirements](https://developer.apple.com/app-store/review/guidelines/#software-requirements)
  - Besonders: [Section 5 - Legal](https://developer.apple.com/app-store/review/guidelines/#legal)

- [ ] **Screen Time API Richtlinien** einhalten
  - Keine Umgehung von Elternkontrollen
  - Transparente Verwendung der API
  - Dokumentation: [FamilyControls Framework](https://developer.apple.com/documentation/familycontrols)

### Altersbeschränkung
- [ ] **Age Rating** festlegen
  - Empfehlung: **4+** (keine bedenklichen Inhalte)
  - In App Store Connect: Age Rating Questionnaire ausfüllen

### Lizenzen & Drittanbieter
- [ ] **Open Source Lizenzen** prüfen
  - Aktuell: Keine Drittanbieter-Dependencies
  - Falls zukünftig: Licenses-Seite in Settings hinzufügen

---

## 🌍 Lokalisierung (Optional für v1.0)

### Sprachen
- [x] **Deutsch** (Haupt-Sprache, bereits implementiert)
- [ ] **Englisch** (empfohlen für größere Reichweite)
  - [ ] Alle UI-Texte übersetzen
  - [ ] Localizable.strings erstellen
  - [ ] App Store Beschreibung auf Englisch

### Weitere Sprachen (Phase 2)
- [ ] Französisch
- [ ] Spanisch
- [ ] Italienisch

---

## 🐛 Bekannte Issues & Verbesserungen

### Bugs zu fixen
- [ ] **Tag-Status synchronisieren**
  - Problem: ~~Aktivierungs-Meldung war verkehrt~~ ✅ BEHOBEN
  - Status: ✅ Gelöst (07.01.2026)

### UX-Verbesserungen
- [ ] **Onboarding Flow**
  - [ ] Welcome Screen beim ersten Start
  - [ ] Tutorial: Wie registriere ich einen Tag?
  - [ ] Berechtigungs-Erklärung vor Anfrage
  - **Library**: [ConcentricOnboarding](https://github.com/exyte/ConcentricOnboarding)

- [ ] **Error Messages verbessern**
  - [ ] Benutzerfreundlichere Fehlermeldungen
  - [ ] Vorschläge zur Problembehebung
  - [ ] "Hilfe"-Links zu Settings

- [ ] **Loading States**
  - [ ] ProgressView während NFC-Scan
  - [ ] Skeleton Screens für Listen
  - [ ] Smooth Transitions

### Feature-Erweiterungen (nicht kritisch)
- [ ] **Haptic Feedback** optimieren
  - [x] Basis implementiert ✅
  - [ ] Verschiedene Feedback-Typen (Success/Error/Impact)

- [ ] **Animations** verfeinern
  - [ ] Tag-Karten Animationen
  - [ ] Status-Wechsel Animationen
  - [ ] Scan-Animation verbessern

- [ ] **Dark Mode Edge Cases**
  - [ ] Alle Farben in beiden Modi testen
  - [ ] Kontrast prüfen (WCAG Accessibility)

---

## 🔧 Code-Qualität & Dokumentation

### Code Cleanup
- [ ] **TODO/FIXME Comments** bereinigen
- [ ] **Debug Print Statements** entfernen oder auskommentieren
  - Viele `print()` im aktuellen Code (NFCController, TagController, etc.)
  - Entweder: Logging-Framework nutzen oder in Release-Build deaktivieren

- [ ] **Unused Code** entfernen
  - [ ] `TestDataController.swift` (nur für Development?)
  - [ ] Legacy/Deprecated Methods

- [ ] **Code Formatting** vereinheitlichen
  - [ ] SwiftLint einrichten (optional)
  - [ ] Konsistente Namenskonventionen

### Dokumentation
- [ ] **Inline Code Comments** für komplexe Logik
  - Besonders: NFC-Hardware-ID-Extraktion
  - Besonders: Screen Time Authorization Flow

- [ ] **API Documentation** (falls öffentliche API)
  - DocC Documentation Bundle (optional)

- [ ] **README.md** aktualisieren
  - [x] Grundstruktur vorhanden ✅
  - [ ] Screenshots hinzufügen
  - [ ] Installation Guide
  - [ ] FAQ-Sektion

---

## 🏗️ Build & Archive

### Xcode Configuration
- [ ] **Build Number incrementieren**
  - Format: `1` (erste Submission), dann `2`, `3`, etc.
  - Version: `1.0.0`

- [ ] **Bundle Identifier prüfen**
  - Aktuell: Wahrscheinlich `com.tristansrebot.Boredom` oder ähnlich
  - **Ändern zu**: `com.tristansrebot.pause` (konsistenter Name!)

- [ ] **Signing & Capabilities**
  - [ ] Automatisches Signing aktiviert
  - [ ] Team ausgewählt
  - [ ] Provisioning Profile aktuell
  - [ ] Capabilities korrekt:
    - [x] Family Controls ✅
    - [x] Near Field Communication Tag Reading ✅

### Build-Einstellungen
- [ ] **Release Configuration** verwenden
  - [ ] Optimizations: `-O` (optimize for speed)
  - [ ] Debug Symbols: Embed in Archive
  - [ ] Bitcode: Deprecated (nicht mehr nötig in Xcode 14+)

- [ ] **App Store Icon** korrekt verlinkt
  - In Assets.xcassets: AppIcon muss alle Größen haben

### Archive erstellen
- [ ] **Xcode Archive** erstellen
  - Product > Archive
  - Warten auf erfolgreichen Build
  - Validate App (in Organizer)
  - Upload to App Store Connect

---

## 📤 App Store Submission

### Pre-Submission Checklist
- [ ] **Testflight Beta abgeschlossen**
- [ ] **Alle kritischen Bugs behoben**
- [ ] **Screenshots hochgeladen** (alle Größen)
- [ ] **App-Beschreibung finalisiert**
- [ ] **Keywords optimiert**
- [ ] **Privacy Policy URL hinterlegt**
- [ ] **Support URL hinterlegt**
- [ ] **Age Rating festgelegt**

### Submit for Review
- [ ] **Build auswählen** in App Store Connect
- [ ] **"Submit for Review"** klicken
- [ ] **Export Compliance** beantworten
  - Verwendet App Verschlüsselung? → **Nein** (nur Standard iOS Encryption)
- [ ] **Advertising Identifier (IDFA)** → **Nein** (keine Ads)

### Review Notes (wichtig!)
- [ ] **Review Notes** für Apple hinzufügen:
  ```
  Pause. verwendet NFC und Screen Time API.
  
  Test-Hinweise:
  - Physisches iPhone mit NFC erforderlich
  - Einen NFC-Tag (NTAG215) zum Testen bereitstellen
  - Screen Time Berechtigung in iOS Einstellungen erteilen
  
  Test-Ablauf:
  1. App öffnen → Screen Time Berechtigung erteilen
  2. "Tag hinzufügen" → NFC Tag scannen
  3. Apps auswählen (z.B. Safari)
  4. Tag erneut scannen → Apps werden blockiert
  5. Tag nochmal scannen → Apps entsperrt
  
  Kontakt: [deine-email]@example.com
  ```

- [ ] **Demo-Zugangsdaten** (falls Login erforderlich) → Nicht nötig

---

## ⏰ Timeline & Planung

### Zeitschätzung (realistisch)

#### Sofort umsetzbar (1-2 Tage)
- [ ] App Icon Design
- [ ] Screenshots erstellen
- [ ] Privacy Policy schreiben
- [ ] App Store Texte schreiben
- [ ] Debug Prints bereinigen

#### Kurze Entwicklung (3-5 Tage)
- [ ] Onboarding Flow
- [ ] Error Messages verbessern
- [ ] UX-Optimierungen
- [ ] Loading States
- [ ] Beta Testing Setup

#### Mittelfristig (1-2 Wochen)
- [ ] TestFlight Beta mit Testern
- [ ] Feedback implementieren
- [ ] Englische Lokalisierung
- [ ] Performance-Optimierungen

#### Review-Prozess (Apple)
- [ ] Submission: ~1-2 Tage Verarbeitung
- [ ] Review: ~1-3 Tage (meist 24-48 Stunden)
- [ ] Mögliche Ablehnung: +3-7 Tage für Fixes

**Gesamt**: ~2-4 Wochen von jetzt bis Go-Live

---

## 🎯 Priorisierung

### 🔴 MUST HAVE (Kritisch für Submission)
1. ✅ App funktioniert korrekt (bereits ✅)
2. ❌ App Icon (alle Größen)
3. ❌ Screenshots (mind. 3 pro Gerätegröße)
4. ❌ App Store Beschreibung
5. ❌ Privacy Policy
6. ❌ Apple Developer Membership
7. ❌ Debug Prints entfernen
8. ❌ Bundle Identifier anpassen
9. ❌ TestFlight Beta (empfohlen!)

### 🟠 SHOULD HAVE (Wichtig für UX)
1. ❌ Onboarding Flow
2. ❌ Error Messages verbessern
3. ❌ Loading States
4. ❌ Englische Lokalisierung
5. ❌ App Preview Video

### 🟢 NICE TO HAVE (Post-Launch)
1. ❌ Weitere Sprachen
2. ❌ Erweiterte Animationen
3. ❌ Widget Support
4. ❌ iCloud Sync
5. ❌ Statistics Dashboard

---

## 📊 App Store Optimierung (ASO)

### Pre-Launch
- [ ] **Keyword Research**
  - Tool: [AppTweak](https://www.apptweak.com/) oder [Sensor Tower](https://sensortower.com/)
  - Konkurrenz analysieren: "App Blocker", "Focus Apps", "Screen Time"

- [ ] **Icon A/B Testing** (optional)
  - Verschiedene Icon-Varianten testen
  - Community-Feedback einholen (Reddit, Twitter)

### Post-Launch
- [ ] **Ratings & Reviews sammeln**
  - In-App Review Prompt nach erfolgreicher Tag-Verwendung
  - `SKStoreReviewController` nutzen

- [ ] **Update-Strategie**
  - Regelmäßige Updates (alle 1-2 Monate)
  - Bug Fixes schnell deployen
  - Neue Features basierend auf User-Feedback

---

## 🆘 Hilfreiche Resources

### Apple Dokumentation
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [FamilyControls Framework](https://developer.apple.com/documentation/familycontrols)
- [Core NFC](https://developer.apple.com/documentation/corenfc)

### Design Resources
- [SF Symbols](https://developer.apple.com/sf-symbols/) (Icons)
- [Figma iOS UI Kit](https://www.figma.com/community/file/984106517828363349)
- [Apple Design Resources](https://developer.apple.com/design/resources/)

### Tools
- [AppIconizer](https://appicon.co/) - Icon Generator
- [ScreenshotStudio](https://screenshotstudio.co/) - App Screenshots
- [App Privacy Policy Generator](https://app-privacy-policy-generator.firebaseapp.com/)
- [QuickTime](https://support.apple.com/guide/quicktime-player) - Screen Recording

### Communities
- [r/iOSProgramming](https://www.reddit.com/r/iOSProgramming/)
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Swift Forums](https://forums.swift.org/)

---

## ✅ Final Check vor Submission

**Vor dem "Submit for Review" Button:**

- [ ] ✅ App startet ohne Crashes
- [ ] ✅ Alle Features funktionieren
- [ ] ✅ Screenshots sind hochgeladen
- [ ] ✅ Beschreibung ist fehlerfrei
- [ ] ✅ Privacy Policy ist verfügbar
- [ ] ✅ Support-Kontakt ist angegeben
- [ ] ✅ Build ist validated
- [ ] ✅ Review Notes sind ausgefüllt
- [ ] ✅ TestFlight Beta war erfolgreich
- [ ] ✅ Keine TODO/FIXME im Code
- [ ] ✅ Debug Logs sind deaktiviert

**Dann: SUBMIT! 🚀**

---

## 📝 Anhang

### Template: App Store Beschreibung

```
PAUSE. - Steuere deine Apps mit NFC Tags

Hol dir die Kontrolle über deine Bildschirmzeit zurück! Pause. nutzt NFC-Tags, um ablenkende Apps mit einem einfachen Tap zu blockieren oder zu entsperren.

🎯 WIE ES FUNKTIONIERT

1. Registriere einen NFC-Tag in der App
2. Wähle aus, welche Apps blockiert werden sollen
3. Tippe dein iPhone an den Tag → Apps werden gesperrt
4. Tippe erneut → Apps sind wieder verfügbar

✨ FEATURES

• NFC Tag Integration - Nutze physische Tags für mehr Kontrolle
• Native Screen Time API - Sicher und zuverlässig
• Unbegrenzte Tags - Erstelle Tags für verschiedene Situationen
• Einfache Verwaltung - Übersichtliches Dashboard
• Toggle-Funktion - Ein Tag zum Blockieren & Entsperren

🔒 PERFEKT FÜR

• Fokus-Arbeit ohne Ablenkungen
• Digital Detox am Abend
• Produktivitäts-Routinen
• Selbst-Kontrolle statt Fremd-Kontrolle

📱 ANFORDERUNGEN

• iPhone 7 oder neuer (mit NFC)
• iOS 16.0 oder höher
• NFC-Tags (z.B. NTAG215)
• Screen Time Berechtigung

🔐 DATENSCHUTZ

Alle Daten bleiben auf deinem Gerät. Keine Cloud, keine Tracking, keine Werbung. Pause. nutzt Apples Screen Time API für maximale Sicherheit.

⚡ EINFACH & EFFEKTIV

Keine komplizierten Einstellungen. Keine Timer. Nur ein physischer Tag zwischen dir und deinen Apps. Simple Lösung für ein modernes Problem.

TESTE PAUSE. NOCH HEUTE!

---

Support: [deine-support-email]@example.com
Website: www.pause-app.com (optional)
```

### Template: Review Notes

```
Review-Team Hinweise für Pause.

KERNFUNKTIONALITÄT:
Pause. ermöglicht es Nutzern, Apps mithilfe von NFC-Tags zu blockieren/entsperren.

ERFORDERLICHE HARDWARE:
- Physisches iPhone mit NFC (iPhone 7+)
- NFC Tag (NTAG215 empfohlen)

TEST-ANLEITUNG:
1. App starten
2. Screen Time Berechtigung erteilen (iOS-System-Prompt)
3. "+ Tag hinzufügen" tippen
4. NFC Tag scannen (an Rückseite des iPhones halten)
5. Tag benennen (z.B. "Schreibtisch")
6. Apps auswählen (z.B. Safari, Instagram)
7. "Weiter" → "Apps verknüpfen"
8. Zurück zum Home-Screen
9. "Tag scannen" → NFC Tag erneut scannen
10. Status zeigt: "Apps blockiert"
11. Versuchen, ausgewählte App zu öffnen → Screen Time Sperre erscheint
12. Erneut scannen → Apps entsperrt

API-VERWENDUNG:
- FamilyControls: Screen Time Authorization
- ManagedSettings: App Blocking
- CoreNFC: Tag Reading

BERECHTIGUNGEN:
- NFC (für Tag-Scanning)
- Screen Time (für App-Blocking)

Bei Fragen: [email]@example.com

Vielen Dank!
```

---

**Ende der Checkliste**

Stand: 07.01.2026  
Nächste Review: Nach TestFlight Beta
