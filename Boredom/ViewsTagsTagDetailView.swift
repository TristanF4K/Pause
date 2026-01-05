//
//  TagDetailView.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI
import FamilyControls

struct TagDetailView: View {
    let tag: NFCTag
    
    @StateObject private var appState = AppState.shared
    @State private var editedName: String
    @State private var showingAppPicker = false
    @State private var isEditing = false
    
    init(tag: NFCTag) {
        self.tag = tag
        _editedName = State(initialValue: tag.name)
    }
    
    var body: some View {
        List {
            Section("Tag-Info") {
                if isEditing {
                    TextField("Name", text: $editedName)
                } else {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(tag.name)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Text("Tag-ID")
                    Spacer()
                    Text(tag.tagIdentifier.prefix(12) + "...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(tag.isActive ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(tag.isActive ? "Aktiv" : "Inaktiv")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                Button(action: { showingAppPicker = true }) {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                        Text("Apps auswählen")
                        Spacer()
                        Text("\(tag.linkedAppTokens.count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Blockierte Apps")
            } footer: {
                Text("Wähle die Apps aus, die bei Aktivierung dieses Tags blockiert werden sollen.")
            }
            
            Section {
                Button(action: testTag) {
                    HStack {
                        Image(systemName: "play.circle")
                        Text("Tag testen")
                    }
                }
            }
        }
        .navigationTitle(tag.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Fertig" : "Bearbeiten") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
        }
        .familyActivityPicker(isPresented: $showingAppPicker, selection: .constant(FamilyActivitySelection()))
    }
    
    private func saveChanges() {
        var updatedTag = tag
        updatedTag.name = editedName
        appState.updateTag(updatedTag)
    }
    
    private func testTag() {
        TagController.shared.handleTagScan(identifier: tag.tagIdentifier)
    }
}

#Preview {
    NavigationStack {
        TagDetailView(tag: NFCTag(
            name: "Schreibtisch",
            tagIdentifier: "ABC123XYZ789",
            linkedAppTokens: ["1", "2", "3"]
        ))
    }
}
