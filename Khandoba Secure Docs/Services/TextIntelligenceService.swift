//
//  TextIntelligenceService.swift
//  Khandoba Secure Docs
//
//  Text-based Intel Reports with Formal Logic
//  Converts all media to text, applies reasoning, generates layman-friendly debrief
//

import Foundation
import SwiftData
import Combine
import Vision
import Speech
import NaturalLanguage
import UIKit
import AVFoundation
import CoreLocation

@MainActor
final class TextIntelligenceService: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var currentStep: String = ""
    @Published var debriefText: String = ""
    @Published var intelligenceData: IntelligenceData?
    @Published var logicalInsights: LogicalInsights?
    
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Main Intel Pipeline
    
    /// Generate text-based Intel Report from selected documents
    func generateTextIntelReport(from documents: [Document]) async throws -> String {
        guard documents.count >= 2 else {
            throw IntelError.insufficientDocuments
        }
        
        isProcessing = true
        processingProgress = 0.0
        defer { isProcessing = false }
        
        print("📊 TEXT INTEL PIPELINE START")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 Processing \(documents.count) documents")
        
        // STEP 1: Convert all media to text
        currentStep = "Converting media to text..."
        processingProgress = 0.2
        let textDescriptions = await convertAllMediaToText(documents)
        print("✅ Step 1: \(textDescriptions.count) text descriptions created")
        
        // STEP 2: Extract entities and metadata
        currentStep = "Extracting entities and metadata..."
        processingProgress = 0.4
        let intelligence = await extractIntelligence(from: textDescriptions, documents: documents)
        intelligenceData = intelligence
        print("✅ Step 2: Intelligence extracted")
        
        // STEP 3: Apply formal logic reasoning
        currentStep = "Applying logical reasoning..."
        processingProgress = 0.6
        let logicalInsights = await applyFormalLogic(intelligence)
        self.logicalInsights = logicalInsights
        print("✅ Step 3: Logical reasoning complete")
        
        // STEP 4: Generate layman-friendly debrief
        currentStep = "Generating debrief..."
        processingProgress = 0.8
        let debrief = generateLaymanDebrief(intelligence, insights: logicalInsights)
        print("✅ Step 4: Debrief generated (\(debrief.count) chars)")
        
        processingProgress = 1.0
        currentStep = "Complete"
        debriefText = debrief
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✅ TEXT INTEL COMPLETE")
        
        return debrief
    }
    
    // MARK: - Step 1: Media → Text Conversion
    
    private func convertAllMediaToText(_ documents: [Document]) async -> [TextDescription] {
        var descriptions: [TextDescription] = []
        
        for (index, document) in documents.enumerated() {
            print("   [\(index + 1)/\(documents.count)] Converting: \(document.name)")
            
            if let desc = await convertDocumentToText(document) {
                descriptions.append(desc)
            }
        }
        
        return descriptions
    }
    
    private func convertDocumentToText(_ document: Document) async -> TextDescription? {
        guard let data = document.encryptedFileData else { return nil }
        
        var text = ""
        var entities: [String] = []
        var actions: [String] = []
        
        // Extract based on document type
        switch document.documentType {
        case "image":
            (text, entities, actions) = await analyzeImage(data)
        case "video":
            (text, entities, actions) = await analyzeVideo(data)
        case "audio":
            (text, entities, actions) = await analyzeAudio(data)
        case "pdf", "text":
            text = await extractTextContent(data)
            entities = extractEntities(from: text)
            actions = extractActions(from: text)
        default:
            return nil
        }
        
        return TextDescription(
            documentID: document.id,
            documentName: document.name,
            documentType: document.documentType,
            textContent: text,
            entities: entities,
            actions: actions,
            capturedAt: document.createdAt,
            uploadedAt: document.uploadedAt,
            location: extractLocation(from: document),
            metadata: extractMetadata(from: document)
        )
    }
    
    // MARK: - Image Analysis
    
    private func analyzeImage(_ data: Data) async -> (String, [String], [String]) {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return ("", [], [])
        }
        
        var text = ""
        var entities: [String] = []
        var actions: [String] = []
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // 1. Scene Classification
        let sceneRequest = VNClassifyImageRequest()
        try? handler.perform([sceneRequest])
        if let results = sceneRequest.results?.prefix(3) {
            let scenes = results.map { $0.identifier }.joined(separator: ", ")
            text += "Scene: \(scenes). "
        }
        
        // 2. Face Detection
        let faceRequest = VNDetectFaceRectanglesRequest()
        try? handler.perform([faceRequest])
        if let faceCount = faceRequest.results?.count, faceCount > 0 {
            text += "\(faceCount) person\(faceCount > 1 ? "s" : "") visible. "
            entities.append("\(faceCount) person\(faceCount > 1 ? "s" : "")")
        }
        
        // 3. Text Recognition (OCR)
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        try? handler.perform([textRequest])
        if let observations = textRequest.results {
            let ocrText = observations.compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            if !ocrText.isEmpty {
                text += "Text content: \(ocrText). "
                // Extract entities from OCR text
                entities.append(contentsOf: extractEntities(from: ocrText))
                actions.append(contentsOf: extractActions(from: ocrText))
            }
        }
        
        return (text, entities, actions)
    }
    
    // MARK: - Video Analysis
    
    private func analyzeVideo(_ data: Data) async -> (String, [String], [String]) {
        var text = ""
        var entities: [String] = []
        var actions: [String] = []
        
        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        do {
            try data.write(to: tempURL)
            
            // Extract audio and transcribe (primary content)
            if let transcript = await transcribeVideo(tempURL) {
                text += transcript
                entities.append(contentsOf: extractEntities(from: transcript))
                actions.append(contentsOf: extractActions(from: transcript))
            }
            
            // Analyze first frame (secondary visual context)
            let asset = AVURLAsset(url: tempURL)
            if let firstFrame = await extractFirstFrame(from: asset) {
                let (frameText, frameEntities, _) = await analyzeImage(firstFrame)
                if !frameText.isEmpty {
                    text += " Visual context: \(frameText)"
                    entities.append(contentsOf: frameEntities)
                }
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("   ⚠️ Video analysis error: \(error)")
        }
        
        return (text, Array(Set(entities)), Array(Set(actions)))
    }
    
    // MARK: - Audio Analysis
    
    private func analyzeAudio(_ data: Data) async -> (String, [String], [String]) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        do {
            try data.write(to: tempURL)
            
            if let transcript = await transcribeAudio(tempURL) {
                let entities = extractEntities(from: transcript)
                let actions = extractActions(from: transcript)
                
                // Cleanup
                try? FileManager.default.removeItem(at: tempURL)
                
                // Return full transcript without prefix
                return (transcript, entities, actions)
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("   ⚠️ Audio analysis error: \(error)")
        }
        
        return ("", [], [])
    }
    
    private func transcribeAudio(_ url: URL) async -> String? {
        // Request authorization if needed
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus != .authorized {
            await SFSpeechRecognizer.requestAuthorization { _ in }
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("   ⚠️ Speech recognition not authorized")
            return nil
        }
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("   ⚠️ Speech recognizer not available")
            return nil
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation // Better for longer audio
        
        return try? await withCheckedThrowingContinuation { continuation in
            var finalTranscript = ""
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    print("   ⚠️ Transcription error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                } else if let result = result {
                    finalTranscript = result.bestTranscription.formattedString
                    if result.isFinal {
                        print("   ✅ Transcription complete: \(finalTranscript.count) characters")
                        continuation.resume(returning: finalTranscript)
                    }
                }
            }
        }
    }
    
    private func transcribeVideo(_ url: URL) async -> String? {
        return await transcribeAudio(url)
    }
    
    private func extractFirstFrame(from asset: AVURLAsset) async -> Data? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        do {
            let time = CMTime(seconds: 0.5, preferredTimescale: 600)
            let cgImage = try await generator.image(at: time).image
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.8)
        } catch {
            return nil
        }
    }
    
    // MARK: - Text Extraction
    
    private func extractTextContent(_ data: Data) async -> String {
        // Try as plain text first
        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        
        // Try PDF extraction (would use PDFTextExtractor service)
        return ""
    }
    
    // MARK: - Entity & Action Extraction (NLP)
    
    private func extractEntities(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, tags.contains(tag) {
                let entity = String(text[tokenRange])
                entities.append("\(tagName(tag)): \(entity)")
            }
            return true
        }
        
        return Array(Set(entities))
    }
    
    private func extractActions(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var actions: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if tag == .verb {
                let verb = String(text[tokenRange])
                if verb.count > 3 {
                    actions.append(verb)
                }
            }
            return true
        }
        
        return Array(Set(actions)).prefix(10).map { $0 }
    }
    
    private func tagName(_ tag: NLTag) -> String {
        switch tag {
        case .personalName: return "Person"
        case .placeName: return "Location"
        case .organizationName: return "Organization"
        default: return "Entity"
        }
    }
    
    // MARK: - Metadata Extraction
    
    private func extractLocation(from document: Document) -> String? {
        // Check document metadata for location info
        if let metadata = document.metadata,
           let data = metadata.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let location = json["location"] as? String {
                return location
            }
        }
        return nil
    }
    
    private func extractMetadata(from document: Document) -> [String: String] {
        var metadata: [String: String] = [:]
        
        metadata["Created"] = document.createdAt.formatted(date: .long, time: .shortened)
        metadata["Uploaded"] = document.uploadedAt.formatted(date: .long, time: .shortened)
        metadata["Type"] = document.documentType
        metadata["Size"] = ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file)
        metadata["Source"] = document.sourceSinkType
        
        return metadata
    }
    
    // MARK: - Step 2: Intelligence Extraction
    
    private func extractIntelligence(from descriptions: [TextDescription], documents: [Document]) async -> IntelligenceData {
        print("   🧠 Extracting intelligence from text...")
        
        var intel = IntelligenceData()
        
        // Combine all text
        let combinedText = descriptions.map { $0.textContent }.joined(separator: " ")
        
        // Extract all entities
        for desc in descriptions {
            intel.entities.formUnion(desc.entities)
        }
        
        // Extract all actions
        for desc in descriptions {
            intel.actions.formUnion(desc.actions)
        }
        
        // Extract topics using NLP
        intel.topics = extractTopics(from: combinedText)
        
        // Build timeline from documents with full text content
        intel.timeline = descriptions.map {
            TimelineEvent(
                date: $0.capturedAt,
                uploadDate: $0.uploadedAt,
                document: $0.documentName,
                type: $0.documentType,
                location: $0.location,
                summary: $0.textContent.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }.sorted { $0.date < $1.date }
        
        // Extract locations
        for desc in descriptions {
            if let location = desc.location {
                intel.locations.insert(location)
            }
        }
        
        // Store metadata
        intel.allMetadata = descriptions.map { $0.metadata }
        
        return intel
    }
    
    private func extractTopics(from text: String) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var nouns: [String: Int] = [:]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if tag == .noun {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 4 {
                    nouns[word, default: 0] += 1
                }
            }
            return true
        }
        
        return Set(nouns.sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key.capitalized })
    }
    
    // MARK: - Step 3: Formal Logic Reasoning
    
    private func applyFormalLogic(_ intelligence: IntelligenceData) async -> LogicalInsights {
        print("   🧠 Applying formal logic reasoning...")
        
        var insights = LogicalInsights()
        
        // DEDUCTIVE REASONING
        insights.deductive = applyDeductiveReasoning(intelligence)
        
        // INDUCTIVE REASONING
        insights.inductive = applyInductiveReasoning(intelligence)
        
        // ABDUCTIVE REASONING (Best explanation)
        insights.abductive = applyAbductiveReasoning(intelligence)
        
        // TEMPORAL REASONING
        insights.temporal = applyTemporalReasoning(intelligence)
        
        return insights
    }
    
    private func applyDeductiveReasoning(_ intel: IntelligenceData) -> [String] {
        var conclusions: [String] = []
        
        // Modus Ponens: If A, then B. A is true. Therefore B.
        if intel.entities.count > 3 && intel.timeline.count > 2 {
            conclusions.append("Multiple entities across timeline indicate ongoing situation")
        }
        
        if intel.actions.contains(where: { ["signed", "approved", "agreed"].contains($0.lowercased()) }) {
            conclusions.append("Legal or contractual activity detected")
        }
        
        if intel.locations.count > 1 {
            conclusions.append("Activity spans multiple locations")
        }
        
        return conclusions
    }
    
    private func applyInductiveReasoning(_ intel: IntelligenceData) -> [String] {
        var patterns: [String] = []
        
        // Pattern recognition from examples
        let timeSpan = calculateTimeSpan(intel.timeline)
        if timeSpan > 7 { // More than a week
            patterns.append("Extended timeline suggests long-term situation (\(timeSpan) days)")
        }
        
        let entityTypes = categorizeEntities(intel.entities)
        if entityTypes["Person"]?.count ?? 0 > 2 {
            patterns.append("Multiple parties involved suggests collaboration or negotiation")
        }
        
        return patterns
    }
    
    private func applyAbductiveReasoning(_ intel: IntelligenceData) -> [String] {
        var explanations: [String] = []
        
        // Best explanation for observed data
        if intel.topics.contains(where: { $0.lowercased().contains("medical") || $0.lowercased().contains("health") }) {
            explanations.append("Healthcare documentation - likely medical records or treatment information")
        }
        
        if intel.topics.contains(where: { $0.lowercased().contains("legal") || $0.lowercased().contains("court") }) {
            explanations.append("Legal documentation - possibly litigation or contract matter")
        }
        
        if intel.entities.count > 5 && intel.timeline.count > 3 {
            explanations.append("Complex multi-party situation with documented progression")
        }
        
        return explanations
    }
    
    private func applyTemporalReasoning(_ intel: IntelligenceData) -> [String] {
        var temporal: [String] = []
        
        guard intel.timeline.count >= 2 else { return [] }
        
        let sortedEvents = intel.timeline.sorted { $0.date < $1.date }
        
        // First and last events
        if let first = sortedEvents.first, let last = sortedEvents.last {
            temporal.append("Timeline: \(first.date.formatted(date: .abbreviated, time: .omitted)) to \(last.date.formatted(date: .abbreviated, time: .omitted))")
        }
        
        // Detect patterns in document types over time
        let types = sortedEvents.map { $0.type }
        if types.allSatisfy({ $0 == "image" }) {
            temporal.append("Photographic documentation throughout period")
        } else if types.contains("audio") && types.contains("image") {
            temporal.append("Mixed media documentation suggests comprehensive record-keeping")
        }
        
        return temporal
    }
    
    // MARK: - Step 4: Simple Document Summary
    
    private func generateLaymanDebrief(_ intel: IntelligenceData, insights: LogicalInsights) -> String {
        var debrief = "# Document Summary\n\n"
        
        // Simple overview
        debrief += "## Overview\n\n"
        debrief += "This summary covers \(intel.timeline.count) document\(intel.timeline.count == 1 ? "" : "s").\n\n"
        
        // Document list with proper summaries
        if !intel.timeline.isEmpty {
            debrief += "## Documents\n\n"
            for (index, event) in intel.timeline.enumerated() {
                debrief += "\(index + 1). **\(event.document)**"
                debrief += " (\(event.type.capitalized))"
                if let location = event.location {
                    debrief += " - \(location)"
                }
                debrief += "\n"
                
                // Use full summary text, not truncated
                let fullSummary = event.summary.trimmingCharacters(in: .whitespacesAndNewlines)
                if !fullSummary.isEmpty {
                    // Clean up the summary - remove "Visual:" or "Audio content:" prefixes if present
                    var cleanSummary = fullSummary
                    if cleanSummary.hasPrefix("Visual: ") {
                        cleanSummary = String(cleanSummary.dropFirst(8))
                    } else if cleanSummary.hasPrefix("Audio content: ") {
                        cleanSummary = String(cleanSummary.dropFirst(15))
                    }
                    
                    debrief += "   \(cleanSummary)\n"
                }
                debrief += "\n"
            }
        }
        
        // Simple summary
        debrief += "## Summary\n\n"
        if !intel.entities.isEmpty {
            let entityList = Array(intel.entities.prefix(5)).joined(separator: ", ")
            debrief += "Key entities: \(entityList).\n\n"
        }
        
        if !intel.topics.isEmpty {
            let topicList = Array(intel.topics.prefix(5)).joined(separator: ", ")
            debrief += "Main topics: \(topicList).\n"
        }
        
        return debrief
    }
    
    // MARK: - Helper Functions
    
    private func categorizeEntities(_ entities: Set<String>) -> [String: [String]] {
        var categorized: [String: [String]] = [:]
        
        for entity in entities {
            let parts = entity.split(separator: ":").map { String($0.trimmingCharacters(in: .whitespaces)) }
            if parts.count == 2 {
                let category = parts[0]
                let value = parts[1]
                categorized[category, default: []].append(value)
            }
        }
        
        return categorized
    }
    
    private func calculateTimeSpan(_ timeline: [TimelineEvent]) -> Int {
        guard let first = timeline.first, let last = timeline.last else { return 0 }
        return Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
    }
    
    // MARK: - Data Models
    
    struct TextDescription {
        let documentID: UUID
        let documentName: String
        let documentType: String
        let textContent: String
        let entities: [String]
        let actions: [String]
        let capturedAt: Date
        let uploadedAt: Date
        let location: String?
        let metadata: [String: String]
    }
    
    struct IntelligenceData {
        var entities: Set<String> = []
        var actions: Set<String> = []
        var topics: Set<String> = []
        var timeline: [TimelineEvent] = []
        var locations: Set<String> = []
        var allMetadata: [[String: String]] = []
    }
    
    struct TimelineEvent {
        let date: Date
        let uploadDate: Date
        let document: String
        let type: String
        let location: String?
        let summary: String
    }
    
    struct LogicalInsights {
        var deductive: [String] = []    // Definite conclusions
        var inductive: [String] = []    // Pattern-based inferences
        var abductive: [String] = []    // Best explanations
        var temporal: [String] = []     // Time-based analysis
    }
}

// MARK: - Errors

enum IntelError: LocalizedError {
    case insufficientDocuments
    case conversionFailed
    case analysisFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientDocuments:
            return "At least 2 documents required for Intel Report"
        case .conversionFailed:
            return "Failed to convert media to text"
        case .analysisFailed:
            return "Failed to analyze intelligence"
        }
    }
}

