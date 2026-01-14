//
//  TimeProfileDetailView.swift
//  Pause.
//
//  Created by Tristan Srebot on 14.01.26.
//

import SwiftUI
import FamilyControls

struct TimeProfileDetailView: View {
    let profile: TimeProfile
    
    // MARK: - Environment Dependencies
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var timeProfileController: TimeProfileController
    @EnvironmentObject private var selectionManager: SelectionManager
    @EnvironmentObject private var screenTimeController: ScreenTimeController
    
    // MARK: - Local State
    @State private var showingAppPicker = false
    @State private var showingScheduleEditor = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    private var currentProfile: TimeProfile? {
        appState.timeProfiles.first(where: { $0.id == profile.id })
    }
    
    private var isActuallyActive: Bool {
        guard let profile = currentProfile else { return false }
        return profile.isCurrentlyBlocking(appState: appState, screenTimeController: screenTimeController)
    }
    
    private var isAnyTimeProfileActive: Bool {
        appState.timeProfiles.contains { profile in
            profile.isCurrentlyBlocking(appState: appState, screenTimeController: screenTimeController)
        }
    }
    
    private var canEdit: Bool {
        // CANNOT edit if a tag is active
        if appState.getActiveTag() != nil {
            return false
        }
        
        // CANNOT edit if THIS profile is currently blocking
        // This prevents deleting or editing an active profile
        return !isActuallyActive
    }
    
    private var canToggle: Bool {
        // Cannot toggle if a tag is active
        if appState.getActiveTag() != nil {
            return false
        }
        
        // Cannot disable if this profile is currently active
        if isActuallyActive {
            return false
        }
        
        return true
    }
    
    private var toggleDisabledReason: String? {
        if let activeTag = appState.getActiveTag() {
            return "Tag '\(activeTag.name)' ist aktiv"
        }
        
        if isActuallyActive {
            return "Profil ist gerade aktiv und blockiert Apps"
        }
        
        return nil
    }
    
    var body: some View {
        ZStack {
            PauseColors.background
                .ignoresSafeArea()
            
            if let profile = currentProfile {
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Status Card
                        statusCard(for: profile)
                        
                        // Schedule Section
                        scheduleSection(for: profile)
                        
                        // Apps Section
                        appsSection(for: profile)
                        
                        // Delete Button
                        deleteButton
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingAppPicker) {
            if let profile = currentProfile {
                TimeProfileAppPickerView(isPresented: $showingAppPicker, profile: profile)
            }
        }
        .sheet(isPresented: $showingScheduleEditor) {
            if let profile = currentProfile {
                ScheduleEditorView(profile: profile)
            }
        }
        .alert("Zeitprofil löschen?", isPresented: $showingDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                timeProfileController.deleteProfile(profile: profile)
                dismiss()
            }
        } message: {
            Text("Dieses Zeitprofil wird dauerhaft gelöscht.")
        }
    }
    
    // MARK: - Status Card
    
    private func statusCard(for profile: TimeProfile) -> some View {
        let isActive = profile.isCurrentlyBlocking(appState: appState, screenTimeController: screenTimeController)
        
        return VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Status")
                        .font(.system(size: FontSize.base, weight: .semibold))
                        .foregroundColor(PauseColors.tertiaryText)
                    
                    if isActive {
                        HStack(spacing: Spacing.xxs) {
                            Circle()
                                .fill(PauseColors.success)
                                .frame(width: 10, height: 10)
                            Text("Gerade aktiv")
                                .font(.system(size: FontSize.lg, weight: .semibold))
                                .foregroundColor(PauseColors.success)
                        }
                    } else if profile.isEnabled {
                        Text("Aktiviert")
                            .font(.system(size: FontSize.lg, weight: .semibold))
                            .foregroundColor(PauseColors.primaryText)
                    } else {
                        Text("Deaktiviert")
                            .font(.system(size: FontSize.lg, weight: .semibold))
                            .foregroundColor(PauseColors.tertiaryText)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { profile.isEnabled },
                    set: { _ in
                        timeProfileController.toggleEnabled(profile: profile)
                    }
                ))
                .labelsHidden()
                .tint(PauseColors.accent)
                .disabled(!canToggle)
                .opacity(canToggle ? 1.0 : 0.6)
            }
            .padding(Spacing.md)
            
            // Info when toggle is disabled
            if !canToggle, let reason = toggleDisabledReason {
                Divider()
                    .background(PauseColors.cardBorder)
                    .padding(.horizontal, Spacing.md)
                
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: isActive ? "clock.fill" : "tag.fill")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.warning)
                    
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(reason)
                            .font(.system(size: FontSize.sm, weight: .medium))
                            .foregroundColor(PauseColors.warning)
                        
                        if isActive {
                            Text("Du kannst das Profil erst deaktivieren, wenn die Zeit abgelaufen ist.")
                                .font(.system(size: FontSize.xs))
                                .foregroundColor(PauseColors.secondaryText)
                        } else {
                            Text("Zeitprofile können nicht aktiviert werden, während ein Tag aktiv ist.")
                                .font(.system(size: FontSize.xs))
                                .foregroundColor(PauseColors.secondaryText)
                        }
                    }
                }
                .padding(Spacing.md)
            }
        }
        .card()
    }
    
    // MARK: - Schedule Section
    
    private func scheduleSection(for profile: TimeProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Zeitplan")
                .font(.system(size: FontSize.base, weight: .semibold))
                .foregroundColor(PauseColors.tertiaryText)
                .padding(.horizontal, Spacing.md)
            
            Button {
                showingScheduleEditor = true
            } label: {
                VStack(spacing: Spacing.md) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: FontSize.lg))
                            .foregroundColor(PauseColors.accent)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Wochentage & Zeiten")
                                .font(.system(size: FontSize.base, weight: .medium))
                                .foregroundColor(PauseColors.primaryText)
                            
                            if profile.schedule.selectedWeekdays.isEmpty {
                                Text("Keine Tage ausgewählt")
                                    .font(.system(size: FontSize.sm))
                                    .foregroundColor(PauseColors.warning)
                            } else {
                                Text(scheduleDescription(for: profile))
                                    .font(.system(size: FontSize.sm))
                                    .foregroundColor(PauseColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: FontSize.sm, weight: .semibold))
                            .foregroundColor(PauseColors.tertiaryText)
                    }
                    .padding(Spacing.md)
                    
                    if !profile.schedule.selectedWeekdays.isEmpty {
                        Divider()
                            .background(PauseColors.cardBorder)
                            .padding(.horizontal, Spacing.md)
                        
                        // Weekday indicators
                        HStack(spacing: Spacing.xs) {
                            ForEach(Weekday.allCasesSorted, id: \.self) { weekday in
                                Text(weekday.shortName)
                                    .font(.system(size: FontSize.sm, weight: .medium))
                                    .foregroundColor(profile.schedule.selectedWeekdays.contains(weekday) ? .white : PauseColors.tertiaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(profile.schedule.selectedWeekdays.contains(weekday) ? PauseColors.accent : PauseColors.secondaryBackground)
                                    .cornerRadius(CornerRadius.sm)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.bottom, Spacing.md)
                    }
                }
                .card()
            }
            .buttonStyle(.plain)
            .disabled(!canEdit)
            .opacity(canEdit ? 1.0 : 0.6)
            
            // Info message when editing is disabled
            if !canEdit {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: isActuallyActive ? "exclamationmark.triangle.fill" : "tag.fill")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.warning)
                    
                    if let activeTag = appState.getActiveTag() {
                        Text("Zeitplan kann nicht bearbeitet werden während Tag '\(activeTag.name)' aktiv ist.")
                            .font(.system(size: FontSize.sm))
                            .foregroundColor(PauseColors.secondaryText)
                    } else if isActuallyActive {
                        Text("Zeitplan kann nicht bearbeitet werden während das Profil aktiv ist.")
                            .font(.system(size: FontSize.sm))
                            .foregroundColor(PauseColors.secondaryText)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
    
    // MARK: - Apps Section
    
    private func appsSection(for profile: TimeProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Blockierte Apps")
                .font(.system(size: FontSize.base, weight: .semibold))
                .foregroundColor(PauseColors.tertiaryText)
                .padding(.horizontal, Spacing.md)
            
            Button {
                showingAppPicker = true
            } label: {
                HStack {
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: FontSize.lg))
                        .foregroundColor(PauseColors.accent)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Apps auswählen")
                            .font(.system(size: FontSize.base, weight: .medium))
                            .foregroundColor(PauseColors.primaryText)
                        
                        let selectionInfo = selectionManager.selectionInfo(for: profile.id)
                        if selectionInfo.apps == 0 && selectionInfo.categories == 0 {
                            Text("Keine Apps ausgewählt")
                                .font(.system(size: FontSize.sm))
                                .foregroundColor(PauseColors.warning)
                        } else {
                            Text("\(selectionInfo.apps) Apps, \(selectionInfo.categories) Kategorien")
                                .font(.system(size: FontSize.sm))
                                .foregroundColor(PauseColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: FontSize.sm, weight: .semibold))
                        .foregroundColor(PauseColors.tertiaryText)
                }
                .padding(Spacing.md)
                .card()
            }
            .buttonStyle(.plain)
            .disabled(!canEdit)
            .opacity(canEdit ? 1.0 : 0.6)
        }
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            Text("Zeitprofil löschen")
                .font(.system(size: FontSize.base, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(PauseColors.error)
                .cornerRadius(CornerRadius.md)
        }
        .disabled(!canEdit)
        .opacity(canEdit ? 1.0 : 0.6)
        .padding(.top, Spacing.lg)
    }
    
    // MARK: - Helper Methods
    
    private func scheduleDescription(for profile: TimeProfile) -> String {
        let days = profile.schedule.selectedWeekdays.count
        let timeRange = "\(profile.schedule.startTime.formattedString) - \(profile.schedule.endTime.formattedString)"
        return "\(days) Tag\(days == 1 ? "" : "e") · \(timeRange)"
    }
}

#Preview {
    NavigationStack {
        TimeProfileDetailView(profile: TimeProfile(name: "Arbeit"))
    }
}
