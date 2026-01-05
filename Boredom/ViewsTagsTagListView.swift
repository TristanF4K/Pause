//
//  TagListView.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct TagListView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingAddTagView = false
    @State private var tagToDelete: NFCTag?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if appState.registeredTags.isEmpty {
                    EmptyStateView(
                        icon: "tag",
                        title: "Keine Tags",
                        message: "Füge deinen ersten NFC Tag hinzu, um Apps zu blockieren.",
                        actionTitle: "Tag hinzufügen",
                        action: { showingAddTagView = true }
                    )
                } else {
                    List {
                        ForEach(appState.registeredTags) { tag in
                            NavigationLink(destination: TagDetailView(tag: tag)) {
                                TagRowView(tag: tag)
                            }
                        }
                        .onDelete(perform: deleteTags)
                    }
                }
            }
            .navigationTitle("Meine Tags")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTagView = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTagView) {
                AddTagView()
            }
            .alert("Tag löschen?", isPresented: $showingDeleteAlert, presenting: tagToDelete) { tag in
                Button("Löschen", role: .destructive) {
                    TagController.shared.deleteTag(tag: tag)
                }
                Button("Abbrechen", role: .cancel) {}
            } message: { tag in
                Text("Möchtest du '\(tag.name)' wirklich löschen?")
            }
        }
    }
    
    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = appState.registeredTags[index]
            tagToDelete = tag
            showingDeleteAlert = true
        }
    }
}

struct TagRowView: View {
    let tag: NFCTag
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(tag.isActive ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "tag.fill")
                    .foregroundStyle(tag.isActive ? .orange : .blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(tag.name)
                    .font(.headline)
                
                Text("\(tag.linkedAppTokens.count) Apps verknüpft")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status
            if tag.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TagListView()
}
