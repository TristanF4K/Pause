//
//  ScanView.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var nfcController = NFCController.shared
    @StateObject private var appState = AppState.shared
    
    @State private var isScanning = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var scannedTag: NFCTag?
    @State private var wasActivated = false // Track what action was performed
    @State private var hasStartedInitialScan = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // NFC Animation
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    if isScanning {
                        Circle()
                            .stroke(lineWidth: 2)
                            .fill(Color.blue)
                            .frame(width: 200, height: 200)
                            .scaleEffect(isScanning ? 1.2 : 0.8)
                            .opacity(isScanning ? 0 : 1)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isScanning)
                    }
                    
                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                }
                
                VStack(spacing: 8) {
                    Text("Scannen...")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Halte dein iPhone an den NFC Tag")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Tag scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        nfcController.stopScanning()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Start scanning immediately when view appears
                if !hasStartedInitialScan {
                    hasStartedInitialScan = true
                    startScanning()
                }
            }
            .onDisappear {
                // Clean up when view disappears
                nfcController.stopScanning()
            }
            .alert("Erfolg!", isPresented: $showingSuccess, presenting: scannedTag) { tag in
                Button("OK") {
                    dismiss()
                }
            } message: { tag in
                Text("'\(tag.name)' wurde \(wasActivated ? "aktiviert" : "deaktiviert")")
            }
            .alert("Fehler", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startScanning() {
        isScanning = true
        nfcController.startScanning { result in
            isScanning = false
            
            switch result {
            case .success(let identifier):
                handleScannedIdentifier(identifier)
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func handleScannedIdentifier(_ identifier: String) {
        // Get the scan result from TagController
        Task {
            let scanResult = await TagController.shared.handleTagScan(identifier: identifier)
            
            await MainActor.run {
                switch scanResult {
                case .success(let tag, let activated):
                    scannedTag = tag
                    self.wasActivated = activated
                    showingSuccess = true
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                case .notRegistered:
                    errorMessage = "Dieser Tag ist nicht registriert. Bitte füge ihn zuerst in den Einstellungen hinzu."
                    showingError = true
                    
                case .noAppsLinked(let tagName):
                    errorMessage = "Der Tag '\(tagName)' hat keine Apps verknüpft. Bitte wähle zuerst Apps aus."
                    showingError = true
                    
                case .blockedByOtherTag(let activeTagName, _):
                    errorMessage = "'\(activeTagName)' ist bereits aktiv. Scanne '\(activeTagName)' zuerst, um ihn zu deaktivieren."
                    showingError = true
                    
                    // Error haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    
                case .blockedByTimeProfile(let profileName, _):
                    errorMessage = "Zeitprofil '\(profileName)' ist gerade aktiv. Tags können nicht aktiviert werden, während ein Zeitprofil aktiv ist."
                    showingError = true
                    
                    // Error haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    
                case .failed:
                    errorMessage = "Die Blockierung konnte nicht aktiviert/deaktiviert werden. Bitte versuche es erneut."
                    showingError = true
                    
                    // Error haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

#Preview {
    ScanView()
}
