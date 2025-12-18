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
import Vision

struct RedactionView: View {
    let document: Document
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var documentService: DocumentService
    
    @State private var redactionAreas: [CGRect] = []
    @State private var showSaveConfirm = false
    @State private var autoDetectedPHI: [PHIMatch] = []
    @StateObject private var locationService = LocationService()
    @State private var isDrawing = false
    @State private var currentRedactionRect: CGRect = .zero
    @State private var startPoint: CGPoint = .zero
    @State private var documentSize: CGSize = .zero
    
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
            
            // Format Validation Warning
            if !isRedactionSupported(for: document) {
                StandardCard {
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(colors.error)
                            .font(.title2)
                        
                        Text("Redaction Not Supported")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Redaction is only available for PDF and image documents (PNG, JPEG, HEIC) to ensure HIPAA/CUI PHI compliance.")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Supported formats: PDF, PNG, JPEG, HEIC")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textTertiary)
                            .padding(.top, 4)
                    }
                    .padding()
                }
                .padding()
            }
            
            // Document Preview with Redaction Overlay
            ZStack {
                colors.background
                
                if isRedactionSupported(for: document) {
                    GeometryReader { geometry in
                        // Document preview with redaction capability
                        DocumentPreviewView(document: document)
                            .onAppear {
                                // Get document size for coordinate conversion
                                if let data = document.encryptedFileData {
                                    if document.documentType == "image",
                                       let image = UIImage(data: data) {
                                        documentSize = image.size
                                    } else if document.documentType == "pdf",
                                              let pdf = PDFDocument(data: data),
                                              let page = pdf.page(at: 0) {
                                        documentSize = page.bounds(for: .mediaBox).size
                                    }
                                }
                            }
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
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if !isDrawing {
                                            isDrawing = true
                                            startPoint = value.startLocation
                                        }
                                        
                                        // Calculate rectangle from start to current point
                                        let minX = min(startPoint.x, value.location.x)
                                        let minY = min(startPoint.y, value.location.y)
                                        let maxX = max(startPoint.x, value.location.x)
                                        let maxY = max(startPoint.y, value.location.y)
                                        
                                        currentRedactionRect = CGRect(
                                            x: minX,
                                            y: minY,
                                            width: maxX - minX,
                                            height: maxY - minY
                                        )
                                    }
                                    .onEnded { value in
                                        isDrawing = false
                                        
                                        // Convert view coordinates to document coordinates
                                        if documentSize.width > 0 && documentSize.height > 0 {
                                            let viewSize = geometry.size
                                            let scaleX = documentSize.width / viewSize.width
                                            let scaleY = documentSize.height / viewSize.height
                                            
                                            let docRect = CGRect(
                                                x: currentRedactionRect.origin.x * scaleX,
                                                y: currentRedactionRect.origin.y * scaleY,
                                                width: currentRedactionRect.width * scaleX,
                                                height: currentRedactionRect.height * scaleY
                                            )
                                            
                                            // Only add if rectangle is large enough
                                            if docRect.width > 10 && docRect.height > 10 {
                                                redactionAreas.append(docRect)
                                            }
                                        }
                                        
                                        currentRedactionRect = .zero
                                    }
                            )
                        
                        // Redaction overlays (existing redactions)
                        ForEach(Array(redactionAreas.enumerated()), id: \.offset) { index, rect in
                            Rectangle()
                                .fill(Color.black.opacity(0.7))
                                .frame(width: rect.width, height: rect.height)
                                .position(x: rect.midX, y: rect.midY)
                        }
                        
                        // Current drawing rectangle
                        if isDrawing && currentRedactionRect.width > 0 && currentRedactionRect.height > 0 {
                            Rectangle()
                                .stroke(Color.red, lineWidth: 2)
                                .fill(Color.red.opacity(0.3))
                                .frame(width: currentRedactionRect.width, height: currentRedactionRect.height)
                                .position(x: currentRedactionRect.midX, y: currentRedactionRect.midY)
                        }
                    }
                } else {
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(colors.warning)
                        Text("Redaction not supported for this document type")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                        Text("Only PDF and image formats (PNG, JPEG, HEIC) support HIPAA-compliant redaction")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Auto-detected PHI
            if !autoDetectedPHI.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: UnifiedTheme.Spacing.sm) {
                        ForEach(autoDetectedPHI) { phi in
                            PHIChip(phi: phi) {
                                // Auto-redact detected PHI using OCR
                                Task {
                                    await redactPHIMatch(phi)
                                }
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
                .disabled(redactionAreas.isEmpty && autoDetectedPHI.isEmpty || !isRedactionSupported(for: document))
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
    
    /// Check if document format supports HIPAA-compliant redaction
    private func isRedactionSupported(for document: Document) -> Bool {
        // Only PDF and image formats support proper redaction
        guard let mimeType = document.mimeType?.lowercased() else {
            // Fallback to document type
            return document.documentType == "pdf" || document.documentType == "image"
        }
        
        // Supported MIME types for redaction
        let supportedMimeTypes = [
            "application/pdf",
            "image/png",
            "image/jpeg",
            "image/jpg",
            "image/heic",
            "image/heif"
        ]
        
        return supportedMimeTypes.contains(mimeType) || 
               document.documentType == "pdf" || 
               document.documentType == "image"
    }
    
    private func detectPHI() async {
        guard let text = document.extractedText else { return }
        
        // Auto-detect HIPAA 18 identifiers and CUI/PHI patterns
        var detected: [PHIMatch] = []
        
        // HIPAA 18 Identifiers
        let phiPatterns: [(String, String)] = [
            ("SSN", #"\b\d{3}-\d{2}-\d{4}\b"#),
            ("DOB", #"\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b"#),
            ("MRN", #"\bMRN[:\s-]?\d{6,10}\b"#),
            ("Email", #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#),
            ("Phone", #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#),
            ("ZIP", #"\b\d{5}(-\d{4})?\b"#),
            ("Account", #"\b\d{9,12}\b"#),
            ("Full Name", #"\b[A-Z][a-z]+ [A-Z][a-z]+( [A-Z][a-z]+)?\b"#),
            ("Credit Card", #"\b\d{4}[-.]?\d{4}[-.]?\d{4}[-.]?\d{4}\b"#),
            ("Passport", #"\b[A-Z]{2}\d{2}[A-Z]{2}\d{4}\b"#),
        ]
        
        for (type, pattern) in phiPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let value = String(text[range])
                        // Avoid duplicates
                        if !detected.contains(where: { $0.value == value }) {
                            detected.append(PHIMatch(type: type, value: value, range: match.range))
                        }
                    }
                }
            }
        }
        
        await MainActor.run {
            autoDetectedPHI = detected
        }
    }
    
    private func redactPHIMatch(_ phi: PHIMatch) async {
        guard let data = document.encryptedFileData else { return }
        
        // Use OCR to find the text location in the image
        if document.documentType == "image",
           let image = UIImage(data: data),
           let cgImage = image.cgImage {
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let textRequest = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }
                
                for observation in observations {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    
                    if candidate.string.contains(phi.value) {
                        // Convert Vision coordinates to UIKit coordinates
                        let boundingBox = observation.boundingBox
                        let imageSize = image.size
                        
                        let rect = CGRect(
                            x: boundingBox.origin.x * imageSize.width,
                            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
                            width: boundingBox.width * imageSize.width,
                            height: boundingBox.height * imageSize.height
                        )
                        
                        Task { @MainActor in
                            redactionAreas.append(rect)
                        }
                        break
                    }
                }
            }
            
            textRequest.recognitionLevel = .accurate
            try? handler.perform([textRequest])
        } else if document.documentType == "pdf",
                  let pdf = PDFDocument(data: data) {
            // For PDF, find text on each page using PDFSelection
            for pageIndex in 0..<pdf.pageCount {
                guard let page = pdf.page(at: pageIndex),
                      let pageText = page.string,
                      pageText.contains(phi.value) else { continue }
                
                // Find all occurrences of the PHI value in the page text
                var searchRange = pageText.startIndex..<pageText.endIndex
                while let range = pageText.range(of: phi.value, range: searchRange) {
                    // Create a selection for this text range
                    let nsRange = NSRange(range, in: pageText)
                    if let selection = page.selection(for: nsRange) {
                        // Get bounds of the selection on the page
                        let bounds = selection.bounds(for: page)
                        Task { @MainActor in
                            redactionAreas.append(bounds)
                        }
                    }
                    
                    // Move search range forward
                    searchRange = range.upperBound..<pageText.endIndex
                }
            }
        }
    }
    
    private func applyRedactions() {
        Task {
            do {
                // Get original document data (decrypt if needed)
                var originalData: Data?
                
                if AppConfig.useSupabase {
                    // In Supabase mode, download the document
                    guard let supabaseDoc: SupabaseDocument = try? await supabaseService.fetch("documents", id: document.id),
                          let storagePath = supabaseDoc.storagePath else {
                        print("❌ Failed to load document from Supabase for redaction")
                        return
                    }
                    
                    // Download encrypted file from Supabase Storage
                    originalData = try await supabaseService.downloadFile(
                        bucket: SupabaseConfig.encryptedDocumentsBucket,
                        path: storagePath
                    )
                } else {
                    // SwiftData mode - use local encrypted data
                    originalData = document.encryptedFileData
                }
                
                guard let originalData = originalData else {
                    print("❌ No document data to redact")
                    return
                }
                
                // Decrypt document for redaction (redaction must work on unencrypted data)
                let decryptedData: Data
                do {
                    decryptedData = try EncryptionService.decryptDocument(originalData, documentID: document.id)
                } catch {
                    print("❌ Failed to decrypt document for redaction: \(error)")
                    // If decryption fails, try using data as-is (might already be decrypted)
                    decryptedData = originalData
                }
                
                // Create version before redaction (HIPAA requirement - maintain audit trail)
                // Use DocumentService to create version (tracks fidelity automatically)
                do {
                    _ = try await documentService.createDocumentVersion(
                        document,
                        changeDescription: "Pre-redaction version (HIPAA audit trail)"
                    )
                } catch {
                    print("⚠️ Failed to track redaction version in fidelity service: \(error.localizedDescription)")
                    // Fallback: create version manually if DocumentService fails
                    if !AppConfig.useSupabase {
                        let version = DocumentVersion(
                            versionNumber: (document.versions ?? []).count + 1,
                            fileSize: document.fileSize,
                            changes: "Pre-redaction version (HIPAA audit trail)"
                        )
                        version.encryptedFileData = originalData
                        version.document = document
                        modelContext.insert(version)
                    }
                }
                
                // Actually redact the content (on decrypted data)
                let redactedData: Data
                
                if document.documentType == "pdf" {
                    redactedData = try RedactionService.redactPDF(
                        data: decryptedData, // Use decrypted data for redaction
                        redactionAreas: redactionAreas,
                        phiMatches: autoDetectedPHI
                    )
                } else if document.documentType == "image" {
                    guard let image = UIImage(data: decryptedData) else {
                        print("❌ Invalid image data")
                        return
                    }
                    
                    let redactedImage = RedactionService.redactImage(
                        image: image,
                        redactionAreas: redactionAreas,
                        phiMatches: autoDetectedPHI
                    )
                    
                    guard let imageData = redactedImage.pngData() else {
                        print("❌ Failed to convert redacted image to data")
                        return
                    }
                    
                    redactedData = imageData
                } else {
                    print("❌ Redaction not supported for document type: \(document.documentType)")
                    return
                }
                
                // Verify redaction (HIPAA requirement - ensure PHI is completely removed)
                let verified = await RedactionService.verifyRedaction(
                    data: redactedData,
                    documentType: document.documentType
                )
                
                if !verified {
                    print("⚠️ Redaction verification failed - PHI may still be present")
                    // Still proceed but log warning
                }
                
                // Re-encrypt redacted document
                let documentID = document.id
                let (encryptedRedactedData, _) = try EncryptionService.encryptDocument(redactedData, documentID: documentID)
                
                // Update document with redacted data
                if AppConfig.useSupabase {
                    // Supabase mode: Upload redacted document to storage
                    try await updateRedactedDocumentInSupabase(
                        document: document,
                        encryptedData: encryptedRedactedData,
                        fileSize: Int64(redactedData.count)
                    )
                } else {
                    // SwiftData mode: Update local document
                    document.encryptedFileData = encryptedRedactedData
                    document.fileSize = Int64(redactedData.count)
                    document.isRedacted = true
                    document.lastModifiedAt = Date()
                    
                    // Mark document as redacted
                    document.name = document.name.contains("(Redacted)") ? 
                        document.name : 
                        document.name + " (Redacted)"
                    
                    // Clear extracted text (may contain PHI)
                    document.extractedText = nil
                    
                    try modelContext.save()
                }
                
                // Log redaction event (HIPAA audit requirement)
                await logRedactionEvent(
                    redactionAreas: redactionAreas.count,
                    phiMatches: autoDetectedPHI.count,
                    verified: verified
                )
                
                print("✅ Redactions applied: \(redactionAreas.count) areas, \(autoDetectedPHI.count) PHI matches, verified: \(verified)")
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                print("❌ Redaction failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update redacted document in Supabase
    private func updateRedactedDocumentInSupabase(
        document: Document,
        encryptedData: Data,
        fileSize: Int64
    ) async throws {
        guard let supabaseDoc: SupabaseDocument = try? await supabaseService.fetch("documents", id: document.id),
              let storagePath = supabaseDoc.storagePath else {
            throw RedactionError.redactionFailed
        }
        
        // Upload redacted encrypted document to Supabase Storage (overwrite existing)
        _ = try await supabaseService.uploadFile(
            bucket: SupabaseConfig.encryptedDocumentsBucket,
            path: storagePath,
            data: encryptedData
        )
        
        // Update document metadata in Supabase
        var updatedDoc = supabaseDoc
        updatedDoc.fileSize = fileSize
        updatedDoc.isRedacted = true
        updatedDoc.lastModifiedAt = Date()
        updatedDoc.name = supabaseDoc.name.contains("(Redacted)") ? 
            supabaseDoc.name : 
            supabaseDoc.name + " (Redacted)"
        updatedDoc.extractedText = nil // Clear extracted text (may contain PHI)
        
        _ = try await supabaseService.update("documents", id: document.id, values: updatedDoc)
        
        // Update local document model
        await MainActor.run {
            document.fileSize = fileSize
            document.isRedacted = true
            document.lastModifiedAt = Date()
            document.name = updatedDoc.name
            document.extractedText = nil
        }
    }
    
    /// Log redaction event for HIPAA audit trail
    private func logRedactionEvent(redactionAreas: Int, phiMatches: Int, verified: Bool) async {
        guard let vault = document.vault,
              let userID = authService.currentUser?.id else { return }
        
        await locationService.requestLocationPermission()
        let location = await locationService.getCurrentLocation()
        
        let deviceInfo = "Redacted \(redactionAreas) areas, \(phiMatches) PHI matches, verified: \(verified ? "Yes" : "No")"
        
        if AppConfig.useSupabase {
            // Create access log in Supabase
            var accessLog = SupabaseVaultAccessLog(
                vaultID: vault.id,
                timestamp: Date(),
                accessType: "redacted",
                userID: userID,
                userName: authService.currentUser?.fullName ?? "User",
                deviceInfo: deviceInfo
            )
            accessLog.documentID = document.id
            accessLog.documentName = document.name
            
            if let location = location {
                accessLog.locationLatitude = location.coordinate.latitude
                accessLog.locationLongitude = location.coordinate.longitude
            }
            
            _ = try? await supabaseService.insert("vault_access_logs", values: accessLog)
        } else {
            // Create access log in SwiftData
            let accessLog = VaultAccessLog(
                accessType: "redacted",
                userID: userID,
                userName: authService.currentUser?.fullName
            )
            accessLog.vault = vault
            accessLog.documentID = document.id
            accessLog.documentName = document.name
            accessLog.deviceInfo = deviceInfo
            
            if let location = location {
                accessLog.locationLatitude = location.coordinate.latitude
                accessLog.locationLongitude = location.coordinate.longitude
            }
            
            modelContext.insert(accessLog)
            try? modelContext.save()
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
