//
//  SettingsView.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var screenTimeController = ScreenTimeController.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Screen Time Zugriff")
                        Spacer()
                        if appState.isAuthorized {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Erlaubt")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Nicht erlaubt")
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Berechtigungen")
                } footer: {
                    if !appState.isAuthorized {
                        Text("FocusLock benötigt Zugriff auf Screen Time, um Apps zu blockieren.")
                    }
                }
                
                Section("App-Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Registrierte Tags")
                        Spacer()
                        Text("\(appState.registeredTags.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Link(destination: URL(string: "https://support.apple.com/de-de/guide/iphone/iph3c5b1b51a/ios")!) {
                        HStack {
                            Text("Screen Time Hilfe")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                    
                    Link(destination: URL(string: "https://support.apple.com/de-de/HT211852")!) {
                        HStack {
                            Text("Über NFC auf dem iPhone")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Hilfe & Support")
                }
                
                Section {
                    Button(role: .destructive, action: resetApp) {
                        Text("Alle Daten löschen")
                    }
                } footer: {
                    Text("Löscht alle registrierten Tags und Einstellungen. Diese Aktion kann nicht rückgängig gemacht werden.")
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
    
    private func resetApp() {
        // Stop all blocking
        screenTimeController.unblockAll()
        
        // Clear all data
        appState.registeredTags = []
        appState.activeProfile = nil
        appState.isBlocking = false
        appState.saveData()
        PersistenceController.shared.clearActiveProfile()
    }
}

#Preview {
    SettingsView()
}
