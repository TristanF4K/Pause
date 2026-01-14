//
//  TimeProfilesView.swift
//  Pause.
//
//  Created by Tristan Srebot on 14.01.26.
//

import SwiftUI

struct TimeProfilesView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingAddProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                PauseColors.background
                    .ignoresSafeArea()
                
                if appState.timeProfiles.isEmpty {
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
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                AddTimeProfileView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [PauseColors.accent.opacity(0.3), PauseColors.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [PauseColors.accent, PauseColors.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: Spacing.sm) {
                Text("Keine Zeitprofile")
                    .font(.system(size: FontSize.xl, weight: .bold))
                    .foregroundColor(PauseColors.primaryText)
                
                Text("Erstelle ein Zeitprofil, um Apps zu bestimmten Zeiten automatisch zu blockieren.")
                    .font(.system(size: FontSize.base))
                    .foregroundColor(PauseColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            
            Button {
                showingAddProfile = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: FontSize.lg))
                    Text("Zeitprofil erstellen")
                        .font(.system(size: FontSize.base, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(
                    LinearGradient(
                        colors: [PauseColors.accent, PauseColors.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(CornerRadius.md)
                .shadow(color: PauseColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.md)
        }
    }
    
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
}

// MARK: - Time Profile Card

struct TimeProfileCard: View {
    let profile: TimeProfile
    @StateObject private var appState = AppState.shared
    @StateObject private var screenTimeController = ScreenTimeController.shared
    
    private var isActuallyActive: Bool {
        profile.isCurrentlyBlocking(appState: appState, screenTimeController: screenTimeController)
    }
    
    private var isBlockedByTag: Bool {
        // Profile should be active but is blocked by a tag
        profile.isEnabled && 
        profile.shouldBeActive &&
        !isActuallyActive &&
        appState.getActiveTag() != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Colorful icon
                ZStack {
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
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isActuallyActive ? "clock.fill" : "clock")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(profile.name)
                        .font(.system(size: FontSize.lg, weight: .semibold))
                        .foregroundColor(PauseColors.primaryText)
                    
                    if profile.schedule.selectedWeekdays.isEmpty {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: FontSize.xs))
                                .foregroundColor(PauseColors.warning)
                            Text("Keine Tage ausgewählt")
                                .font(.system(size: FontSize.sm))
                                .foregroundColor(PauseColors.warning)
                        }
                    } else {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "calendar")
                                .font(.system(size: FontSize.xs))
                                .foregroundColor(PauseColors.accent)
                            Text(formattedSchedule)
                                .font(.system(size: FontSize.sm))
                                .foregroundColor(PauseColors.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                    if isActuallyActive {
                        HStack(spacing: Spacing.xxs) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Aktiv")
                                .font(.system(size: FontSize.sm, weight: .semibold))
                                .foregroundColor(Color.green)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(CornerRadius.sm)
                    } else if isBlockedByTag {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: FontSize.xs))
                            Text("Wartet")
                                .font(.system(size: FontSize.sm, weight: .medium))
                        }
                        .foregroundColor(Color.orange)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(CornerRadius.sm)
                    } else if !profile.isEnabled {
                        Text("Aus")
                            .font(.system(size: FontSize.sm, weight: .medium))
                            .foregroundColor(PauseColors.tertiaryText)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(PauseColors.tertiaryText.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                    } else {
                        Text("Bereit")
                            .font(.system(size: FontSize.sm, weight: .medium))
                            .foregroundColor(PauseColors.accent)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(PauseColors.accent.opacity(0.15))
                            .cornerRadius(CornerRadius.sm)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: FontSize.sm, weight: .semibold))
                        .foregroundColor(PauseColors.tertiaryText)
                        .padding(.top, Spacing.xxs)
                }
            }
            
            // Info banner when blocked by tag
            if isBlockedByTag, let activeTag = appState.getActiveTag() {
                Divider()
                    .background(PauseColors.cardBorder)
                    .padding(.vertical, Spacing.xxs)
                
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(Color.orange)
                    
                    Text("Wartet auf Deaktivierung von '\(activeTag.name)'")
                        .font(.system(size: FontSize.xs))
                        .foregroundColor(PauseColors.secondaryText)
                    
                    Spacer()
                }
            }
            
            // Weekday indicators
            if !profile.schedule.selectedWeekdays.isEmpty {
                Divider()
                    .background(PauseColors.cardBorder)
                    .padding(.vertical, Spacing.xxs)
                
                HStack(spacing: Spacing.xs) {
                    ForEach(Weekday.allCasesSorted, id: \.self) { weekday in
                        Text(weekday.shortName)
                            .font(.system(size: FontSize.xs, weight: .semibold))
                            .foregroundColor(profile.schedule.selectedWeekdays.contains(weekday) ? .white : PauseColors.tertiaryText)
                            .frame(width: 32, height: 32)
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
                            .cornerRadius(CornerRadius.sm)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(PauseColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(
                            isActuallyActive
                                ? Color.green.opacity(0.5)
                                : PauseColors.cardBorder,
                            lineWidth: isActuallyActive ? 2 : 1
                        )
                )
                .shadow(
                    color: isActuallyActive ? Color.green.opacity(0.2) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    private var formattedSchedule: String {
        "\(profile.schedule.startTime.formattedString) - \(profile.schedule.endTime.formattedString)"
    }
}

#Preview {
    TimeProfilesView()
}
