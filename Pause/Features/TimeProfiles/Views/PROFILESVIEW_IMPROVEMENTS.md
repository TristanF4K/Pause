# 🚀 ProfilesView.swift - Konkrete Verbesserungen

Diese Datei enthält **Copy-Paste Ready** Code-Snippets für die empfohlenen Verbesserungen.

---

## 1. ✅ Quick Win: LazyVStack für bessere Performance

### Aktuell
```swift
private var profileListView: some View {
    ScrollView {
        VStack(spacing: Spacing.md) {
            ForEach(appState.timeProfiles) { profile in
                NavigationLink(destination: TimeProfileDetailView(profile: profile)) {
                    TimeProfileCard(profile: profile)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.lg)
    }
}
```

### ✨ Verbessert
```swift
private var profileListView: some View {
    ScrollView {
        LazyVStack(spacing: Spacing.md) {  // ← Geändert zu LazyVStack
            ForEach(appState.timeProfiles) { profile in
                NavigationLink(destination: TimeProfileDetailView(profile: profile)) {
                    TimeProfileCard(profile: profile)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.lg)
    }
}
```

**Warum:** Views werden nur bei Bedarf gerendert → bessere Performance bei vielen Profilen

---

## 2. ✅ Design System erweitern: IconSize

### In DesignSystem.swift hinzufügen
```swift
enum IconSize {
    static let xs: CGFloat = 16
    static let sm: CGFloat = 20
    static let md: CGFloat = 24
    static let lg: CGFloat = 32
    static let xl: CGFloat = 44
    static let xxl: CGFloat = 64
    static let hero: CGFloat = 120
}
```

### Dann in ProfilesView.swift ersetzen:

**Empty State Icon:**
```swift
// Vorher:
Circle()
    .frame(width: 120, height: 120)

// Nachher:
Circle()
    .frame(width: IconSize.hero, height: IconSize.hero)
```

**Profile Card Icon:**
```swift
// Vorher:
Circle()
    .frame(width: 44, height: 44)

// Nachher:
Circle()
    .frame(width: IconSize.xl, height: IconSize.xl)
```

**Weekday Badges:**
```swift
// Vorher:
.frame(width: 32, height: 32)

// Nachher:
.frame(width: IconSize.lg, height: IconSize.lg)
```

---

## 3. ✅ Gradient Helper Extensions

### In DesignSystem.swift hinzufügen:
```swift
// MARK: - Gradient Styles

extension LinearGradient {
    /// Primary accent gradient (timberwolf)
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [PauseColors.accent.opacity(0.8), PauseColors.accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Subtle accent gradient for backgrounds
    static var subtleAccentGradient: LinearGradient {
        LinearGradient(
            colors: [PauseColors.accent.opacity(0.3), PauseColors.accent.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Success gradient (green)
    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [Color.green.opacity(0.8), Color.green],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Disabled/inactive gradient (gray)
    static var disabledGradient: LinearGradient {
        LinearGradient(
            colors: [PauseColors.dimGray.opacity(0.6), PauseColors.dimGray],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Flat gradient (for non-gradient backgrounds)
    static func flat(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
```

### Dann in ProfilesView.swift ersetzen:

**Empty State Circle:**
```swift
// Vorher:
Circle()
    .fill(
        LinearGradient(
            colors: [PauseColors.accent.opacity(0.3), PauseColors.accent.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

// Nachher:
Circle()
    .fill(.subtleAccentGradient)
```

**Empty State Icon:**
```swift
// Vorher:
Image(systemName: "clock.fill")
    .foregroundStyle(
        LinearGradient(
            colors: [PauseColors.accent, PauseColors.accent.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

// Nachher:
Image(systemName: "clock.fill")
    .foregroundStyle(.accentGradient)
```

**Profile Card Icon:**
```swift
// Vorher:
Circle()
    .fill(
        LinearGradient(
            colors: isActuallyActive
                ? [Color.green.opacity(0.8), Color.green]
                : profile.isEnabled
                    ? [PauseColors.accent.opacity(0.8), PauseColors.accent]
                    : [PauseColors.dimGray.opacity(0.6), PauseColors.dimGray],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

// Nachher:
Circle()
    .fill(
        isActuallyActive
            ? .successGradient
            : profile.isEnabled
                ? .accentGradient
                : .disabledGradient
    )
```

**Weekday Badges:**
```swift
// Vorher:
.background(
    profile.schedule.selectedWeekdays.contains(weekday)
        ? LinearGradient(
            colors: [PauseColors.accent.opacity(0.9), PauseColors.accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        : LinearGradient(
            colors: [PauseColors.secondaryBackground, PauseColors.secondaryBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
)

// Nachher:
.background(
    profile.schedule.selectedWeekdays.contains(weekday)
        ? .accentGradient
        : .flat(PauseColors.secondaryBackground)
)
```

**Empty State Button:**
```swift
// Vorher:
.background(
    LinearGradient(
        colors: [PauseColors.accent, PauseColors.accent.opacity(0.8)],
        startPoint: .leading,
        endPoint: .trailing
    )
)

// Nachher:
.background(.accentGradient)
```

---

## 4. ✅ Previews mit Test-Daten

### Am Ende von ProfilesView.swift ersetzen:
```swift
// VORHER:
#Preview {
    TimeProfilesView()
}

// NACHHER:
#Preview("Empty State") {
    let mockAppState = AppState(screenTimeController: nil)
    mockAppState.timeProfiles = []
    
    return TimeProfilesView()
        .environmentObject(mockAppState)
}

#Preview("With Profiles") {
    let mockAppState = AppState(screenTimeController: nil)
    
    mockAppState.timeProfiles = [
        TimeProfile(
            id: UUID(),
            name: "Arbeit",
            schedule: TimeSchedule(
                startTime: TimeOfDay(hour: 9, minute: 0),
                endTime: TimeOfDay(hour: 17, minute: 0),
                selectedWeekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]
            ),
            linkedAppsCount: 12,
            linkedCategoriesCount: 3,
            isEnabled: true
        ),
        TimeProfile(
            id: UUID(),
            name: "Schlafzeit",
            schedule: TimeSchedule(
                startTime: TimeOfDay(hour: 22, minute: 0),
                endTime: TimeOfDay(hour: 7, minute: 0),
                selectedWeekdays: Weekday.allCases
            ),
            linkedAppsCount: 8,
            linkedCategoriesCount: 1,
            isEnabled: true
        ),
        TimeProfile(
            id: UUID(),
            name: "Wochenende",
            schedule: TimeSchedule(
                startTime: TimeOfDay(hour: 0, minute: 0),
                endTime: TimeOfDay(hour: 23, minute: 59),
                selectedWeekdays: [.saturday, .sunday]
            ),
            linkedAppsCount: 5,
            linkedCategoriesCount: 2,
            isEnabled: false
        ),
        TimeProfile(
            id: UUID(),
            name: "Keine Tage",
            schedule: TimeSchedule(
                startTime: TimeOfDay(hour: 12, minute: 0),
                endTime: TimeOfDay(hour: 13, minute: 0),
                selectedWeekdays: []
            ),
            linkedAppsCount: 0,
            linkedCategoriesCount: 0,
            isEnabled: true
        )
    ]
    
    return TimeProfilesView()
        .environmentObject(mockAppState)
}

#Preview("Profile Card - Active") {
    let mockAppState = AppState(screenTimeController: nil)
    let mockScreenTime = ScreenTimeController()
    
    let profile = TimeProfile(
        id: UUID(),
        name: "Arbeit",
        schedule: TimeSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 17, minute: 0),
            selectedWeekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        ),
        linkedAppsCount: 12,
        linkedCategoriesCount: 3,
        isEnabled: true
    )
    
    return TimeProfileCard(profile: profile)
        .environmentObject(mockAppState)
        .environmentObject(mockScreenTime)
        .padding()
        .background(PauseColors.background)
}

#Preview("Profile Card - Blocked by Tag") {
    let mockAppState = AppState(screenTimeController: nil)
    let mockScreenTime = ScreenTimeController()
    
    // Add an active tag
    let tag = NFCTag(
        id: UUID(),
        name: "Roter Tag",
        tagIdentifier: "ABC123",
        linkedAppsCount: 5,
        linkedCategoriesCount: 2,
        isActive: true
    )
    mockAppState.registeredTags = [tag]
    
    let profile = TimeProfile(
        id: UUID(),
        name: "Arbeit (blockiert)",
        schedule: TimeSchedule(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 17, minute: 0),
            selectedWeekdays: [.monday, .tuesday, .wednesday, .thursday, .friday]
        ),
        linkedAppsCount: 12,
        linkedCategoriesCount: 3,
        isEnabled: true
    )
    
    return TimeProfileCard(profile: profile)
        .environmentObject(mockAppState)
        .environmentObject(mockScreenTime)
        .padding()
        .background(PauseColors.background)
}

#Preview("Profile Card - Disabled") {
    let mockAppState = AppState(screenTimeController: nil)
    let mockScreenTime = ScreenTimeController()
    
    let profile = TimeProfile(
        id: UUID(),
        name: "Deaktiviert",
        schedule: TimeSchedule(
            startTime: TimeOfDay(hour: 12, minute: 0),
            endTime: TimeOfDay(hour: 13, minute: 0),
            selectedWeekdays: [.monday, .wednesday, .friday]
        ),
        linkedAppsCount: 5,
        linkedCategoriesCount: 1,
        isEnabled: false
    )
    
    return TimeProfileCard(profile: profile)
        .environmentObject(mockAppState)
        .environmentObject(mockScreenTime)
        .padding()
        .background(PauseColors.background)
}
```

---

## 5. 🎯 Optional: Accessibility Improvements

### In TimeProfileCard hinzufügen:
```swift
var body: some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        // ... existing content ...
    }
    .padding(Spacing.md)
    .background(
        // ... existing background ...
    )
    // ✨ NEU: Accessibility
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityValue(accessibilityValue)
    .accessibilityHint("Doppeltippen zum Öffnen der Details")
}

// Helper computed properties
private var accessibilityLabel: String {
    "Zeitprofil \(profile.name)"
}

private var accessibilityValue: String {
    var value = "Von \(profile.schedule.startTime.formattedString) bis \(profile.schedule.endTime.formattedString). "
    
    if profile.schedule.selectedWeekdays.isEmpty {
        value += "Keine Tage ausgewählt. "
    } else {
        let weekdayNames = profile.schedule.selectedWeekdays
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.longName }
            .joined(separator: ", ")
        value += "Aktiv an: \(weekdayNames). "
    }
    
    if isActuallyActive {
        value += "Status: Gerade aktiv und blockiert Apps."
    } else if isBlockedByTag {
        value += "Status: Wartet auf Tag-Deaktivierung."
    } else if !profile.isEnabled {
        value += "Status: Deaktiviert."
    } else {
        value += "Status: Bereit zur Aktivierung."
    }
    
    return value
}
```

**Hinweis:** Dafür müssten `Weekday.longName` Properties existieren:
```swift
// In Weekday enum hinzufügen:
var longName: String {
    switch self {
    case .monday: return "Montag"
    case .tuesday: return "Dienstag"
    case .wednesday: return "Mittwoch"
    case .thursday: return "Donnerstag"
    case .friday: return "Freitag"
    case .saturday: return "Samstag"
    case .sunday: return "Sonntag"
    }
}
```

---

## 6. 🎯 Optional: Error & Loading States

### In TimeProfilesView hinzufügen:
```swift
struct TimeProfilesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingAddProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                PauseColors.background
                    .ignoresSafeArea()
                
                // ✨ NEU: Loading State
                if appState.isLoadingProfiles {
                    loadingView
                }
                // ✨ NEU: Error State
                else if let error = appState.profilesError {
                    errorView(error: error)
                }
                // Existing Empty & List views
                else if appState.timeProfiles.isEmpty {
                    emptyStateView
                } else {
                    profileListView
                }
            }
            .navigationTitle("Zeitprofile")
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddProfile = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(PauseColors.accent)
                    }
                    .disabled(appState.isLoadingProfiles)  // ✨ Disable während Loading
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                AddTimeProfileView()
            }
        }
    }
    
    // ✨ NEU: Loading View
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(PauseColors.accent)
            
            Text("Lade Zeitprofile...")
                .font(.system(size: FontSize.base))
                .foregroundColor(PauseColors.secondaryText)
        }
    }
    
    // ✨ NEU: Error View
    private func errorView(error: Error) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(PauseColors.error)
            
            VStack(spacing: Spacing.sm) {
                Text("Fehler beim Laden")
                    .font(.system(size: FontSize.xl, weight: .bold))
                    .foregroundColor(PauseColors.primaryText)
                
                Text(error.localizedDescription)
                    .font(.system(size: FontSize.base))
                    .foregroundColor(PauseColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            
            Button {
                Task {
                    await appState.reloadProfiles()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Erneut versuchen")
                        .font(.system(size: FontSize.base, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(PauseColors.accent)
                .cornerRadius(CornerRadius.md)
            }
        }
    }
    
    // ... rest of the views ...
}
```

**Hinweis:** Dafür müsste `AppState` folgende Properties haben:
```swift
@Published var isLoadingProfiles = false
@Published var profilesError: Error?

func reloadProfiles() async {
    isLoadingProfiles = true
    profilesError = nil
    
    do {
        timeProfiles = try await loadTimeProfiles()
    } catch {
        profilesError = error
    }
    
    isLoadingProfiles = false
}
```

---

## 📋 Implementation Checklist

### Quick Wins (Sofort umsetzbar)
- [ ] `LazyVStack` implementieren (2 Min)
- [ ] `IconSize` enum hinzufügen (5 Min)
- [ ] Magic Numbers ersetzen (5 Min)
- [ ] Previews mit Daten hinzufügen (10 Min)

### Medium Term (Optional)
- [ ] Gradient Extensions erstellen (15 Min)
- [ ] Alle Gradients ersetzen (10 Min)
- [ ] Accessibility Labels hinzufügen (20 Min)
- [ ] `Weekday.longName` implementieren (5 Min)

### Optional (Nice to have)
- [ ] Loading State in AppState (30 Min)
- [ ] Error State in AppState (30 Min)
- [ ] Loading/Error Views hinzufügen (20 Min)

---

## 🎯 Erwartetes Ergebnis

Nach Implementierung der Quick Wins:
- ✅ **Bessere Performance** bei vielen Profilen
- ✅ **Konsistenterer Code** durch Design System
- ✅ **Bessere Developer Experience** mit Preview-Daten
- ✅ **Wartbarerer Code** ohne Magic Numbers

Nach allen Optimierungen:
- ✅ **Production-Ready Code** mit Error Handling
- ✅ **Accessibility-optimiert** für VoiceOver
- ✅ **Design System vollständig** mit Gradients
- ✅ **Testbar** mit Mock-Daten in Previews

---

**Viel Erfolg beim Implementieren! 🚀**
