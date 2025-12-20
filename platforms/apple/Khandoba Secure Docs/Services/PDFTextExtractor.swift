//
//  PDFTextExtractor.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import PDFKit
import Vision
#if os(iOS)
import UIKit
#endif

/// Extract text from various document formats
struct PDFTextExtractor {
    
    /// Extract text from PDF data
    static func extractFromPDF(data: Data) -> String {
        guard let pdfDocument = PDFDocument(data: data) else {
            return ""
        }
        
        var fullText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        
        return fullText
    }
    
    /// Extract text from image using OCR
    static func extractFromImage(data: Data) async throws -> String {
        #if os(iOS)
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            throw PDFTextExtractorError.invalidImage
        }
        #elseif os(macOS)
        guard let image = NSImage(data: data) else {
            throw PDFTextExtractorError.invalidImage
        }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw PDFTextExtractorError.invalidImage
        }
        #endif
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    /// Extract text based on file type
    static func extractText(from document: Document) async -> String {
        guard let data = document.encryptedFileData else {
            return document.name
        }
        
        let fileType = document.documentType.lowercased()
        
        // PDF
        if fileType.contains("pdf") {
            return extractFromPDF(data: data)
        }
        
        // Images
        if fileType.contains("image") || fileType.contains("png") || 
           fileType.contains("jpg") || fileType.contains("jpeg") {
            return (try? await extractFromImage(data: data)) ?? ""
        }
        
        // Plain text
        if fileType.contains("text") || fileType.contains("txt") {
            return String(data: data, encoding: .utf8) ?? ""
        }
        
        // Fallback: Use name + extracted text if available
        var text = document.name
        if let extracted = document.extractedText {
            text += " " + extracted
        }
        
        return text
    }
}

enum PDFTextExtractorError: LocalizedError {
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        }
    }
}

