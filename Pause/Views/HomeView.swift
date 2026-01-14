//
//  HomeView.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct HomeView: View {
    // MARK: - Environment Dependencies
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var tagController: TagController
    @EnvironmentObject private var screenTimeController: ScreenTimeController
    @EnvironmentObject private var selectionManager: SelectionManager
    
    // MARK: - Local Controllers
    @StateObject private var nfcController = NFCController.shared
    
    // MARK: - Local State
    @State private var showingAuthorizationAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var successMessage = ""
    @State private var errorMessage = ""
    @State private var scannedTag: NFCTag?
    @State private var showingAddTagView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                PauseColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        headerView
                        
                        // Status Card
                        StatusCardView(isBlocking: appState.isBlocking)
                            .padding(.horizontal, Spacing.lg)
                        
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
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationBarHidden(true)
            .alert("Autorisierung erforderlich", isPresented: $showingAuthorizationAlert) {
                Button("Einstellungen öffnen") {
                    requestAuthorization()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Pause. benötigt Zugriff auf Screen Time, um Apps zu blockieren.")
            }
            .alert("Erfolg!", isPresented: $showingSuccessAlert, presenting: scannedTag) { tag in
                Button("OK") {}
            } message: { tag in
                Text(successMessage)
            }
            .alert("Fehler", isPresented: $showingErrorAlert) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingAddTagView) {
                AddTagView()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Pause.")
                    .font(.system(size: FontSize.xxxl, weight: .bold))
                    .foregroundColor(PauseColors.primaryText)
                
                Spacer()
            }
            
            Text("Konzentriere dich auf das Wichtige")
                .font(.system(size: FontSize.md))
                .foregroundColor(PauseColors.secondaryText)
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    private var authorizationRequiredCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock.shield")
                .font(.system(size: 56))
                .foregroundColor(PauseColors.warning)
            
            VStack(spacing: Spacing.xs) {
                Text("Autorisierung erforderlich")
                    .font(.system(size: FontSize.lg, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
                
                Text("Pause. benötigt Zugriff auf Screen Time, um Apps zu blockieren.")
                    .font(.system(size: FontSize.base))
                    .foregroundColor(PauseColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: requestAuthorization) {
                Text("Zugriff erlauben")
            }
            .primaryButton()
            .padding(.top, Spacing.xs)
        }
        .padding(Spacing.lg)
        .card()
        .padding(.horizontal, Spacing.lg)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeader("Deine Tags")
                Spacer()
                NavigationLink(destination: TagListView()) {
                    Text("Alle")
                        .font(.system(size: FontSize.base, weight: .medium))
                        .foregroundColor(PauseColors.accent)
                }
            }
            .padding(.horizontal, Spacing.lg)
            
            if appState.registeredTags.isEmpty {
                EmptyStateView(
                    icon: "tag",
                    title: "Keine Tags",
                    message: "Füge deinen ersten NFC Tag hinzu, um zu beginnen.",
                    actionTitle: "Tag hinzufügen",
                    action: { showingAddTagView = true }
                )
                .padding(.horizontal, Spacing.lg)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(appState.registeredTags.prefix(5)) { tag in
                            TagCard(tag: tag)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }
        }
    }
    
    private var quickScanButton: some View {
        Button(action: startScanning) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "wave.3.right")
                    .font(.system(size: FontSize.lg))
                Text("Tag scannen")
                    .font(.system(size: FontSize.md, weight: .semibold))
            }
        }
        .primaryButton()
        .padding(.horizontal, Spacing.lg)
    }
    
    
    // MARK: - Actions
    
    private func startScanning() {
        nfcController.startScanning { result in
            switch result {
            case .success(let identifier):
                handleScannedIdentifier(identifier)
            case .failure(let error):
                if case .userCancelled = error {
                    // User cancelled - don't show error
                    return
                }
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
    }
    
    private func handleScannedIdentifier(_ identifier: String) {
        // Get the scan result from TagController
        Task {
            let scanResult = await tagController.handleTagScan(identifier: identifier)
            
            await MainActor.run {
                switch scanResult {
                case .success(let tag, let wasActivated):
                    scannedTag = tag
                    
                    // Set success message based on what happened
                    if wasActivated {
                        successMessage = "'\(tag.name)' wurde aktiviert"
                    } else {
                        successMessage = "'\(tag.name)' wurde deaktiviert"
                    }
                    
                    showingSuccessAlert = true
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                case .notRegistered:
                    errorMessage = "Dieser Tag ist nicht registriert. Bitte füge ihn zuerst in den Einstellungen hinzu."
                    showingErrorAlert = true
                    
                case .noAppsLinked(let tagName):
                    errorMessage = "Der Tag '\(tagName)' hat keine Apps verknüpft. Bitte wähle zuerst Apps aus."
                    showingErrorAlert = true
                    
                case .blockedByOtherTag(let activeTagName, _):
                    errorMessage = "'\(activeTagName)' ist bereits aktiv. Scanne '\(activeTagName)' zuerst, um ihn zu deaktivieren."
                    showingErrorAlert = true
                    
                    // Error haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    
                case .blockedByTimeProfile(let profileName, _):
                    errorMessage = "Zeitprofil '\(profileName)' ist gerade aktiv. Tags können nicht aktiviert werden, während ein Zeitprofil aktiv ist."
                    showingErrorAlert = true
                    
                    // Error haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    
                case .failed:
                    errorMessage = "Die Blockierung konnte nicht aktiviert/deaktiviert werden. Bitte versuche es erneut."
                    showingErrorAlert = true
                    
                    // Error haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func requestAuthorization() {
        Task {
            do {
                try await screenTimeController.requestAuthorization()
                await appState.checkAuthorizationStatus()
            } catch {
                showingAuthorizationAlert = true
            }
        }
    }
}

// MARK: - Status Card View

struct StatusCardView: View {
    let isBlocking: Bool
    
    var body: some View {
        HStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Status")
                    .font(.system(size: FontSize.base))
                    .foregroundColor(PauseColors.tertiaryText)
                
                Text(isBlocking ? "Blockiert" : "Entsperrt")
                    .font(.system(size: FontSize.xl, weight: .bold))
                    .foregroundColor(isBlocking ? PauseColors.error : PauseColors.success)
            }
            
            Spacer()
            
            Image(systemName: isBlocking ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 32))
                .foregroundColor(isBlocking ? PauseColors.error : PauseColors.success)
                .padding(Spacing.md)
                .background(
                    Circle()
                        .fill(isBlocking ? PauseColors.error.opacity(0.1) : PauseColors.success.opacity(0.1))
                )
        }
        .padding(Spacing.lg)
        .card()
    }
}

// MARK: - Tag Card

struct TagCard: View {
    let tag: NFCTag
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: TagDetailView(tag: tag)) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: FontSize.lg))
                        .foregroundColor(tag.isActive ? PauseColors.success : PauseColors.dimGray)
                    
                    Spacer()
                    
                    if tag.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: FontSize.base))
                            .foregroundColor(PauseColors.success)
                    }
                }
                
                Text(tag.name)
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
                    .lineLimit(1)
                
                Text("\(tag.linkedAppTokens.count) Apps")
                    .font(.system(size: FontSize.sm))
                    .foregroundColor(PauseColors.secondaryText)
            }
            .padding(Spacing.md)
            .frame(width: 140, height: 100)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(tag.isActive ? PauseColors.tagActive : PauseColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(tag.isActive ? PauseColors.success.opacity(0.3) : PauseColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    HomeView()
}