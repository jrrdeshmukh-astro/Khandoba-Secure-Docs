//
//  NLPTaggingService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import NaturalLanguage
import Vision
import UIKit

class NLPTaggingService {
    
    /// Generate intelligent document name based on content
    static func generateDocumentName(
        for data: Data,
        mimeType: String?,
        fallbackName: String
    ) async -> String {
        // Extract text from document
        if let text = await extractText(from: data, mimeType: mimeType), !text.isEmpty {
            // Get first meaningful phrase or keywords
            let keywords = extractKeywords(from: text)
            
            if !keywords.isEmpty {
                // Use top 2-3 keywords as name
                let nameParts = keywords.prefix(3)
                var suggestedName = nameParts.joined(separator: " ")
                
                // Add file extension
                if let ext = fileExtension(from: mimeType) {
                    suggestedName += ".\(ext)"
                }
                
                return suggestedName
            }
            
            // Try to find a title or header
            if let title = extractTitle(from: text) {
                if let ext = fileExtension(from: mimeType) {
                    return "\(title).\(ext)"
                }
                return title
            }
        }
        
        // Analyze filename for clues
        let analyzedTags = analyzeFilename(fallbackName)
        if !analyzedTags.isEmpty {
            let categoryName = analyzedTags.first ?? "Document"
            if let ext = fileExtension(from: mimeType) {
                return "\(categoryName)_\(Date().timeIntervalSince1970).\(ext)"
            }
            return "\(categoryName)_\(Date().timeIntervalSince1970)"
        }
        
        // Use fallback with timestamp
        return fallbackName
    }
    
    private static func extractTitle(from text: String) -> String? {
        // Get first line or first sentence
        let lines = text.components(separatedBy: .newlines)
        if let firstLine = lines.first, !firstLine.isEmpty, firstLine.count < 50 {
            return firstLine.trimmingCharacters(in: .whitespaces)
        }
        
        // Try first sentence
        if let firstSentence = text.components(separatedBy: ".").first,
           !firstSentence.isEmpty,
           firstSentence.count < 50 {
            return firstSentence.trimmingCharacters(in: .whitespaces)
        }
        
        return nil
    }
    
    private static func fileExtension(from mimeType: String?) -> String? {
        guard let mimeType = mimeType else { return nil }
        
        switch mimeType {
        case "image/jpeg", "image/jpg": return "jpg"
        case "image/png": return "png"
        case "application/pdf": return "pdf"
        case "video/mp4": return "mp4"
        case "video/quicktime": return "mov"
        case "audio/m4a": return "m4a"
        case "audio/mp3": return "mp3"
        default: return nil
        }
    }
    
    /// Generate comprehensive AI tags for a document
    static func generateTags(
        for data: Data,
        mimeType: String?,
        documentName: String
    ) async -> [String] {
        var tags: [String] = []
        
        // Add document type tags
        if let mimeType = mimeType {
            tags.append(contentsOf: tagsForMimeType(mimeType))
        }
        
        // Extract text and analyze
        if let text = await extractText(from: data, mimeType: mimeType) {
            tags.append(contentsOf: await analyzeText(text))
        }
        
        // Analyze filename
        tags.append(contentsOf: analyzeFilename(documentName))
        
        // Remove duplicates and return
        return Array(Set(tags))
    }
    
    // MARK: - Text Extraction
    
    private static func extractText(from data: Data, mimeType: String?) async -> String? {
        guard let mimeType = mimeType else { return nil }
        
        if mimeType.hasPrefix("image/") {
            return await extractTextFromImage(data)
        } else if mimeType == "application/pdf" {
            return extractTextFromPDF(data)
        } else if mimeType.hasPrefix("text/") {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    private static func extractTextFromImage(_ data: Data) async -> String? {
        guard let image = UIImage(data: data) else { return nil }
        guard let cgImage = image.cgImage else { return nil }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                continuation.resume(returning: recognizedText.isEmpty ? nil : recognizedText)
            }
            
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private static func extractTextFromPDF(_ data: Data) -> String? {
        // Use PDFTextExtractor service
        return PDFTextExtractor.extractFromPDF(data: data)
    }
    
    // MARK: - NLP Analysis
    
    private static func analyzeText(_ text: String) async -> [String] {
        var tags: [String] = []
        
        // Named Entity Recognition
        tags.append(contentsOf: extractNamedEntities(from: text))
        
        // Keyword extraction
        tags.append(contentsOf: extractKeywords(from: text))
        
        // Sentiment analysis
        if let sentiment = analyzeSentiment(text) {
            tags.append(sentiment)
        }
        
        // Language detection
        if let language = detectLanguage(text) {
            tags.append("Language: \(language)")
        }
        
        return tags
    }
    
    private static func extractNamedEntities(from text: String) -> [String] {
        var entities: [String] = []
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, tags.contains(tag) {
                let entity = String(text[tokenRange])
                
                switch tag {
                case .personalName:
                    entities.append("Person: \(entity)")
                case .placeName:
                    entities.append("Location: \(entity)")
                case .organizationName:
                    entities.append("Organization: \(entity)")
                default:
                    break
                }
            }
            return true
        }
        
        return entities
    }
    
    private static func extractKeywords(from text: String) -> [String] {
        var keywords: [String] = []
        
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        // Extract nouns and proper nouns as keywords
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            
            // Only include meaningful words (length > 3, not common words)
            if word.count > 3 && !isCommonWord(word) {
                keywords.append(word.capitalized)
            }
            
            return true
        }
        
        // Return top 10 keywords
        return Array(Set(keywords)).prefix(10).map { String($0) }
    }
    
    private static func analyzeSentiment(_ text: String) -> String? {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        if let sentiment = sentiment, let score = Double(sentiment.rawValue) {
            if score > 0.3 {
                return "Sentiment: Positive"
            } else if score < -0.3 {
                return "Sentiment: Negative"
            } else {
                return "Sentiment: Neutral"
            }
        }
        
        return nil
    }
    
    private static func detectLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let language = recognizer.dominantLanguage {
            return language.rawValue
        }
        
        return nil
    }
    
    // MARK: - Helpers
    
    private static func tagsForMimeType(_ mimeType: String) -> [String] {
        var tags: [String] = []
        
        if mimeType.hasPrefix("image/") {
            tags.append("Image")
            if mimeType.contains("jpeg") || mimeType.contains("jpg") {
                tags.append("JPEG")
            } else if mimeType.contains("png") {
                tags.append("PNG")
            }
        } else if mimeType == "application/pdf" {
            tags.append("PDF")
            tags.append("Document")
        } else if mimeType.hasPrefix("video/") {
            tags.append("Video")
        } else if mimeType.hasPrefix("audio/") {
            tags.append("Audio")
        } else if mimeType.hasPrefix("text/") {
            tags.append("Text")
        }
        
        return tags
    }
    
    private static func analyzeFilename(_ filename: String) -> [String] {
        var tags: [String] = []
        let lowercased = filename.lowercased()
        
        // Common document types
        if lowercased.contains("invoice") {
            tags.append("Invoice")
        }
        if lowercased.contains("receipt") {
            tags.append("Receipt")
        }
        if lowercased.contains("contract") {
            tags.append("Contract")
        }
        if lowercased.contains("report") {
            tags.append("Report")
        }
        if lowercased.contains("medical") || lowercased.contains("health") {
            tags.append("Medical")
        }
        if lowercased.contains("legal") {
            tags.append("Legal")
        }
        if lowercased.contains("financial") || lowercased.contains("bank") {
            tags.append("Financial")
        }
        
        return tags
    }
    
    private static func isCommonWord(_ word: String) -> Bool {
        let commonWords = ["the", "and", "for", "that", "this", "with", "from", "have", "been", "will", "would", "could", "should"]
        return commonWords.contains(word.lowercased())
    }
}

