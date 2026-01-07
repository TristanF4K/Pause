//
//  AppPickerView.swift
//  Pause.
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
    @StateObject private var selectionManager = SelectionManager.shared
    
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
                        
                        Text("Apps für \(tag.name) auswählen")
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
                        selectionInfoCard
                    }
                    
                    Spacer()
                    
                    // Info Card
                    infoCard
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Apps auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        isPresented = false
                    }
                    .foregroundColor(PauseColors.accent)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        saveSelection()
                    }
                    .foregroundColor(PauseColors.accent)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onAppear {
            // Load existing selection
            if let existingSelection = selectionManager.getSelection(for: tag.id) {
                selection = existingSelection
            }
        }
    }
    
    // MARK: - Subviews
    
    private var hasSelection: Bool {
        let info = selectionManager.selectionInfo(for: tag.id)
        return info.apps > 0 || info.categories > 0
    }
    
    private var selectionInfoCard: some View {
        HStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xs) {
                let info = selectionManager.selectionInfo(for: tag.id)
                Text("\(info.apps)")
                    .font(.system(size: FontSize.xxl, weight: .bold))
                    .foregroundColor(PauseColors.primaryText)
                Text("Apps")
                    .font(.system(size: FontSize.sm))
                    .foregroundColor(PauseColors.secondaryText)
            }
            
            Rectangle()
                .fill(PauseColors.cardBorder)
                .frame(width: 1, height: 40)
            
            VStack(spacing: Spacing.xs) {
                let info = selectionManager.selectionInfo(for: tag.id)
                Text("\(info.categories)")
                    .font(.system(size: FontSize.xxl, weight: .bold))
                    .foregroundColor(PauseColors.primaryText)
                Text("Kategorien")
                    .font(.system(size: FontSize.sm))
                    .foregroundColor(PauseColors.secondaryText)
            }
        }
        .padding(Spacing.lg)
        .card()
    }
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Hinweis", systemImage: "info.circle.fill")
                .font(.system(size: FontSize.md, weight: .semibold))
                .foregroundColor(PauseColors.accent)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                bulletPoint("Apps und Kategorien werden bei Aktivierung des Tags blockiert")
                bulletPoint("Systemapps können nicht blockiert werden")
                bulletPoint("Die Auswahl kann jederzeit geändert werden")
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PauseColors.tertiaryBackground)
        .cornerRadius(CornerRadius.lg)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("•")
                .font(.system(size: FontSize.base))
                .foregroundColor(PauseColors.dimGray)
            Text(text)
                .font(.system(size: FontSize.sm))
                .foregroundColor(PauseColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Actions
    
    private func saveSelection() {
        // Use the modern API that accepts FamilyActivitySelection directly
        // This properly handles encoding and storage of tokens
        TagController.shared.linkAppsToTag(
            tag: tag,
            selection: selection
        )
        
        isPresented = false
    }
}

// MARK: - App Picker Modal Modifier

struct AppPickerModal: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selection: FamilyActivitySelection
    let headerTitle: String
    let onSave: (FamilyActivitySelection) -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    ZStack {
                        PauseColors.background
                            .ignoresSafeArea()
                        
                        VStack {
                            Text(headerTitle)
                                .font(.system(size: FontSize.lg, weight: .semibold))
                                .foregroundColor(PauseColors.primaryText)
                                .padding()
                            
                            Divider()
                                .background(PauseColors.cardBorder)
                            
                            FamilyActivityPicker(selection: $selection)
                                .ignoresSafeArea()
                        }
                    }
                    .navigationTitle("Apps auswählen")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") {
                                isPresented = false
                            }
                            .foregroundColor(PauseColors.accent)
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Fertig") {
                                onSave(selection)
                                isPresented = false
                            }
                            .foregroundColor(PauseColors.accent)
                        }
                    }
                }
                .preferredColorScheme(.dark)
            }
    }
}

extension View {
    func appPickerModal(
        isPresented: Binding<Bool>,
        selection: Binding<FamilyActivitySelection>,
        headerTitle: String = "Wähle Apps und Kategorien",
        onSave: @escaping (FamilyActivitySelection) -> Void
    ) -> some View {
        self.modifier(AppPickerModal(
            isPresented: isPresented,
            selection: selection,
            headerTitle: headerTitle,
            onSave: onSave
        ))
    }
}

#Preview {
    AppPickerView(
        isPresented: .constant(true),
        tag: NFCTag(name: "Test", tagIdentifier: "123")
    )
}
