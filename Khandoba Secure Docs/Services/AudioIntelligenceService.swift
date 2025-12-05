//
//  AudioIntelligenceService.swift
//  Khandoba Secure Docs
//
//  Created by AI Assistant on 12/5/25.
//
//  Analyzes audio files and generates intelligence debriefs
//

import Foundation
import Speech
import NaturalLanguage
import AVFoundation
import Combine

@MainActor
final class AudioIntelligenceService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var currentReport: AudioIntelReport?
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    /// Main analysis function - converts audio to intelligence debrief
    func analyzeAndGenerateDebrief(audioFiles: [(url: URL, document: Document)]) async throws -> URL {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        print("🧠 Analyzing \(audioFiles.count) audio files...")
        
        // Phase 1: Transcribe all audio
        analysisProgress = 0.1
        var transcripts: [Transcript] = []
        
        for (index, audioFile) in audioFiles.enumerated() {
            print("   Transcribing \(index + 1)/\(audioFiles.count): \(audioFile.document.name)")
            
            if let transcript = await transcribeAudio(audioFile.url, document: audioFile.document) {
                transcripts.append(transcript)
            }
            
            analysisProgress = 0.1 + (Double(index + 1) / Double(audioFiles.count)) * 0.4
        }
        
        print("✅ Transcribed \(transcripts.count) audio files")
        
        // Phase 2: Extract entities
        analysisProgress = 0.5
        let entities = extractEntities(from: transcripts)
        print("✅ Extracted \(entities.count) entities")
        
        // Phase 3: Detect patterns
        analysisProgress = 0.6
        let patterns = detectPatterns(in: transcripts, entities: entities)
        print("✅ Detected \(patterns.count) patterns")
        
        // Phase 4: Build timeline
        analysisProgress = 0.7
        let timeline = buildTimeline(from: audioFiles.map { $0.document })
        print("✅ Built timeline with \(timeline.count) events")
        
        // Phase 5: Generate insights
        analysisProgress = 0.8
        let insights = generateInsights(
            transcripts: transcripts,
            entities: entities,
            patterns: patterns,
            timeline: timeline
        )
        print("✅ Generated \(insights.count) insights")
        
        // Phase 6: Create debrief narrative
        analysisProgress = 0.9
        let debriefText = createDebriefNarrative(
            transcripts: transcripts,
            entities: entities,
            patterns: patterns,
            insights: insights,
            timeline: timeline
        )
        
        print("📝 Debrief: \(debriefText.count) characters")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(debriefText)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Phase 7: Convert to audio
        let debriefURL = try await convertToAudio(text: debriefText)
        
        analysisProgress = 1.0
        
        // Create report object
        currentReport = AudioIntelReport(
            sourceDocuments: audioFiles.map { $0.document },
            transcripts: transcripts,
            entities: entities,
            patterns: patterns,
            insights: insights,
            debriefURL: debriefURL,
            debriefTranscript: debriefText
        )
        
        print("✅ Audio Intel Report complete!")
        return debriefURL
    }
    
    // MARK: - Transcription
    
    private func transcribeAudio(_ url: URL, document: Document) async -> Transcript? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("   ⚠️ Speech recognition not authorized")
            return nil
        }
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard recognizer?.isAvailable == true else {
            print("   ⚠️ Speech recognizer not available")
            return nil
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        return await withCheckedContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let error = error {
                    print("   ❌ Transcription error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                } else if let result = result {
                    let transcript = Transcript(
                        documentID: document.id,
                        documentName: document.name,
                        text: result.bestTranscription.formattedString,
                        duration: 0.0, // Calculate if needed
                        confidence: 1.0,
                        timestamp: document.createdAt
                    )
                    continuation.resume(returning: transcript)
                }
            }
        }
    }
    
    // MARK: - Entity Extraction
    
    private func extractEntities(from transcripts: [Transcript]) -> [Entity] {
        var entityDict: [String: Entity] = [:]
        
        for transcript in transcripts {
            let tagger = NLTagger(tagSchemes: [.nameType])
            tagger.string = transcript.text
            
            let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
            let tags: [NLTag] = [.personalName, .placeName, .organizationName]
            
            tagger.enumerateTags(in: transcript.text.startIndex..<transcript.text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
                if let tag = tag, tags.contains(tag) {
                    let entity = String(transcript.text[tokenRange])
                    let entityType: EntityType = tag == .personalName ? .person :
                                                tag == .placeName ? .location : .organization
                    
                    let key = "\(entityType.rawValue):\(entity)"
                    
                    if var existing = entityDict[key] {
                        existing.frequency += 1
                        existing.documentIDs.append(transcript.documentID)
                        entityDict[key] = existing
                    } else {
                        entityDict[key] = Entity(
                            type: entityType,
                            value: entity,
                            frequency: 1,
                            documentIDs: [transcript.documentID]
                        )
                    }
                }
                return true
            }
        }
        
        return Array(entityDict.values).sorted { $0.frequency > $1.frequency }
    }
    
    // MARK: - Pattern Detection
    
    private func detectPatterns(in transcripts: [Transcript], entities: [Entity]) -> [Pattern] {
        var patterns: [Pattern] = []
        
        // Pattern 1: Recurring entities across documents
        let recurringEntities = entities.filter { $0.frequency >= 2 }
        for entity in recurringEntities {
            patterns.append(Pattern(
                type: .recurringEntity,
                description: "\(entity.value) appears in \(entity.frequency) documents",
                significance: min(Double(entity.frequency) / Double(transcripts.count), 1.0),
                documentIDs: entity.documentIDs
            ))
        }
        
        // Pattern 2: Common themes
        let allText = transcripts.map { $0.text }.joined(separator: " ")
        let themes = extractThemes(from: allText)
        for theme in themes.prefix(5) {
            patterns.append(Pattern(
                type: .commonTheme,
                description: "Theme: \(theme)",
                significance: 0.7,
                documentIDs: transcripts.map { $0.documentID }
            ))
        }
        
        // Pattern 3: Temporal patterns (if documents span time)
        if let earliest = transcripts.min(by: { $0.timestamp < $1.timestamp }),
           let latest = transcripts.max(by: { $0.timestamp < $1.timestamp }) {
            let timeSpan = latest.timestamp.timeIntervalSince(earliest.timestamp)
            if timeSpan > 86400 { // More than 1 day
                let days = Int(timeSpan / 86400)
                patterns.append(Pattern(
                    type: .temporal,
                    description: "Documents span \(days) days showing progression",
                    significance: 0.8,
                    documentIDs: transcripts.map { $0.documentID }
                ))
            }
        }
        
        return patterns.sorted { $0.significance > $1.significance }
    }
    
    private func extractThemes(from text: String) -> [String] {
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
        
        return nouns.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key.capitalized }
    }
    
    // MARK: - Timeline Building
    
    private func buildTimeline(from documents: [Document]) -> [TimelineEvent] {
        return documents
            .sorted { $0.createdAt < $1.createdAt }
            .map { doc in
                TimelineEvent(
                    date: doc.createdAt,
                    documentName: doc.name,
                    documentType: doc.documentType
                )
            }
    }
    
    // MARK: - Insight Generation
    
    private func generateInsights(
        transcripts: [Transcript],
        entities: [Entity],
        patterns: [Pattern],
        timeline: [TimelineEvent]
    ) -> [String] {
        var insights: [String] = []
        
        // Insight from entities
        if let topEntity = entities.first, topEntity.frequency >= 2 {
            insights.append("\(topEntity.value) is mentioned in \(topEntity.frequency) documents, indicating significance")
        }
        
        // Insight from patterns
        for pattern in patterns.prefix(3) where pattern.significance > 0.6 {
            insights.append(pattern.description)
        }
        
        // Insight from timeline
        if timeline.count >= 3 {
            insights.append("Documents show chronological progression over \(timeline.count) events")
        }
        
        // Document type diversity
        let types = Set(timeline.map { $0.documentType })
        if types.count >= 3 {
            insights.append("Multi-modal evidence across \(types.count) media types strengthens analysis")
        }
        
        return insights
    }
    
    // MARK: - Debrief Narrative
    
    private func createDebriefNarrative(
        transcripts: [Transcript],
        entities: [Entity],
        patterns: [Pattern],
        insights: [String],
        timeline: [TimelineEvent]
    ) -> String {
        var narrative = ""
        
        // Opening
        narrative += "Intelligence debrief for \(transcripts.count) documents. "
        
        // Key entities
        if !entities.isEmpty {
            let topEntities = entities.prefix(3).map { $0.value }
            narrative += "Key references: \(topEntities.joined(separator: ", ")). "
        }
        
        // Timeline
        if let first = timeline.first, let last = timeline.last {
            let span = last.date.timeIntervalSince(first.date)
            if span > 0 {
                let days = Int(span / 86400)
                if days > 0 {
                    narrative += "Timeline spans \(days) days from \(first.date.formatted(date: .abbreviated, time: .omitted)) to \(last.date.formatted(date: .abbreviated, time: .omitted)). "
                }
            }
        }
        
        // Patterns
        for pattern in patterns.prefix(2) where pattern.significance > 0.6 {
            narrative += "\(pattern.description). "
        }
        
        // Insights
        for insight in insights.prefix(3) {
            narrative += "\(insight). "
        }
        
        // Closing with recommendation
        narrative += "Recommendation: Review these documents together for complete context."
        
        return narrative
    }
    
    // MARK: - Audio Generation
    
    private func convertToAudio(text: String) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("intel_debrief_\(UUID().uuidString)")
            .appendingPathExtension("m4a")
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.50
        utterance.volume = 1.0
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try audioSession.setActive(true)
        
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let recorder = try AVAudioRecorder(url: outputURL, settings: audioSettings)
        recorder.prepareToRecord()
        recorder.record()
        
        speechSynthesizer.speak(utterance)
        
        while speechSynthesizer.isSpeaking {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        recorder.stop()
        try audioSession.setActive(false)
        
        // Verify file was created
        let fileSize = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? UInt64 ?? 0
        print("📊 Debrief audio: \(fileSize) bytes")
        
        if fileSize < 10000 {
            throw AudioIntelError.debriefGenerationFailed
        }
        
        return outputURL
    }
}

// MARK: - Data Models

struct AudioIntelReport: Identifiable {
    let id = UUID()
    let generatedAt = Date()
    let sourceDocuments: [Document]
    let transcripts: [Transcript]
    let entities: [Entity]
    let patterns: [Pattern]
    let insights: [String]
    let debriefURL: URL
    let debriefTranscript: String
}

struct Transcript: Identifiable {
    let id = UUID()
    let documentID: UUID
    let documentName: String
    let text: String
    let duration: TimeInterval
    let confidence: Double
    let timestamp: Date
}

struct Entity: Identifiable {
    let id = UUID()
    var type: EntityType
    var value: String
    var frequency: Int
    var documentIDs: [UUID]
}

enum EntityType: String {
    case person = "Person"
    case location = "Location"
    case organization = "Organization"
    case date = "Date"
}

struct Pattern: Identifiable {
    let id = UUID()
    let type: PatternType
    let description: String
    let significance: Double // 0.0 to 1.0
    let documentIDs: [UUID]
}

enum PatternType {
    case recurringEntity
    case commonTheme
    case temporal
    case crossReference
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let date: Date
    let documentName: String
    let documentType: String
}

// MARK: - Errors

enum AudioIntelError: LocalizedError {
    case transcriptionFailed
    case debriefGenerationFailed
    case noAudioFiles
    
    var errorDescription: String? {
        switch self {
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .debriefGenerationFailed:
            return "Failed to generate audio debrief"
        case .noAudioFiles:
            return "No audio files provided for analysis"
        }
    }
}

