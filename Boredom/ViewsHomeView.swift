//
//  HomeView.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var appState = AppState.shared
    @StateObject private var nfcController = NFCController.shared
    @State private var showingScanView = false
    @State private var showingAuthorizationAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Card
                    StatusCardView(isBlocking: appState.isBlocking)
                        .padding(.horizontal)
                    
                    if !appState.isAuthorized {
                        // Authorization Required Card
                        authorizationRequiredCard
                    }
                    
                    // Tags Section
                    tagsSection
                    
                    // Quick Scan Button
                    if appState.isAuthorized && !appState.registeredTags.isEmpty {
                        quickScanButton
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("FocusLock")
            .sheet(isPresented: $showingScanView) {
                ScanView()
            }
            .alert("Autorisierung erforderlich", isPresented: $showingAuthorizationAlert) {
                Button("Einstellungen öffnen") {
                    requestAuthorization()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("FocusLock benötigt Zugriff auf Screen Time, um Apps zu blockieren.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var authorizationRequiredCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Autorisierung erforderlich")
                .font(.headline)
            
            Text("FocusLock benötigt Zugriff auf Screen Time, um Apps zu blockieren.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: requestAuthorization) {
                Text("Zugriff erlauben")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .padding(.horizontal)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Deine Tags")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: TagListView()) {
                    Text("Alle")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            
            if appState.registeredTags.isEmpty {
                EmptyStateView(
                    icon: "tag",
                    title: "Keine Tags",
                    message: "Füge deinen ersten NFC Tag hinzu, um zu beginnen.",
                    actionTitle: "Tag hinzufügen",
                    action: { showingScanView = true }
                )
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(appState.registeredTags.prefix(5)) { tag in
                            TagCard(tag: tag)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var quickScanButton: some View {
        Button(action: { showingScanView = true }) {
            HStack {
                Image(systemName: "wave.3.right")
                Text("Tag scannen")
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 8)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func requestAuthorization() {
        Task {
            do {
                try await ScreenTimeController.shared.requestAuthorization()
                await appState.checkAuthorizationStatus()
            } catch {
                showingAuthorizationAlert = true
            }
        }
    }
}

#Preview {
    HomeView()
}
