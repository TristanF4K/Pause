//
//  TestModeView.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct TestModeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appState = AppState.shared
    @State private var showingDeleteConfirmation = false
    @State private var showingTestTagCreation = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .foregroundStyle(.orange)
                        Text("Test-Modus")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Entwicklung")
                } footer: {
                    Text("Diese Funktionen sind nur für Tests während der Entwicklung gedacht.")
                        .font(.caption)
                }
                
                Section("Test-Daten") {
                    Button(action: {
                        showingTestTagCreation = true
                    }) {
                        Label("Test-Tags erstellen", systemImage: "plus.circle.fill")
                    }
                    .disabled(!appState.registeredTags.isEmpty)
                    
                    if !appState.registeredTags.isEmpty {
                        Button(role: .destructive, action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Alle Tags löschen", systemImage: "trash.fill")
                        }
                    }
                }
                
                if !appState.registeredTags.isEmpty {
                    Section("Scan simulieren") {
                        ForEach(appState.registeredTags) { tag in
                            Button(action: {
                                TestDataController.shared.simulateTagScan(tagIdentifier: tag.tagIdentifier)
                            }) {
                                HStack {
                                    Text(tag.name)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    if tag.isActive {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                    
                                    Image(systemName: "hand.tap.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Status:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(appState.isBlocking ? "🔒 Blockiert" : "🔓 Entsperrt")
                                    .foregroundStyle(appState.isBlocking ? .orange : .green)
                            }
                            
                            if let profile = appState.activeProfile {
                                HStack {
                                    Text("Aktives Profil:")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(profile.name)
                                        .foregroundStyle(.secondary)
                                }
                                
                                HStack {
                                    Text("Blockierte Apps:")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(profile.blockedAppTokens.count)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            HStack {
                                Text("Registrierte Tags:")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(appState.registeredTags.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    } header: {
                        Text("Debug-Info")
                    }
                }
            }
            .navigationTitle("Test-Modus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .alert("Test-Tags erstellen?", isPresented: $showingTestTagCreation) {
                Button("Erstellen") {
                    TestDataController.shared.createTestTags()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Es werden 4 Test-Tags erstellt, die Sie ohne NFC-Chip testen können.")
            }
            .alert("Alle Tags löschen?", isPresented: $showingDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    TestDataController.shared.clearAllTags()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }
}

#Preview {
    TestModeView()
}
