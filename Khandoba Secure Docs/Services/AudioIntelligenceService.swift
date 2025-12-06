//
//  AudioIntelligenceService.swift
//  Khandoba Secure Docs
//
//  Audio-to-Audio Intel Reports System
//  Converts all media to audio, applies intelligence algorithms
//

import Foundation
import SwiftData
import Combine
import AVFoundation
import Vision
import Speech
import NaturalLanguage
import UIKit
import CoreMedia

@MainActor
final class AudioIntelligenceService: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var currentStep: String = ""
    
    private var modelContext: ModelContext?
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Main Intel Generation Pipeline
    
    /// Generate Intel Report from selected documents using Audio-to-Audio processing
    func generateAudioIntelReport(from documents: [Document]) async throws -> URL {
        guard documents.count >= 2 else {
            throw AudioIntelError.insufficientDocuments
        }
        
        isProcessing = true
        processingProgress = 0.0
        defer { isProcessing = false }
        
        print("AUDIO INTEL PIPELINE START")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(" Processing \(documents.count) documents")
        
        // STEP 1: Convert all documents to audio descriptions
        currentStep = "Converting media to audio..."
        processingProgress = 0.1
        let audioDescriptions = await convertAllDocumentsToAudio(documents)
        print(" Step 1: \(audioDescriptions.count) audio streams created")
        
        // STEP 2: Transcribe all audio to text
        currentStep = "Transcribing audio content..."
        processingProgress = 0.3
        let combinedTranscript = await transcribeAllAudio(audioDescriptions)
        print(" Step 2: Combined transcript (\(combinedTranscript.count) chars)")
        
        // STEP 3: Analyze transcript for intelligence
        currentStep = "Analyzing intelligence..."
        processingProgress = 0.5
        let intelligence = await analyzeTranscriptForIntel(combinedTranscript, documents: documents)
        print(" Step 3: Intelligence analysis complete")
        
        // STEP 4: Generate debrief narrative
        currentStep = "Generating debrief..."
        processingProgress = 0.7
        let debriefText = generateDebriefNarrative(intelligence)
        print(" Step 4: Debrief narrative generated (\(debriefText.count) chars)")
        
        // STEP 5: Convert debrief to audio
        currentStep = "Creating audio debrief..."
        processingProgress = 0.9
        let debriefAudioURL = try await convertTextToAudio(debriefText)
        print(" Step 5: Audio debrief created")
        
        processingProgress = 1.0
        currentStep = "Complete"
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎉 AUDIO INTEL COMPLETE")
        
        return debriefAudioURL
    }
    
    // MARK: - Step 1: Media to Audio Conversion
    
    private func convertAllDocumentsToAudio(_ documents: [Document]) async -> [AudioDescription] {
        var audioDescriptions: [AudioDescription] = []
        
        for (index, document) in documents.enumerated() {
            print("   [\(index + 1)/\(documents.count)] Converting: \(document.name)")
            
            if let audioDesc = await convertDocumentToAudio(document) {
                audioDescriptions.append(audioDesc)
            }
        }
        
        return audioDescriptions
    }
    
    private func convertDocumentToAudio(_ document: Document) async -> AudioDescription? {
        guard let data = document.encryptedFileData else { return nil }
        
        switch document.documentType {
        case "image":
            return await convertImageToAudio(data, document: document)
        case "video":
            return await convertVideoToAudio(data, document: document)
        case "audio":
            return await extractAudioContent(data, document: document)
        case "pdf", "text":
            return await convertTextToAudioDescription(data, document: document)
        default:
            return nil
        }
    }
    
    /// Convert image to audio description using Vision
    private func convertImageToAudio(_ data: Data, document: Document) async -> AudioDescription? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return nil
        }
        
        var description = "Image: \(document.name). "
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Scene classification
        let sceneRequest = VNClassifyImageRequest()
        try? handler.perform([sceneRequest])
        if let results = sceneRequest.results?.prefix(3) {
            let scenes = results.map { $0.identifier }.joined(separator: ", ")
            description += "Scene shows: \(scenes). "
        }
        
        // Face detection
        let faceRequest = VNDetectFaceRectanglesRequest()
        try? handler.perform([faceRequest])
        if let faceCount = faceRequest.results?.count, faceCount > 0 {
            description += "\(faceCount) person\(faceCount > 1 ? "s" : "") detected. "
        }
        
        // Text recognition (OCR)
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        try? handler.perform([textRequest])
        if let observations = textRequest.results {
            let extractedText = observations.compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            if !extractedText.isEmpty {
                description += "Text found: \(extractedText.prefix(200)). "
            }
        }
        
        return AudioDescription(
            documentID: document.id,
            documentName: document.name,
            description: description,
            timestamp: document.createdAt,
            audioData: nil // Pure description, will be synthesized later
        )
    }
    
    /// Convert video to audio (extract audio + describe visuals)
    private func convertVideoToAudio(_ data: Data, document: Document) async -> AudioDescription? {
        var description = "Video: \(document.name). "
        
        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        do {
            try data.write(to: tempURL)
            
            // Extract audio track (modern async API)
            let asset = AVURLAsset(url: tempURL)
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            
            if !audioTracks.isEmpty {
                description += "Contains audio. "
            } else {
                description += "Silent video. "
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("    Video processing error: \(error)")
        }
        
        return AudioDescription(
            documentID: document.id,
            documentName: document.name,
            description: description,
            timestamp: document.createdAt,
            audioData: data // Original video data
        )
    }
    
    /// Extract audio content directly
    private func extractAudioContent(_ data: Data, document: Document) async -> AudioDescription? {
        return AudioDescription(
            documentID: document.id,
            documentName: document.name,
            description: "Audio: \(document.name). ",
            timestamp: document.createdAt,
            audioData: data
        )
    }
    
    /// Convert text/PDF to audio description
    private func convertTextToAudioDescription(_ data: Data, document: Document) async -> AudioDescription? {
        var description = "Document: \(document.name). "
        
        if let text = String(data: data, encoding: .utf8) {
            let preview = text.prefix(500)
            description += "Content: \(preview). "
        }
        
        return AudioDescription(
            documentID: document.id,
            documentName: document.name,
            description: description,
            timestamp: document.createdAt,
            audioData: nil
        )
    }
    
    // MARK: - Step 2: Audio Transcription
    
    private func transcribeAllAudio(_ descriptions: [AudioDescription]) async -> String {
        var combinedText = ""
        
        for (index, desc) in descriptions.enumerated() {
            print("   [\(index + 1)/\(descriptions.count)] Transcribing: \(desc.documentName)")
            
            // Add textual description
            combinedText += desc.description + " "
            
            // If has audio data, transcribe it
            if let audioData = desc.audioData {
                if let transcription = await transcribeAudio(audioData) {
                    combinedText += "Audio content: \(transcription). "
                }
            }
        }
        
        return combinedText
    }
    
    private func transcribeAudio(_ data: Data) async -> String? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            return nil
        }
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard recognizer?.isAvailable == true else {
            return nil
        }
        
        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        do {
            try data.write(to: tempURL)
            
            let request = SFSpeechURLRecognitionRequest(url: tempURL)
            request.shouldReportPartialResults = false
            
            let transcription: String = try await withCheckedThrowingContinuation { continuation in
                recognizer?.recognitionTask(with: request) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let result = result, result.isFinal {
                        continuation.resume(returning: result.bestTranscription.formattedString)
                    }
                }
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
            return transcription
            
        } catch {
            print("    Transcription error: \(error)")
            return nil
        }
    }
    
    // MARK: - Step 3: Intelligence Analysis
    
    private func analyzeTranscriptForIntel(_ transcript: String, documents: [Document]) async -> IntelligenceAnalysis {
        print("   🧠 Analyzing combined transcript...")
        
        var analysis = IntelligenceAnalysis()
        
        // Extract entities using NaturalLanguage
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = transcript
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]
        
        tagger.enumerateTags(in: transcript.startIndex..<transcript.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, tags.contains(tag) {
                let entity = String(transcript[tokenRange])
                analysis.entities.insert(entity)
            }
            return true
        }
        
        // Extract key topics
        analysis.topics = extractTopics(from: transcript)
        
        // Detect patterns
        analysis.patterns = detectPatterns(in: transcript, documents: documents)
        
        // Extract timeline
        analysis.timeline = extractTimeline(from: documents)
        
        // Generate insights
        analysis.insights = generateInsights(from: transcript, entities: analysis.entities, topics: analysis.topics)
        
        return analysis
    }
    
    private func extractTopics(from text: String) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var topics: [String: Int] = [:]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if tag == .noun {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 4 {
                    topics[word, default: 0] += 1
                }
            }
            return true
        }
        
        // Return top topics
        return Set(topics.sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key.capitalized })
    }
    
    private func detectPatterns(in text: String, documents: [Document]) -> [String] {
        var patterns: [String] = []
        
        let lowercased = text.lowercased()
        
        // Legal patterns
        if lowercased.contains("lawsuit") || lowercased.contains("court") || lowercased.contains("legal") {
            patterns.append("Legal proceedings detected")
        }
        
        // Medical patterns
        if lowercased.contains("medical") || lowercased.contains("patient") || lowercased.contains("doctor") {
            patterns.append("Medical documentation present")
        }
        
        // Temporal patterns
        let timeline = extractTimeline(from: documents)
        if timeline.count > 5 {
            patterns.append("Extended timeline spanning multiple events")
        }
        
        return patterns
    }
    
    private func extractTimeline(from documents: [Document]) -> [(Date, String)] {
        return documents.map { ($0.createdAt, $0.name) }
            .sorted { $0.0 < $1.0 }
    }
    
    private func generateInsights(from text: String, entities: Set<String>, topics: Set<String>) -> [String] {
        var insights: [String] = []
        
        if !entities.isEmpty {
            insights.append("\(entities.count) key entities identified across documents")
        }
        
        if !topics.isEmpty {
            insights.append("Primary themes: \(topics.prefix(3).joined(separator: ", "))")
        }
        
        if text.count > 5000 {
            insights.append("Substantial content volume requiring detailed review")
        }
        
        return insights
    }
    
    // MARK: - Step 4: Debrief Generation
    
    private func generateDebriefNarrative(_ intelligence: IntelligenceAnalysis) -> String {
        var debrief = ""
        
        // Opening
        if !intelligence.entities.isEmpty {
            let entities = Array(intelligence.entities.prefix(5))
            debrief += "Intelligence debrief. Key figures: \(entities.joined(separator: ", ")). "
        } else {
            debrief += "Intelligence debrief. "
        }
        
        // Topics
        if !intelligence.topics.isEmpty {
            let topics = Array(intelligence.topics.prefix(5))
            debrief += "Primary subjects: \(topics.joined(separator: ", ")). "
        }
        
        // Patterns
        if !intelligence.patterns.isEmpty {
            debrief += intelligence.patterns.joined(separator: ". ") + ". "
        }
        
        // Timeline
        if intelligence.timeline.count > 1 {
            let timespan = calculateTimespan(intelligence.timeline)
            debrief += "Timeline spans \(timespan). "
            
            if let first = intelligence.timeline.first, let last = intelligence.timeline.last {
                debrief += "From \(first.0.formatted(date: .abbreviated, time: .omitted)) "
                debrief += "to \(last.0.formatted(date: .abbreviated, time: .omitted)). "
            }
        }
        
        // Insights
        if !intelligence.insights.isEmpty {
            debrief += intelligence.insights.joined(separator: ". ") + ". "
        }
        
        return debrief
    }
    
    private func calculateTimespan(_ timeline: [(Date, String)]) -> String {
        guard let first = timeline.first?.0, let last = timeline.last?.0 else {
            return "unknown duration"
        }
        
        let components = Calendar.current.dateComponents([.day, .hour], from: first, to: last)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        
        return "less than an hour"
    }
    
    // MARK: - Step 5: Text to Audio Conversion
    
    private func convertTextToAudio(_ text: String) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("intel_debrief_\(UUID().uuidString).m4a")
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try audioSession.setActive(true)
        
        // Create audio recorder
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let recorder = try AVAudioRecorder(url: outputURL, settings: audioSettings)
        recorder.prepareToRecord()
        recorder.record()
        
        // Synthesize speech
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
        
        // Wait for speech to finish
        while speechSynthesizer.isSpeaking {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        recorder.stop()
        try audioSession.setActive(false)
        
        return outputURL
    }
    
    // MARK: - Data Models
    
    struct AudioDescription {
        let documentID: UUID
        let documentName: String
        let description: String
        let timestamp: Date
        let audioData: Data?
    }
    
    struct IntelligenceAnalysis {
        var entities: Set<String> = []
        var topics: Set<String> = []
        var patterns: [String] = []
        var timeline: [(Date, String)] = []
        var insights: [String] = []
    }
}

// MARK: - Errors

enum AudioIntelError: LocalizedError {
    case insufficientDocuments
    case conversionFailed
    case transcriptionFailed
    case analysisFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientDocuments:
            return "At least 2 documents required for Intel Report"
        case .conversionFailed:
            return "Failed to convert media to audio"
        case .transcriptionFailed:
            return "Failed to transcribe audio content"
        case .analysisFailed:
            return "Failed to analyze intelligence"
        }
    }
}

