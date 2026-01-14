//
//  ScheduleEditorView.swift
//  Pause.
//
//  Created by Tristan Srebot on 14.01.26.
//

import SwiftUI

struct ScheduleEditorView: View {
    let profile: TimeProfile
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Environment Dependencies
    @EnvironmentObject private var timeProfileController: TimeProfileController
    
    // MARK: - Local State
    @State private var selectedWeekdays: Set<Weekday>
    @State private var startTime: Date
    @State private var endTime: Date
    
    init(profile: TimeProfile) {
        self.profile = profile
        _selectedWeekdays = State(initialValue: profile.schedule.selectedWeekdays)
        _startTime = State(initialValue: profile.schedule.startTime.asDate)
        _endTime = State(initialValue: profile.schedule.endTime.asDate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                PauseColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Weekdays Section
                        weekdaysSection
                        
                        // Time Range Section
                        timeRangeSection
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Zeitplan bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        saveSchedule()
                    }
                    .disabled(selectedWeekdays.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Weekdays Section
    
    private var weekdaysSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Wochentage")
                .font(.system(size: FontSize.base, weight: .semibold))
                .foregroundColor(PauseColors.tertiaryText)
                .padding(.horizontal, Spacing.md)
            
            VStack(spacing: Spacing.xs) {
                ForEach(Weekday.allCasesSorted, id: \.self) { weekday in
                    WeekdayToggleRow(
                        weekday: weekday,
                        isSelected: selectedWeekdays.contains(weekday)
                    ) {
                        toggleWeekday(weekday)
                    }
                }
            }
            .card()
        }
    }
    
    // MARK: - Time Range Section
    
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Zeitbereich")
                .font(.system(size: FontSize.base, weight: .semibold))
                .foregroundColor(PauseColors.tertiaryText)
                .padding(.horizontal, Spacing.md)
            
            VStack(spacing: 0) {
                // Start Time
                HStack {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: FontSize.lg))
                        .foregroundColor(PauseColors.accent)
                        .frame(width: 32)
                    
                    Text("Von")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.primaryText)
                    
                    Spacer()
                    
                    DatePicker(
                        "",
                        selection: $startTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .colorScheme(.dark)
                }
                .padding(Spacing.md)
                
                Divider()
                    .background(PauseColors.cardBorder)
                    .padding(.horizontal, Spacing.md)
                
                // End Time
                HStack {
                    Image(systemName: "sunset.fill")
                        .font(.system(size: FontSize.lg))
                        .foregroundColor(PauseColors.accent)
                        .frame(width: 32)
                    
                    Text("Bis")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.primaryText)
                    
                    Spacer()
                    
                    DatePicker(
                        "",
                        selection: $endTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .colorScheme(.dark)
                }
                .padding(Spacing.md)
            }
            .card()
            
            // Info
            if startTime >= endTime {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.warning)
                    
                    Text("Die Endzeit muss nach der Startzeit liegen.")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(PauseColors.warning)
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleWeekday(_ weekday: Weekday) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }
    
    private func saveSchedule() {
        let schedule = TimeSchedule(
            selectedWeekdays: selectedWeekdays,
            startTime: TimeOfDay(from: startTime),
            endTime: TimeOfDay(from: endTime)
        )
        
        timeProfileController.updateSchedule(profile: profile, schedule: schedule)
        dismiss()
    }
}

// MARK: - Weekday Toggle Row

struct WeekdayToggleRow: View {
    let weekday: Weekday
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(weekday.name)
                    .font(.system(size: FontSize.base))
                    .foregroundColor(PauseColors.primaryText)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? PauseColors.accent : PauseColors.cardBorder, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(PauseColors.accent)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                isSelected ?
                PauseColors.accent.opacity(0.1) :
                    Color.clear
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScheduleEditorView(profile: TimeProfile(name: "Arbeit"))
}
