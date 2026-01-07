//
//  TagListView.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct TagListView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingAddTagView = false
    @State private var tagToDelete: NFCTag?
    @State private var showingDeleteAlert = false
    @State private var showingActiveTagWarning = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                PauseColors.background
                    .ignoresSafeArea()
                
                Group {
                    if appState.registeredTags.isEmpty {
                        VStack {
                            Spacer()
                            EmptyStateView(
                                icon: "tag",
                                title: "Keine Tags",
                                message: "Füge deinen ersten NFC Tag hinzu, um Apps zu blockieren.",
                                actionTitle: "Tag hinzufügen",
                                action: { showingAddTagView = true }
                            )
                            .padding(.horizontal, Spacing.lg)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(appState.registeredTags) { tag in
                                NavigationLink {
                                    TagDetailView(tag: tag)
                                } label: {
                                    TagRowView(tag: tag)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.lg, bottom: Spacing.xs, trailing: Spacing.lg))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if tag.isActive {
                                        Button {
                                            showingActiveTagWarning = true
                                        } label: {
                                            Label("Aktiv", systemImage: "lock.fill")
                                        }
                                        .tint(.orange)
                                    } else {
                                        Button(role: .destructive) {
                                            tagToDelete = tag
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("Löschen", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Meine Tags")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTagView = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(PauseColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddTagView) {
                AddTagView()
            }
            .alert("Tag löschen?", isPresented: $showingDeleteAlert, presenting: tagToDelete) { tag in
                Button("Löschen", role: .destructive) {
                    print("🗑️ Deleting tag: \(tag.name) (ID: \(tag.id))")
                    TagController.shared.deleteTag(tag: tag)
                }
                Button("Abbrechen", role: .cancel) {}
            } message: { tag in
                Text("Möchtest du '\(tag.name)' wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
            }
            .alert("Tag ist aktiv", isPresented: $showingActiveTagWarning) {
                Button("OK") {}
            } message: {
                Text("Dieser Tag ist derzeit aktiv und kann nicht gelöscht werden. Deaktiviere ihn zuerst durch erneutes Scannen.")
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct TagRowView: View {
    let tag: NFCTag
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(tag.isActive ? PauseColors.success.opacity(0.2) : PauseColors.accent.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "tag.fill")
                    .font(.system(size: FontSize.lg))
                    .foregroundColor(tag.isActive ? PauseColors.success : PauseColors.accent)
            }
            
            // Info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(tag.name)
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
                
                HStack(spacing: Spacing.xs) {
                    Text("\(tag.linkedAppTokens.count) Apps verknüpft")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(PauseColors.secondaryText)
                    
                    if tag.isActive {
                        Text("•")
                            .font(.system(size: FontSize.sm))
                            .foregroundColor(PauseColors.tertiaryText)
                        
                        Text("Aktiv")
                            .font(.system(size: FontSize.sm, weight: .medium))
                            .foregroundColor(PauseColors.success)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator for active tags only
            if tag.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: FontSize.lg))
                    .foregroundColor(PauseColors.success)
            }
        }
        .padding(Spacing.md)
        .card()
        .contentShape(Rectangle()) // Makes the entire card tappable
    }
}

#Preview {
    TagListView()
}
