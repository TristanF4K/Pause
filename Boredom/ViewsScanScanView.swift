//
//  ScanView.swift
//  FocusLock
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
                    Text(isScanning ? "Scannen..." : "Bereit zum Scannen")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(isScanning ? "Halte dein iPhone an den NFC Tag" : "Tippe auf 'Scannen', um zu starten")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Scan Button
                if !isScanning {
                    Button(action: startScanning) {
                        Text("Scannen")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Tag scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        nfcController.stopScanning()
                        dismiss()
                    }
                }
            }
            .alert("Erfolg!", isPresented: $showingSuccess, presenting: scannedTag) { tag in
                Button("OK") {
                    dismiss()
                }
            } message: { tag in
                Text("'\(tag.name)' wurde \(tag.isActive ? "aktiviert" : "deaktiviert")")
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
        // Check if tag is registered
        if let tag = appState.registeredTags.first(where: { $0.tagIdentifier == identifier }) {
            // Handle registered tag
            TagController.shared.handleTagScan(identifier: identifier)
            
            // Get updated tag
            if let updatedTag = appState.registeredTags.first(where: { $0.id == tag.id }) {
                scannedTag = updatedTag
                showingSuccess = true
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } else {
            // Tag not registered
            errorMessage = "Dieser Tag ist nicht registriert. Bitte füge ihn zuerst in den Einstellungen hinzu."
            showingError = true
        }
    }
}

#Preview {
    ScanView()
}
