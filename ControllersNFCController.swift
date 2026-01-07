//
//  NFCController.swift
//  FocusLock
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif
import Combine

#if canImport(CoreNFC)
enum NFCError: Error, LocalizedError {
    case notSupported
    case sessionInvalidated
    case readFailed
    case writeFailed
    case noMessagesFound
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "NFC wird auf diesem Gerät nicht unterstützt"
        case .sessionInvalidated:
            return "NFC Session wurde beendet"
        case .readFailed:
            return "NFC Tag konnte nicht gelesen werden"
        case .writeFailed:
            return "NFC Tag konnte nicht beschrieben werden"
        case .noMessagesFound:
            return "Keine Daten auf dem Tag gefunden"
        case .userCancelled:
            return "Scan wurde abgebrochen"
        }
    }
}

@MainActor
final class NFCController: NSObject, ObservableObject {
    static let shared = NFCController()
    
    @Published var isScanning = false
    @Published var lastScannedIdentifier: String?
    @Published var errorMessage: String?
    
    private var tagSession: NFCTagReaderSession?
    private var scanCompletion: ((Result<String, NFCError>) -> Void)?
    
    private override init() {
        super.init()
    }
    
    var isNFCAvailable: Bool {
        NFCTagReaderSession.readingAvailable
    }
    
    // Normalize identifier to lowercase hex string
    private func normalizeIdentifier(_ identifier: String) -> String {
        let normalized = identifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ":", with: "")
        
        print("   🔄 Normalisiere ID: '\(identifier)' -> '\(normalized)'")
        return normalized
    }
    
    func startScanning(completion: @escaping (Result<String, NFCError>) -> Void) {
        guard isNFCAvailable else {
            completion(.failure(.notSupported))
            return
        }
        
        // Clean up any existing session
        stopScanning()
        
        scanCompletion = completion
        
        // Use NFCTagReaderSession with iso14443 for MiFare tags (your NFC 215 chips)
        tagSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
        tagSession?.alertMessage = "Halte dein iPhone an den NFC Tag"
        tagSession?.begin()
        isScanning = true
        
        print("🚀 NFC Tag Session gestartet (Hardware-ID Modus)")
    }
    
    func stopScanning() {
        tagSession?.invalidate()
        tagSession = nil
        isScanning = false
        scanCompletion = nil
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension NFCController: NFCTagReaderSessionDelegate {
    
    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("📡 NFC Tag Reader Session aktiv")
    }
    
    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.handleSessionInvalidation(error: error)
        }
    }
    
    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [CoreNFC.NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "Kein Tag gefunden")
            return
        }
        
        print("🔍 Tag erkannt: \(tag)")
        
        // Connect to tag
        session.connect(to: tag) { error in
            if let error = error {
                print("❌ Verbindungsfehler: \(error)")
                session.invalidate(errorMessage: "Verbindung fehlgeschlagen")
                Task { @MainActor [weak self] in
                    self?.handleScanFailure(.readFailed)
                }
                return
            }
            
            // Extract hardware identifier based on tag type
            var hardwareIdentifier: String?
            
            switch tag {
            case .miFare(let miFareTag):
                let idData = miFareTag.identifier
                hardwareIdentifier = idData.map { String(format: "%02x", $0) }.joined()
                print("✅ MiFare Tag erkannt!")
                print("   Hardware-ID Bytes: \(idData.map { String(format: "%02x", $0) })")
                print("   Hardware-ID String: \(hardwareIdentifier ?? "nil")")
                print("   Byte-Länge: \(idData.count)")
                print("   String-Länge: \(hardwareIdentifier?.count ?? 0)")
                
            case .iso7816(let iso7816Tag):
                let idData = iso7816Tag.identifier
                hardwareIdentifier = idData.map { String(format: "%02x", $0) }.joined()
                print("✅ ISO7816 Tag erkannt!")
                print("   Hardware-ID: \(hardwareIdentifier ?? "nil")")
                
            case .feliCa(let feliCaTag):
                let idData = feliCaTag.currentIDm
                hardwareIdentifier = idData.map { String(format: "%02x", $0) }.joined()
                print("✅ FeliCa Tag erkannt!")
                print("   Hardware-ID: \(hardwareIdentifier ?? "nil")")
                
            case .iso15693(let iso15693Tag):
                let idData = iso15693Tag.identifier
                hardwareIdentifier = idData.map { String(format: "%02x", $0) }.joined()
                print("✅ ISO15693 Tag erkannt!")
                print("   Hardware-ID: \(hardwareIdentifier ?? "nil")")
                
            @unknown default:
                print("⚠️ Unbekannter Tag-Typ: \(tag)")
            }
            
            // Use hardware ID if available
            if let hwId = hardwareIdentifier, !hwId.isEmpty {
                print("🎉 Hardware-ID erfolgreich extrahiert: \(hwId)")
                session.alertMessage = "Tag erfolgreich gelesen! ✓"
                session.invalidate()
                
                Task { @MainActor [weak self] in
                    self?.handleScanSuccess(identifier: hwId)
                }
            } else {
                print("❌ Keine Hardware-ID verfügbar")
                session.invalidate(errorMessage: "Tag-ID konnte nicht gelesen werden")
                Task { @MainActor [weak self] in
                    self?.handleScanFailure(.readFailed)
                }
            }
        }
    }
}

// MARK: - Private MainActor Methods
@MainActor
private extension NFCController {
    
    func handleSessionInvalidation(error: Error) {
        self.isScanning = false
        self.tagSession = nil
        
        // Only report non-cancellation errors
        if let nfcError = error as? NFCReaderError {
            switch nfcError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                print("ℹ️ Scan vom Benutzer abgebrochen")
                self.scanCompletion?(.failure(.userCancelled))
            case .readerSessionInvalidationErrorSessionTimeout:
                print("⏱️ Session Timeout")
                self.errorMessage = "Session-Timeout. Bitte erneut versuchen."
                self.scanCompletion?(.failure(.sessionInvalidated))
            case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
                print("⚠️ Session unerwartet beendet")
                self.errorMessage = "Session wurde unerwartet beendet."
                self.scanCompletion?(.failure(.sessionInvalidated))
            default:
                print("❌ NFC Fehler: \(nfcError.localizedDescription)")
                self.errorMessage = nfcError.localizedDescription
                self.scanCompletion?(.failure(.sessionInvalidated))
            }
        }
        
        self.scanCompletion = nil
    }
    
    func handleScanSuccess(identifier: String) {
        // Normalize identifier before using it
        let normalizedId = normalizeIdentifier(identifier)
        
        // Debug logging
        print("🔍 NFC Scan erfolgreich!")
        print("   📇 Original Identifier: \(identifier)")
        print("   📇 Normalisierter Identifier: \(normalizedId)")
        print("   📏 Länge: \(normalizedId.count)")
        
        self.lastScannedIdentifier = normalizedId
        self.scanCompletion?(.success(normalizedId))
        self.isScanning = false
        self.tagSession = nil
        self.scanCompletion = nil
    }
    
    func handleScanFailure(_ error: NFCError) {
        print("❌ Scan fehlgeschlagen: \(error.localizedDescription)")
        self.scanCompletion?(.failure(error))
        self.scanCompletion = nil
    }
}

#else
// Placeholder for non-NFC capable devices (like simulator)
@MainActor
final class NFCController: NSObject, ObservableObject {
    static let shared = NFCController()
    
    @Published var isScanning = false
    @Published var lastScannedIdentifier: String?
    @Published var errorMessage: String?
    
    var isNFCAvailable: Bool { false }
    
    func startScanning(completion: @escaping (Result<String, NFCError>) -> Void) {
        completion(.failure(.notSupported))
    }
    
    func stopScanning() {
        isScanning = false
    }
}

enum NFCError: Error, LocalizedError {
    case notSupported
    case sessionInvalidated
    case readFailed
    case writeFailed
    case noMessagesFound
    case userCancelled
    
    var errorDescription: String? {
        return "NFC wird auf diesem Gerät nicht unterstützt"
    }
}
#endif
