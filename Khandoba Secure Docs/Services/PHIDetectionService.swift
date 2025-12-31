//
//  PHIDetectionService.swift
//  Khandoba Secure Docs
//
//  PHI detection and redaction service for HIPAA compliance
//

import Foundation
import NaturalLanguage
import Vision
import SwiftData
import UIKit

/// PHI type enum
enum PHIType: String, Codable {
    case ssn = "SSN"
    case medicalRecordNumber = "Medical Record Number"
    case patientName = "Patient Name"
    case dateOfBirth = "Date of Birth"
    case address = "Address"
    case phoneNumber = "Phone Number"
    case email = "Email"
    case insuranceNumber = "Insurance Number"
    case diagnosis = "Diagnosis"
    case treatment = "Treatment"
}

/// PHI detection errors
enum PHIDetectionError: LocalizedError {
    case detectionFailed
    case invalidDocument
    case redactionFailed
    
    var errorDescription: String? {
        switch self {
        case .detectionFailed:
            return "Failed to detect PHI in document."
        case .invalidDocument:
            return "Invalid document format."
        case .redactionFailed:
            return "Failed to redact PHI from document."
        }
    }
}

@MainActor
final class PHIDetectionService {
    static let shared = PHIDetectionService()
    
    private init() {}
    
    // MARK: - PHI Detection
    
    /// Detect PHI in document text
    func detectPHI(in text: String) async -> [PHIMatch] {
        var matches: [PHIMatch] = []
        
        // SSN pattern (XXX-XX-XXXX)
        let ssnPattern = #"\b\d{3}-\d{2}-\d{4}\b"#
        matches.append(contentsOf: detectPattern(in: text, pattern: ssnPattern, type: .ssn))
        
        // Medical record number pattern (varies by institution)
        let mrnPattern = #"\bMRN[:\s]?\d{6,}\b"#
        matches.append(contentsOf: detectPattern(in: text, pattern: mrnPattern, type: .medicalRecordNumber))
        
        // Date of birth patterns
        let dobPattern = #"\b(DOB|Date of Birth|Birth Date)[:\s]?\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b"#
        matches.append(contentsOf: detectPattern(in: text, pattern: dobPattern, type: .dateOfBirth))
        
        // Phone number pattern
        let phonePattern = #"\b\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b"#
        matches.append(contentsOf: detectPattern(in: text, pattern: phonePattern, type: .phoneNumber))
        
        // Email pattern
        let emailPattern = #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#
        matches.append(contentsOf: detectPattern(in: text, pattern: emailPattern, type: .email))
        
        // Insurance number pattern
        let insurancePattern = #"\b(Insurance|Policy|Member ID)[:\s]?\d{6,}\b"#
        matches.append(contentsOf: detectPattern(in: text, pattern: insurancePattern, type: .insuranceNumber))
        
        // Use NaturalLanguage framework for named entity recognition
        matches.append(contentsOf: detectNamedEntities(in: text))
        
        // Remove duplicates
        return Array(Set(matches.map { $0.value })).compactMap { value in
            matches.first { $0.value == value }
        }
    }
    
    /// Detect PHI in document using OCR
    func detectPHIInImage(_ imageData: Data) async throws -> [PHIMatch] {
        guard let image = UIImage(data: imageData) else {
            throw PHIDetectionError.invalidDocument
        }
        
        var matches: [PHIMatch] = []
        
        // Use Vision framework for text recognition
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                let text = topCandidate.string
                
                // Detect PHI in recognized text
                Task {
                    let phiMatches = await self.detectPHI(in: text)
                    matches.append(contentsOf: phiMatches)
                }
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        try handler.perform([request])
        
        return matches
    }
    
    // MARK: - Pattern Detection
    
    private func detectPattern(in text: String, pattern: String, type: PHIType) -> [PHIMatch] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return []
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            let value = String(text[range])
            let nsRange = NSRange(range, in: text)
            return PHIMatch(
                type: type.rawValue,
                value: value,
                range: nsRange
            )
        }
    }
    
    // MARK: - Named Entity Recognition
    
    private func detectNamedEntities(in text: String) -> [PHIMatch] {
        var matches: [PHIMatch] = []
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag {
                switch tag {
                case .personalName:
                    let name = String(text[tokenRange])
                    let nsRange = NSRange(tokenRange, in: text)
                    matches.append(PHIMatch(
                        type: PHIType.patientName.rawValue,
                        value: name,
                        range: nsRange
                    ))
                case .placeName:
                    let place = String(text[tokenRange])
                    // Check if it's likely an address
                    if place.count > 5 {
                        let nsRange = NSRange(tokenRange, in: text)
                        matches.append(PHIMatch(
                            type: PHIType.address.rawValue,
                            value: place,
                            range: nsRange
                        ))
                    }
                default:
                    break
                }
            }
            return true
        }
        
        return matches
    }
    
    // MARK: - Document Classification
    
    /// Check if document contains PHI
    func documentContainsPHI(_ document: Document) async -> Bool {
        // Extract text from document
        guard let data = document.encryptedFileData else { return false }
        
        let text: String
        if document.mimeType?.contains("pdf") == true {
            text = await PDFTextExtractor.extractText(from: document) ?? ""
        } else if document.mimeType?.hasPrefix("image/") == true {
            do {
                let matches = try await detectPHIInImage(data)
                return !matches.isEmpty
            } catch {
                return false
            }
        } else if document.mimeType?.hasPrefix("text/") == true {
            text = String(data: data, encoding: .utf8) ?? ""
        } else {
            return false
        }
        
        let matches = await detectPHI(in: text)
        return !matches.isEmpty
    }
    
    /// Mark document as containing PHI
    func markDocumentAsPHI(_ document: Document, modelContext: ModelContext) throws {
        // Add PHI tag to document
        var tags = document.aiTags ?? []
        if !tags.contains("phi") {
            tags.append("phi")
        }
        if !tags.contains("hipaa-protected") {
            tags.append("hipaa-protected")
        }
        document.aiTags = tags
        
        try modelContext.save()
    }
}

