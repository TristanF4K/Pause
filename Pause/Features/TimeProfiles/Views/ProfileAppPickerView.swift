//
//  TimeProfileAppPickerView.swift
//  Pause.
//
//  Created by Tristan Srebot on 14.01.26.
//

import SwiftUI
import FamilyControls

struct TimeProfileAppPickerView: View {
    @Binding var isPresented: Bool
    let profile: TimeProfile
    
    // MARK: - Environment Dependencies
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var timeProfileController: TimeProfileController
    @EnvironmentObject private var selectionManager: SelectionManager
    
    // MARK: - Local State
    @State private var selection = FamilyActivitySelection()
    
    var body: some View {
        NavigationStack {
            ZStack {
                PauseColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    // Header Info
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 48))
                            .foregroundColor(PauseColors.accent)
                            .padding(Spacing.md)
                            .background(
                                Circle()
                                    .fill(PauseColors.tertiaryBackground)
                            )
                        
                        Text("Apps für \(profile.name) auswählen")
                            .font(.system(size: FontSize.lg, weight: .semibold))
                            .foregroundColor(PauseColors.primaryText)
                        
                        Text("Wähle die Apps und Kategorien aus, die blockiert werden sollen")
                            .font(.system(size: FontSize.base))
                            .foregroundColor(PauseColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, Spacing.xl)
                    
                    // Selection Info
                    if hasSelection {
                        HStack(spacing: Spacing.lg) {
                            VStack(spacing: Spacing.xxs) {
                                Text("\(selection.applicationTokens.count)")
                                    .font(.system(size: FontSize.xl, weight: .bold))
                                    .foregroundColor(PauseColors.accent)
                                Text("Apps")
                                    .font(.system(size: FontSize.sm))
                                    .foregroundColor(PauseColors.secondaryText)
                            }
                            
                            Divider()
                                .frame(height: 40)
                                .background(PauseColors.cardBorder)
                            
                            VStack(spacing: Spacing.xxs) {
                                Text("\(selection.categoryTokens.count)")
                                    .font(.system(size: FontSize.xl, weight: .bold))
                                    .foregroundColor(PauseColors.accent)
                                Text("Kategorien")
                                    .font(.system(size: FontSize.sm))
                                    .foregroundColor(PauseColors.secondaryText)
                            }
                        }
                        .padding(Spacing.md)
                        .card()
                        .padding(.horizontal, Spacing.lg)
                    }
                    
                    // Family Activity Picker
                    FamilyActivityPicker(selection: $selection)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Apps auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        saveSelection()
                    }
                    .disabled(!hasSelection)
                }
            }
        }
        .onAppear {
            loadExistingSelection()
        }
    }
    
    private var hasSelection: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }
    
    private func loadExistingSelection() {
        if let existingSelection = selectionManager.getSelection(for: profile.id) {
            selection = existingSelection
        }
    }
    
    private func saveSelection() {
        timeProfileController.linkAppsToProfile(profile: profile, selection: selection)
        isPresented = false
    }
}

#Preview {
    @Previewable @State var isPresented = true
    TimeProfileAppPickerView(isPresented: $isPresented, profile: TimeProfile(name: "Arbeit"))
}
