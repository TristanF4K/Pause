//
//  TagDetailView.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI
import FamilyControls

struct TagDetailView: View {
    let tag: NFCTag
    
    // MARK: - Environment Dependencies
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var tagController: TagController
    @EnvironmentObject private var selectionManager: SelectionManager
    
    // MARK: - Local State
    @State private var editedName: String
    @State private var showingAppPicker = false
    @State private var isEditing = false
    @State private var selection: FamilyActivitySelection
    @Environment(\.colorScheme) var colorScheme
    
    init(tag: NFCTag) {
        self.tag = tag
        _editedName = State(initialValue: tag.name)
        
        // Load existing selection if available
        let existingSelection = SelectionManager.shared.getSelection(for: tag.id) ?? FamilyActivitySelection()
        _selection = State(initialValue: existingSelection)
    }
    
    // Get current tag from appState to reflect real-time updates
    private var currentTag: NFCTag? {
        appState.registeredTags.first(where: { $0.id == tag.id })
    }
    
    // Check if this tag is currently active
    private var isTagActive: Bool {
        currentTag?.isActive ?? false
    }
    
    // Can only edit when tag is NOT active
    private var canEdit: Bool {
        !isTagActive
    }
    
    var body: some View {
        ZStack {
            PauseColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Tag Info Card
                    tagInfoCard
                    
                    // App Selection Card
                    appSelectionCard
                }
                .padding(Spacing.lg)
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
                .foregroundColor(PauseColors.accent)
                .disabled(!canEdit)
                .opacity(canEdit ? 1.0 : 0.6)
            }
        }
        .familyActivityPicker(
            isPresented: $showingAppPicker,
            selection: $selection
        )
        .onChange(of: selection) { oldValue, newValue in
            // Save selection when it changes
            saveAppSelection(newValue)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    
    private var tagInfoCard: some View {
        InfoCard(title: "Tag-Info", icon: "info.circle.fill") {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Name (editable)
                HStack {
                    Text("Name")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.secondaryText)
                    Spacer()
                    if isEditing {
                        TextField("Name", text: $editedName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(tag.name)
                            .font(.system(size: FontSize.base, weight: .medium))
                            .foregroundColor(PauseColors.primaryText)
                    }
                }
                
                // Tag ID
                InfoRow(
                    label: "Tag-ID",
                    value: formatTagID(tag.tagIdentifier)
                )
                
                // Status
                InfoRowWithView(label: "Status") {
                    StatusIndicator(style: tag.isActive ? .active : .inactive)
                }
            }
        }
    }
    
    private var appSelectionCard: some View {
        let info = selectionManager.selectionInfo(for: tag.id)
        
        return AppSelectionCard(
            title: "Blockierte Apps",
            selectionInfo: SelectionInfo(appCount: info.apps, categoryCount: info.categories),
            isDisabled: !canEdit,
            footerText: canEdit ? "Wähle die Apps aus, die bei Aktivierung dieses Tags blockiert werden sollen." : nil,
            warningTitle: !canEdit ? "Tag ist aktiv" : nil,
            warningMessage: !canEdit ? "Du kannst Apps nicht ändern, während der Tag aktiv ist und Apps blockiert." : nil
        ) {
            showingAppPicker = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTagID(_ id: String) -> String {
        if id.count > 12 {
            return String(id.prefix(12)) + "..."
        }
        return id
    }
    
    private func saveChanges() {
        var updatedTag = tag
        updatedTag.name = editedName
        appState.updateTag(updatedTag)
    }
    
    private func saveAppSelection(_ selection: FamilyActivitySelection) {
        // Use TagController to properly save the selection
        tagController.linkAppsToTag(tag: tag, selection: selection)
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
