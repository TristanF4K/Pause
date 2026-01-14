//
//  AddTimeProfileView.swift
//  Pause.
//
//  Created by Tristan Srebot on 14.01.26.
//

import SwiftUI

struct AddTimeProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Environment Dependencies
    @EnvironmentObject private var timeProfileController: TimeProfileController
    
    // MARK: - Local State
    @State private var profileName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                PauseColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Name Section
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("Profilname")
                                .font(.system(size: FontSize.base, weight: .semibold))
                                .foregroundColor(PauseColors.tertiaryText)
                                .padding(.horizontal, Spacing.md)
                            
                            VStack(spacing: 0) {
                                TextField("z.B. Arbeit, Schule, Lernen", text: $profileName)
                                    .font(.system(size: FontSize.base))
                                    .foregroundColor(PauseColors.primaryText)
                                    .padding(Spacing.md)
                                    .background(PauseColors.cardBackground)
                                    .cornerRadius(CornerRadius.md)
                            }
                            .card()
                        }
                        
                        // Info
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: FontSize.base))
                                    .foregroundColor(PauseColors.accent)
                                
                                Text("Nach dem Erstellen kannst du Zeitplan und Apps festlegen.")
                                    .font(.system(size: FontSize.sm))
                                    .foregroundColor(PauseColors.secondaryText)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Neues Zeitprofil")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        createProfile()
                    }
                    .disabled(profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Fehler", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createProfile() {
        let trimmedName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Bitte gib einen Namen ein."
            showingError = true
            return
        }
        
        // Create the profile
        _ = timeProfileController.createProfile(name: trimmedName)
        
        dismiss()
    }
}

#Preview {
    AddTimeProfileView()
}
