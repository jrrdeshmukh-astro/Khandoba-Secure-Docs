//
//  RedactionView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData
import CoreLocation
import PDFKit
import Combine
import UIKit

struct RedactionView: View {
    let document: Document
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var redactionAreas: [CGRect] = []
    @State private var showSaveConfirm = false
    @State private var autoDetectedPHI: [PHIMatch] = []
    @StateObject private var locationService = LocationService()
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // HIPAA Warning
            StandardCard {
                HStack(spacing: UnifiedTheme.Spacing.sm) {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(colors.warning)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HIPAA Redaction")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        Text("Redactions are permanent and cannot be undone")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                }
            }
            .padding()
            
            // Document Preview with Redaction Overlay
            ZStack {
                colors.background
                
                if document.documentType == "pdf" || document.documentType == "image" {
                    // Document preview with redaction capability
                    DocumentPreviewView(document: document)
                        .overlay(
                            VStack(spacing: UnifiedTheme.Spacing.sm) {
                                Spacer()
                                Text("Tap and drag to mark areas for redaction")
                                    .font(theme.typography.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(8)
                                    .padding()
                            }
                        )
                    
                    // Redaction overlays
                    ForEach(Array(redactionAreas.enumerated()), id: \.offset) { index, rect in
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Auto-detected PHI
            if !autoDetectedPHI.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: UnifiedTheme.Spacing.sm) {
                        ForEach(autoDetectedPHI) { phi in
                            PHIChip(phi: phi) {
                                // Add to redaction areas when tapped
                                // TODO: Implement area selection from PHI match
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 60)
                .background(colors.surface)
            }
            
            // Actions
            HStack(spacing: UnifiedTheme.Spacing.md) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button {
                    showSaveConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Apply Redactions")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(redactionAreas.isEmpty && autoDetectedPHI.isEmpty)
            }
            .padding()
            .background(colors.surface)
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Apply Redactions", isPresented: $showSaveConfirm) {
            Button("Apply (Permanent)", role: .destructive) {
                applyRedactions()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action is permanent and cannot be undone. The redacted information will be permanently removed from the document.")
        }
        .task {
            await detectPHI()
        }
    }
    
    private func detectPHI() async {
        guard let text = document.extractedText else { return }
        
        // Auto-detect PHI patterns
        var detected: [PHIMatch] = []
        
        // SSN pattern (XXX-XX-XXXX)
        let ssnPattern = #"\b\d{3}-\d{2}-\d{4}\b"#
        if let regex = try? NSRegularExpression(pattern: ssnPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    detected.append(PHIMatch(type: "SSN", value: String(text[range]), range: match.range))
                }
            }
        }
        
        // Date of Birth patterns
        let dobPattern = #"\b\d{1,2}/\d{1,2}/\d{2,4}\b"#
        if let regex = try? NSRegularExpression(pattern: dobPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    detected.append(PHIMatch(type: "DOB", value: String(text[range]), range: match.range))
                }
            }
        }
        
        // Medical Record Numbers (MRN)
        let mrnPattern = #"\bMRN[:\s-]?\d{6,10}\b"#
        if let regex = try? NSRegularExpression(pattern: mrnPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    detected.append(PHIMatch(type: "MRN", value: String(text[range]), range: match.range))
                }
            }
        }
        
        autoDetectedPHI = detected
    }
    
    private func applyRedactions() {
        Task {
            do {
                guard let originalData = document.encryptedFileData else {
                    print(" No document data to redact")
                    return
                }
                
                // Create version before redaction
                let version = DocumentVersion(
                    versionNumber: (document.versions ?? []).count + 1,
                    fileSize: document.fileSize,
                    changes: "Pre-redaction version"
                )
                version.encryptedFileData = originalData
                version.document = document
                
                modelContext.insert(version)
                
                // Actually redact the content
                let redactedData: Data
                
                if document.documentType == "pdf" {
                    redactedData = try RedactionService.redactPDF(
                        data: originalData,
                        redactionAreas: redactionAreas,
                        phiMatches: autoDetectedPHI
                    )
                } else if document.documentType == "image" {
                    guard let image = UIImage(data: originalData) else {
                        print(" Invalid image data")
                        return
                    }
                    
                    let redactedImage = RedactionService.redactImage(
                        image: image,
                        redactionAreas: redactionAreas,
                        phiMatches: autoDetectedPHI
                    )
                    
                    guard let imageData = redactedImage.pngData() else {
                        print(" Failed to convert redacted image to data")
                        return
                    }
                    
                    redactedData = imageData
                } else {
                    print(" Redaction not supported for document type: \(document.documentType)")
                    return
                }
                
                // Verify redaction
                let verified = await RedactionService.verifyRedaction(
                    data: redactedData,
                    documentType: document.documentType
                )
                
                if !verified {
                    print(" Redaction verification failed - PHI may still be present")
                }
                
                // Update document with redacted data
                document.encryptedFileData = redactedData
                document.fileSize = Int64(redactedData.count)
                document.isRedacted = true
                document.lastModifiedAt = Date()
                
                // Mark document as redacted
                document.name = document.name.contains("(Redacted)") ? 
                    document.name : 
                    document.name + " (Redacted)"
                
                // Clear extracted text (may contain PHI)
                document.extractedText = nil
                
                // Log redaction event
                if let vault = document.vault {
                    await locationService.requestLocationPermission()
                    let location = await locationService.getCurrentLocation()
                    
                    let accessLog = VaultAccessLog(
                        accessType: "redacted",
                        userID: authService.currentUser?.id,
                        userName: authService.currentUser?.fullName
                    )
                    accessLog.vault = vault
                    accessLog.documentID = document.id
                    accessLog.documentName = document.name
                    accessLog.deviceInfo = "Redacted \(redactionAreas.count) areas, \(autoDetectedPHI.count) PHI matches"
                    
                    if let location = location {
                        accessLog.locationLatitude = location.coordinate.latitude
                        accessLog.locationLongitude = location.coordinate.longitude
                    }
                    
                    modelContext.insert(accessLog)
                }
                
                try modelContext.save()
                
                print(" Redactions applied: \(redactionAreas.count) areas, \(autoDetectedPHI.count) PHI matches")
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                print(" Redaction failed: \(error.localizedDescription)")
            }
        }
    }
}

// PHIMatch moved to RedactionService.swift

struct PHIChip: View {
    let phi: PHIMatch
    let onSelect: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: onSelect) {
            VStack(spacing: 2) {
                Text(phi.type)
                    .font(.caption2)
                    .fontWeight(.semibold)
                Text(phi.value)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(colors.error)
            .cornerRadius(UnifiedTheme.CornerRadius.md)
        }
    }
}
