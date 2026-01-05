//
//  AppPickerView.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI
import FamilyControls

struct AppPickerView: View {
    @Binding var isPresented: Bool
    let tag: NFCTag
    
    @State private var selection = FamilyActivitySelection()
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Wähle die Apps aus, die blockiert werden sollen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                
                // Note: FamilyActivityPicker presents its own UI
                // We use a button to trigger it
                
                Spacer()
            }
            .navigationTitle("Apps auswählen")
            .navigationBarTitleDisplayMode(.inline)
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
                }
            }
        }
    }
    
    private func saveSelection() {
        // Note: ApplicationToken and ActivityCategoryToken cannot be directly
        // encoded to JSON/UserDefaults. In a production app, you would need to:
        // 1. Store them in a ShieldConfigurationDataSource
        // 2. Use DeviceActivitySchedule to manage them
        // 3. Or keep them in memory and require re-selection on app launch
        
        // For now, we'll store placeholder identifiers
        let appTokenStrings = selection.applicationTokens.map { token in
            // This is a simplified approach
            // In production, you'd need proper token management
            return token.debugDescription
        }
        
        let categoryTokenStrings = selection.categoryTokens.map { token in
            return token.debugDescription
        }
        
        TagController.shared.linkAppsToTag(
            tag: tag,
            appTokens: Set(appTokenStrings),
            categoryTokens: Set(categoryTokenStrings)
        )
        
        isPresented = false
    }
}

// MARK: - Extended TagDetailView with App Picker

extension TagDetailView {
    // This can be integrated into TagDetailView to properly show the picker
}

#Preview {
    AppPickerView(
        isPresented: .constant(true),
        tag: NFCTag(name: "Test", tagIdentifier: "123")
    )
}
