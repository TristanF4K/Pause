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
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: FontSize.lg))
                    .foregroundColor(PauseColors.accent)
                Text("Tag-Info")
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
                Spacer()
            }
            .padding(Spacing.lg)
            
            Divider()
                .background(PauseColors.cardBorder)
            
            // Content
            VStack(spacing: Spacing.md) {
                // Name
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
                HStack {
                    Text("Tag-ID")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.secondaryText)
                    Spacer()
                    Text(formatTagID(tag.tagIdentifier))
                        .font(.system(size: FontSize.sm, design: .monospaced))
                        .foregroundColor(PauseColors.tertiaryText)
                }
                
                // Status
                HStack {
                    Text("Status")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.secondaryText)
                    Spacer()
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(tag.isActive ? PauseColors.success : PauseColors.dimGray)
                            .frame(width: 8, height: 8)
                        Text(tag.isActive ? "Aktiv" : "Inaktiv")
                            .font(.system(size: FontSize.base, weight: .medium))
                            .foregroundColor(tag.isActive ? PauseColors.success : PauseColors.dimGray)
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .card()
    }
    
    private var appSelectionCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: FontSize.lg))
                    .foregroundColor(PauseColors.accent)
                Text("Blockierte Apps")
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
                Spacer()
            }
            .padding(Spacing.lg)
            
            Divider()
                .background(PauseColors.cardBorder)
            
            // Selection Button
            Button(action: { showingAppPicker = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Apps auswählen")
                            .font(.system(size: FontSize.base, weight: .medium))
                            .foregroundColor(PauseColors.primaryText)
                        
                        let info = selectionManager.selectionInfo(for: tag.id)
                        if info.apps > 0 || info.categories > 0 {
                            Text("\(info.apps) Apps, \(info.categories) Kategorien")
                                .font(.system(size: FontSize.sm))
                                .foregroundColor(PauseColors.secondaryText)
                        } else {
                            Text("Keine Apps ausgewählt")
                                .font(.system(size: FontSize.sm))
                                .foregroundColor(PauseColors.tertiaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.dimGray)
                }
                .padding(Spacing.lg)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canEdit)
            .opacity(canEdit ? 1.0 : 0.6)
            
            // Warning when tag is active
            if !canEdit {
                Divider()
                    .background(PauseColors.cardBorder)
                
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: FontSize.base))
                        .foregroundColor(PauseColors.warning)
                    
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Tag ist aktiv")
                            .font(.system(size: FontSize.sm, weight: .medium))
                            .foregroundColor(PauseColors.warning)
                        
                        Text("Du kannst Apps nicht ändern, während der Tag aktiv ist und Apps blockiert.")
                            .font(.system(size: FontSize.xs))
                            .foregroundColor(PauseColors.secondaryText)
                    }
                }
                .padding(Spacing.lg)
            }
            
            // Footer
            if canEdit {
                Text("Wähle die Apps aus, die bei Aktivierung dieses Tags blockiert werden sollen.")
                    .font(.system(size: FontSize.sm))
                    .foregroundColor(PauseColors.tertiaryText)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.lg)
            }
        }
        .card()
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
