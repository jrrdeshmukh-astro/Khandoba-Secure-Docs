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
            
            // Document Preview with Redaction Overlay
            ZStack {
                colors.background
                
                if document.documentType == "pdf" || document.documentType == "image" {
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
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(colors.warning)
                        Text("Redaction not supported for this document type")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
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
            // For PDF, find text on each page
            for pageIndex in 0..<pdf.pageCount {
                guard let page = pdf.page(at: pageIndex),
                      let pageText = page.string,
                      pageText.contains(phi.value) else { continue }
                
                // Find text selection that matches PHI
                if let selection = page.selectionForRange(NSRange(location: 0, length: pageText.count)) {
                    let bounds = selection.bounds(for: page, characterRange: NSRange(location: 0, length: pageText.count))
                    Task { @MainActor in
                        redactionAreas.append(bounds)
                    }
                }
            }
        }
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
