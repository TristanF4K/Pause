//
//  AddTagView.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import SwiftUI

struct AddTagView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var nfcController = NFCController.shared
    
    @State private var tagName = ""
    @State private var scannedIdentifier: String?
    @State private var isScanning = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                PauseColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Tag Name Card
                        tagNameCard
                        
                        // NFC Scan Card
                        nfcScanCard
                        
                        // NFC Availability Warning
                        if !nfcController.isNFCAvailable {
                            nfcUnavailableCard
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Tag hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(PauseColors.accent)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Weiter") {
                        saveTag()
                    }
                    .disabled(!canSave)
                    .foregroundColor(canSave ? PauseColors.accent : PauseColors.dimGray)
                }
            }
            .alert("Fehler", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Subviews
    
    private var tagNameCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "textformat")
                    .font(.system(size: FontSize.lg))
                    .foregroundColor(PauseColors.accent)
                Text("Tag-Name")
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
            }
            
            TextField("z.B. Schreibtisch, Schlafzimmer", text: $tagName)
                .textFieldStyle(CustomTextFieldStyle())
                .font(.system(size: FontSize.base))
            
            Text("Gib deinem Tag einen aussagekräftigen Namen")
                .font(.system(size: FontSize.sm))
                .foregroundColor(PauseColors.tertiaryText)
        }
        .padding(Spacing.lg)
        .card()
    }
    
    private var nfcScanCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "wave.3.right")
                    .font(.system(size: FontSize.lg))
                    .foregroundColor(PauseColors.accent)
                Text("NFC Tag scannen")
                    .font(.system(size: FontSize.md, weight: .semibold))
                    .foregroundColor(PauseColors.primaryText)
                Spacer()
            }
            .padding(Spacing.lg)
            
            Divider()
                .background(PauseColors.cardBorder)
            
            // Content
            VStack(spacing: Spacing.md) {
                if let identifier = scannedIdentifier {
                    // Success State
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: FontSize.xl))
                            .foregroundColor(PauseColors.success)
                        
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Tag erfolgreich gescannt")
                                .font(.system(size: FontSize.base, weight: .medium))
                                .foregroundColor(PauseColors.primaryText)
                            Text(formatTagID(identifier))
                                .font(.system(size: FontSize.sm, design: .monospaced))
                                .foregroundColor(PauseColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Button(action: { 
                            scannedIdentifier = nil 
                        }) {
                            Text("Erneut scannen")
                                .font(.system(size: FontSize.sm, weight: .medium))
                                .foregroundColor(PauseColors.accent)
                        }
                    }
                    .padding(Spacing.lg)
                    .background(PauseColors.success.opacity(0.1))
                    .cornerRadius(CornerRadius.md)
                } else {
                    // Scan Button
                    Button(action: startScanning) {
                        HStack(spacing: Spacing.sm) {
                            if isScanning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: PauseColors.jet))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "wave.3.right")
                                    .font(.system(size: FontSize.lg))
                            }
                            Text(isScanning ? "Scannen..." : "Tag scannen")
                                .font(.system(size: FontSize.md, weight: .semibold))
                        }
                    }
                    .primaryButton()
                    .disabled(isScanning)
                    
                    Text("Halte dein iPhone an den NFC-Tag")
                        .font(.system(size: FontSize.sm))
                        .foregroundColor(PauseColors.tertiaryText)
                }
            }
            .padding(Spacing.lg)
        }
        .card()
    }
    
    private var nfcUnavailableCard: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: FontSize.lg))
                .foregroundColor(PauseColors.warning)
            
            Text("NFC wird auf diesem Gerät nicht unterstützt")
                .font(.system(size: FontSize.base))
                .foregroundColor(PauseColors.primaryText)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PauseColors.warning.opacity(0.1))
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(PauseColors.warning.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private var canSave: Bool {
        !tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && scannedIdentifier != nil
    }
    
    private func formatTagID(_ id: String) -> String {
        if id.count > 12 {
            return String(id.prefix(12)) + "..."
        }
        return id
    }
    
    private func startScanning() {
        isScanning = true
        nfcController.startScanning { result in
            isScanning = false
            switch result {
            case .success(let identifier):
                scannedIdentifier = identifier
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func saveTag() {
        guard let identifier = scannedIdentifier else { return }
        
        _ = TagController.shared.registerTag(
            name: tagName.trimmingCharacters(in: .whitespacesAndNewlines),
            identifier: identifier
        )
        
        dismiss()
    }
}

// MARK: - Custom TextField Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Spacing.md)
            .background(PauseColors.tertiaryBackground)
            .cornerRadius(CornerRadius.sm)
            .foregroundColor(PauseColors.primaryText)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(PauseColors.cardBorder, lineWidth: 1)
            )
    }
}

#Preview {
    AddTagView()
}