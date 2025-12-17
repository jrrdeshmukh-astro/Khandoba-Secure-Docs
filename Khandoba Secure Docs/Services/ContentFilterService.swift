//
//  ContentFilterService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import Foundation
import Vision
import NaturalLanguage
import UIKit
import AVFoundation
import CoreML
import PDFKit
import Speech
import Combine

/// Content filter result
struct ContentFilterResult {
    var isBlocked: Bool
    var severity: ContentSeverity
    var categories: [ContentCategory]
    var confidence: Double
    var reason: String?
}

/// Content severity levels
enum ContentSeverity: String, Codable, Comparable {
    case safe = "safe"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case explicit = "explicit"
    
    var shouldBlock: Bool {
        switch self {
        case .safe, .low:
            return false
        case .medium, .high, .explicit:
            return true
        }
    }
    
    // For comparison
    private var severityLevel: Int {
        switch self {
        case .safe: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .explicit: return 4
        }
    }
    
    static func < (lhs: ContentSeverity, rhs: ContentSeverity) -> Bool {
        lhs.severityLevel < rhs.severityLevel
    }
}

/// Content categories detected
enum ContentCategory: String, Codable {
    case nudity = "nudity"
    case violence = "violence"
    case profanity = "profanity"
    case hateSpeech = "hate_speech"
    case drugUse = "drug_use"
    case weapons = "weapons"
    case adult = "adult"
    case other = "other"
}

@MainActor
final class ContentFilterService: ObservableObject {
    @Published var isFiltering = false
    
    // Content filter settings
    var filterEnabled: Bool = true
    var blockOnMedium: Bool = true // Block medium severity content
    var blockOnHigh: Bool = true // Block high severity content
    var blockOnExplicit: Bool = true // Block explicit content
    
    // Profanity word list (basic - can be expanded)
    private let profanityWords: Set<String> = [
        // Add common profanity words here
        // This is a basic implementation - in production, use a comprehensive list
    ]
    
    nonisolated init() {}
    
    // MARK: - Main Filter Method
    
    /// Filter content from document data
    func filterContent(
        data: Data,
        mimeType: String?,
        documentType: String?
    ) async throws -> ContentFilterResult {
        guard filterEnabled else {
            return ContentFilterResult(
                isBlocked: false,
                severity: .safe,
                categories: [],
                confidence: 1.0,
                reason: nil
            )
        }
        
        isFiltering = true
        defer { isFiltering = false }
        
        print("🔍 Filtering content: \(mimeType ?? "unknown")")
        
        guard let mimeType = mimeType else {
            // Unknown type - allow but log
            return ContentFilterResult(
                isBlocked: false,
                severity: .safe,
                categories: [],
                confidence: 0.5,
                reason: "Unknown MIME type"
            )
        }
        
        // Route to appropriate filter based on content type
        if mimeType.hasPrefix("image/") {
            return try await filterImage(data: data)
        } else if mimeType.hasPrefix("video/") {
            return try await filterVideo(data: data)
        } else if mimeType.hasPrefix("audio/") {
            return try await filterAudio(data: data)
        } else if mimeType == "application/pdf" || mimeType.hasPrefix("text/") {
            return try await filterText(data: data)
        } else {
            // For other types, try text extraction if possible
            if let text = try? await extractTextFromData(data: data, mimeType: mimeType) {
                return try await filterTextContent(text: text)
            }
            
            // Unknown/unsupported type - allow but log
            return ContentFilterResult(
                isBlocked: false,
                severity: .safe,
                categories: [],
                confidence: 0.5,
                reason: "Unsupported content type for filtering"
            )
        }
    }
    
    // MARK: - Image Filtering
    
    private func filterImage(data: Data) async throws -> ContentFilterResult {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            throw ContentFilterError.invalidImage
        }
        
        var categories: [ContentCategory] = []
        var maxSeverity: ContentSeverity = .safe
        var maxConfidence: Double = 0.0
        var reasons: [String] = []
        
        // Use Vision framework for image analysis
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 1. Scene classification (detect adult/inappropriate scenes)
        let sceneRequest = VNClassifyImageRequest()
        try handler.perform([sceneRequest])
        
        if let observations = sceneRequest.results {
            for observation in observations {
                let identifier = observation.identifier.lowercased()
                let confidence = Double(observation.confidence)
                
                // Check for inappropriate content
                if identifier.contains("adult") || identifier.contains("nude") || identifier.contains("nudity") || identifier.contains("explicit") {
                    categories.append(.nudity)
                    if confidence > maxConfidence {
                        maxConfidence = confidence
                        maxSeverity = .explicit
                        reasons.append("Detected adult/nude content (confidence: \(Int(confidence * 100))%)")
                    }
                } else if identifier.contains("violence") || identifier.contains("weapon") || identifier.contains("gun") || identifier.contains("blood") {
                    categories.append(.violence)
                    if confidence > maxConfidence {
                        maxConfidence = confidence
                        maxSeverity = .high
                        reasons.append("Detected violent content (confidence: \(Int(confidence * 100))%)")
                    }
                }
            }
        }
        
        // 2. Object detection (detect weapons, drugs, etc.)
        // Note: VNDetectObjectRectanglesRequest is deprecated in iOS 13+
        // For production, use custom Core ML models or VNDetectHumanRectanglesRequest
        // For now, we'll skip object detection and rely on scene classification
        
        // 3. Text recognition (check for profanity in image text)
        let textRequest = VNRecognizeTextRequest()
        try handler.perform([textRequest])
        
        if let textObservations = textRequest.results {
            var detectedText = ""
            for observation in textObservations {
                if let topCandidate = observation.topCandidates(1).first {
                    detectedText += topCandidate.string + " "
                }
            }
            
            if !detectedText.isEmpty {
                let textResult = try await filterTextContent(text: detectedText)
                if textResult.isBlocked {
                    categories.append(contentsOf: textResult.categories)
                    if textResult.severity > maxSeverity {
                        maxSeverity = textResult.severity
                        maxConfidence = textResult.confidence
                        reasons.append("Detected inappropriate text in image: \(textResult.reason ?? "")")
                    }
                }
            }
        }
        
        // Determine if content should be blocked
        let shouldBlock = determineBlockStatus(severity: maxSeverity)
        
        return ContentFilterResult(
            isBlocked: shouldBlock,
            severity: maxSeverity,
            categories: Array(Set(categories)), // Remove duplicates
            confidence: maxConfidence,
            reason: reasons.isEmpty ? nil : reasons.joined(separator: "; ")
        )
    }
    
    // MARK: - Video Filtering
    
    private func filterVideo(data: Data) async throws -> ContentFilterResult {
        // Save to temporary file for analysis
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        try data.write(to: tempURL)
        let asset = AVURLAsset(url: tempURL)
        
        var categories: [ContentCategory] = []
        var maxSeverity: ContentSeverity = .safe
        var maxConfidence: Double = 0.0
        var reasons: [String] = []
        
        // Extract frames at key points (start, middle, end)
        let frameTimes = [
            CMTime(seconds: 0, preferredTimescale: 600),
            CMTime(seconds: CMTimeGetSeconds(asset.duration) / 2, preferredTimescale: 600),
            CMTime(seconds: CMTimeGetSeconds(asset.duration) * 0.9, preferredTimescale: 600)
        ]
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        for time in frameTimes {
            if let cgImage = try? await imageGenerator.copyCGImage(at: time, actualTime: nil) {
                let frameResult = try await filterImageFrame(cgImage: cgImage)
                
                if frameResult.isBlocked {
                    categories.append(contentsOf: frameResult.categories)
                    if frameResult.severity > maxSeverity {
                        maxSeverity = frameResult.severity
                        maxConfidence = frameResult.confidence
                        reasons.append("Frame at \(Int(CMTimeGetSeconds(time)))s: \(frameResult.reason ?? "")")
                    }
                }
            }
        }
        
        // Check audio track for profanity
        if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
            // In a real implementation, extract audio and use speech recognition
            // For now, we'll rely on frame analysis
        }
        
        let shouldBlock = determineBlockStatus(severity: maxSeverity)
        
        return ContentFilterResult(
            isBlocked: shouldBlock,
            severity: maxSeverity,
            categories: Array(Set(categories)),
            confidence: maxConfidence,
            reason: reasons.isEmpty ? nil : reasons.joined(separator: "; ")
        )
    }
    
    private func filterImageFrame(cgImage: CGImage) async throws -> ContentFilterResult {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var categories: [ContentCategory] = []
        var maxSeverity: ContentSeverity = .safe
        var maxConfidence: Double = 0.0
        
        let sceneRequest = VNClassifyImageRequest()
        try handler.perform([sceneRequest])
        
        if let observations = sceneRequest.results {
            for observation in observations {
                let identifier = observation.identifier.lowercased()
                let confidence = Double(observation.confidence)
                
                if identifier.contains("adult") || identifier.contains("nude") || identifier.contains("nudity") || identifier.contains("explicit") {
                    categories.append(.nudity)
                    if confidence > maxConfidence {
                        maxConfidence = confidence
                        maxSeverity = .explicit
                    }
                } else if identifier.contains("violence") || identifier.contains("weapon") || identifier.contains("blood") {
                    categories.append(.violence)
                    if confidence > maxConfidence {
                        maxConfidence = confidence
                        maxSeverity = .high
                    }
                }
            }
        }
        
        return ContentFilterResult(
            isBlocked: determineBlockStatus(severity: maxSeverity),
            severity: maxSeverity,
            categories: categories,
            confidence: maxConfidence,
            reason: nil
        )
    }
    
    // MARK: - Audio Filtering
    
    private func filterAudio(data: Data) async throws -> ContentFilterResult {
        // Save to temporary file for transcription
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        try data.write(to: tempURL)
        
        // Transcribe audio using Speech framework
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer = recognizer else {
            // Cannot transcribe - allow but log
            return ContentFilterResult(
                isBlocked: false,
                severity: .safe,
                categories: [],
                confidence: 0.5,
                reason: "Speech recognition not available"
            )
        }
        
        let request = SFSpeechURLRecognitionRequest(url: tempURL)
        request.shouldReportPartialResults = false
        
        // Note: SFSpeechRecognizer requires proper authorization
        // For now, we'll return safe if transcription fails
        // In production, implement proper speech recognition with authorization
        
        // For now, return safe (audio filtering requires speech recognition setup)
        return ContentFilterResult(
            isBlocked: false,
            severity: .safe,
            categories: [],
            confidence: 0.5,
            reason: "Audio content filtering requires speech recognition setup"
        )
    }
    
    // MARK: - Text Filtering
    
    private func filterText(data: Data) async throws -> ContentFilterResult {
        guard let text = String(data: data, encoding: .utf8) else {
            throw ContentFilterError.invalidText
        }
        
        return try await filterTextContent(text: text)
    }
    
    private func filterTextContent(text: String) async throws -> ContentFilterResult {
        var categories: [ContentCategory] = []
        var maxSeverity: ContentSeverity = .safe
        var maxConfidence: Double = 0.0
        var reasons: [String] = []
        
        let lowercasedText = text.lowercased()
        
        // 1. Check for profanity
        let profanityCount = profanityWords.filter { lowercasedText.contains($0) }.count
        if profanityCount > 0 {
                    categories.append(.profanity)
                    let severity: ContentSeverity = profanityCount > 5 ? .high : .medium
                    if severity > maxSeverity {
                        maxSeverity = severity
                        maxConfidence = min(Double(profanityCount) / 10.0, 1.0)
                        reasons.append("Detected \(profanityCount) profanity word(s)")
                    }
        }
        
        // 2. Use NaturalLanguage framework for sentiment and entity analysis
        let tagger = NLTagger(tagSchemes: [.sentimentScore, .lexicalClass])
        tagger.string = text
        
        // Check sentiment (very negative sentiment might indicate inappropriate content)
        var sentimentScore: Double = 0.0
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, tokenRange in
            if let tag = tag, let score = Double(tag.rawValue) {
                sentimentScore = score
            }
            return true
        }
        
        // Very negative sentiment might indicate hate speech
        if sentimentScore < -0.7 {
            categories.append(.hateSpeech)
            if maxSeverity < .high {
                maxSeverity = .high
                maxConfidence = abs(sentimentScore)
                reasons.append("Detected highly negative sentiment (possible hate speech)")
            }
        }
        
        // 3. Check for drug-related keywords
        let drugKeywords = ["drug", "cocaine", "heroin", "marijuana", "cannabis", "opioid", "meth", "crack"]
        let drugCount = drugKeywords.filter { lowercasedText.contains($0) }.count
        if drugCount > 0 {
            categories.append(.drugUse)
            if maxSeverity < .medium {
                maxSeverity = .medium
                maxConfidence = min(Double(drugCount) / 5.0, 1.0)
                reasons.append("Detected drug-related content")
            }
        }
        
        // 4. Check for weapon-related keywords
        let weaponKeywords = ["gun", "weapon", "knife", "bomb", "explosive", "ammunition"]
        let weaponCount = weaponKeywords.filter { lowercasedText.contains($0) }.count
        if weaponCount > 0 {
            categories.append(.weapons)
            if maxSeverity < .medium {
                maxSeverity = .medium
                maxConfidence = min(Double(weaponCount) / 5.0, 1.0)
                reasons.append("Detected weapon-related content")
            }
        }
        
        let shouldBlock = determineBlockStatus(severity: maxSeverity)
        
        return ContentFilterResult(
            isBlocked: shouldBlock,
            severity: maxSeverity,
            categories: Array(Set(categories)),
            confidence: maxConfidence,
            reason: reasons.isEmpty ? nil : reasons.joined(separator: "; ")
        )
    }
    
    // MARK: - Helper Methods
    
    private func determineBlockStatus(severity: ContentSeverity) -> Bool {
        switch severity {
        case .safe, .low:
            return false
        case .medium:
            return blockOnMedium
        case .high:
            return blockOnHigh
        case .explicit:
            return blockOnExplicit
        }
    }
    
    private func extractTextFromData(data: Data, mimeType: String) async throws -> String? {
        if mimeType == "application/pdf" {
            // Extract text from PDF
            guard let pdfDocument = PDFDocument(data: data) else {
                return nil
            }
            
            var text = ""
            for i in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: i) {
                    text += page.string ?? ""
                }
            }
            
            return text.isEmpty ? nil : text
        } else if mimeType.hasPrefix("text/") {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
}

// MARK: - Error Types

enum ContentFilterError: LocalizedError {
    case invalidImage
    case invalidVideo
    case invalidAudio
    case invalidText
    case filteringFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .invalidVideo:
            return "Invalid video data"
        case .invalidAudio:
            return "Invalid audio data"
        case .invalidText:
            return "Invalid text data"
        case .filteringFailed:
            return "Content filtering failed"
        }
    }
}
