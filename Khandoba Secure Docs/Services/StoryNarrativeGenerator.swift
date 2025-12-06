//
//  StoryNarrativeGenerator.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//
//  Generates cinematic story-based narratives from media content
//  using Vision, Speech, and NaturalLanguage frameworks with
//  Three-Act Structure and Hero's Journey narrative frameworks.
//

import Foundation
import Vision
import Speech
import NaturalLanguage
import AVFoundation
import UIKit
import CoreLocation
import SwiftData
import Combine

@MainActor
final class StoryNarrativeGenerator: ObservableObject {
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Story Generation
    
    /// Generate cinematic story-based narrative from documents
    func generateStoryNarrative(from documents: [Document]) async -> String {
        isGenerating = true
        defer { isGenerating = false }
        
        print(" Analyzing \(documents.count) documents for story...")
        
        // Step 1: Analyze all media content
        generationProgress = 0.1
        let mediaInsights = await analyzeAllMedia(documents)
        print(" Step 1: Media analysis complete (\(mediaInsights.count) insights)")
        
        // Step 2: Extract story elements
        generationProgress = 0.3
        let storyElements = await extractStoryElements(from: mediaInsights, documents: documents)
        print(" Step 2: Story elements extracted")
        print("   Characters: \(storyElements.characters.count)")
        print("   Settings: \(storyElements.settings.count)")
        print("   Events: \(storyElements.events.count)")
        
        // Step 3: Build chronological timeline
        generationProgress = 0.5
        let timeline = buildTimeline(from: storyElements.events)
        print(" Step 3: Timeline built (\(timeline.count) events)")
        
        // Step 4: Identify narrative arc
        generationProgress = 0.7
        let narrativeArc = identifyNarrativeArc(timeline: timeline, elements: storyElements)
        print(" Step 4: Narrative arc identified")
        
        // Step 5: Generate cinematic narrative
        generationProgress = 0.9
        let narrative = generateCinematicNarrative(
            arc: narrativeArc,
            elements: storyElements,
            timeline: timeline
        )
        print(" Step 5: Cinematic narrative generated")
        print("   Length: \(narrative.count) characters")
        
        generationProgress = 1.0
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(" Story narrative generation complete!")
        
        return narrative
    }
    
    // MARK: - Media Analysis
    
    /// Analyze all media content using Vision and Speech frameworks
    private func analyzeAllMedia(_ documents: [Document]) async -> [MediaInsight] {
        var insights: [MediaInsight] = []
        
        for document in documents {
            guard let data = document.encryptedFileData else { continue }
            
            switch document.documentType {
            case "image":
                if let insight = await analyzeImage(data: data, document: document) {
                    insights.append(insight)
                }
            case "video":
                if let insight = await analyzeVideo(data: data, document: document) {
                    insights.append(insight)
                }
            case "audio":
                if let insight = await analyzeAudio(data: data, document: document) {
                    insights.append(insight)
                }
            default:
                break
            }
        }
        
        return insights
    }
    
    /// Analyze image using Vision framework
    private func analyzeImage(data: Data, document: Document) async -> MediaInsight? {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else { return nil }
        
        var insight = MediaInsight(
            documentID: document.id,
            mediaType: "image",
            timestamp: document.createdAt
        )
        
        // Scene classification
        let sceneRequest = VNClassifyImageRequest()
        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([sceneRequest])
        if let results = sceneRequest.results?.prefix(3) {
            insight.scenes = results.map { "\($0.identifier) (\(Int($0.confidence * 100))%)" }
        }
        
        // Face detection (characters)
        let faceRequest = VNDetectFaceRectanglesRequest()
        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([faceRequest])
        insight.faceCount = faceRequest.results?.count ?? 0
        
        // Text recognition (OCR)
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([textRequest])
        
        if let observations = textRequest.results {
            let recognizedText = observations.compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            if !recognizedText.isEmpty {
                insight.extractedText = recognizedText
                
                // Extract names, places, orgs from OCR text
                insight.entities = extractEntities(from: recognizedText)
            }
        }
        
        // Extract location from image metadata/tags
        if let location = document.aiTags.first(where: { $0.hasPrefix("Location:") }) {
            insight.location = location.replacingOccurrences(of: "Location: ", with: "")
        }
        
        print("   📸 Image analyzed: \(insight.scenes.joined(separator: ", "))")
        if insight.faceCount > 0 {
            print("       Faces: \(insight.faceCount)")
        }
        if let text = insight.extractedText, !text.isEmpty {
            print("      📝 OCR: \(text.prefix(50))...")
        }
        
        return insight
    }
    
    /// Analyze video using Vision + Speech
    private func analyzeVideo(data: Data, document: Document) async -> MediaInsight? {
        guard data.count < 50 * 1024 * 1024 else {  // Skip videos > 50MB
            print("    Video too large, skipping deep analysis")
            return nil
        }
        
        var insight = MediaInsight(
            documentID: document.id,
            mediaType: "video",
            timestamp: document.createdAt
        )
        
        // Save to temp file for processing
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        do {
            try data.write(to: tempURL)
            
            // Extract first frame for scene analysis
            let asset = AVURLAsset(url: tempURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            do {
                let imageResult = try await imageGenerator.image(at: time)
                let cgImage = imageResult.image
                // Analyze first frame
                let sceneRequest = VNClassifyImageRequest()
                try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([sceneRequest])
                if let results = sceneRequest.results?.prefix(3) {
                    insight.scenes = results.map { $0.identifier }
                }
            } catch {
                print("    Failed to extract video frame: \(error.localizedDescription)")
            }
            
            // Transcribe audio from video
            if let transcription = await transcribeAudioFromVideo(url: tempURL) {
                insight.extractedText = transcription
                insight.entities = extractEntities(from: transcription)
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
            print("   Video analyzed: \(insight.scenes.joined(separator: ", "))")
            if let text = insight.extractedText {
                print("      Transcription: \(text.prefix(50))...")
            }
            
        } catch {
            print("   Video analysis error: \(error)")
        }
        
        return insight
    }
    
    /// Analyze audio using Speech framework
    private func analyzeAudio(data: Data, document: Document) async -> MediaInsight? {
        var insight = MediaInsight(
            documentID: document.id,
            mediaType: "audio",
            timestamp: document.createdAt
        )
        
        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        do {
            try data.write(to: tempURL)
            
            // Transcribe audio
            if let transcription = await transcribeAudio(url: tempURL) {
                insight.extractedText = transcription
                insight.entities = extractEntities(from: transcription)
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
            print("    Audio analyzed")
            if let text = insight.extractedText {
                print("      Transcription: \(text.prefix(50))...")
            }
            
        } catch {
            print("   Audio analysis error: \(error)")
        }
        
        return insight
    }
    
    /// Transcribe audio using Speech framework
    private func transcribeAudio(url: URL) async -> String? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("       Speech recognition not authorized")
            return nil
        }
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard recognizer?.isAvailable == true else {
            print("       Speech recognizer not available")
            return nil
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        return try? await withCheckedThrowingContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let error = error {
                    print("       Transcription error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                } else if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    /// Transcribe audio from video
    private func transcribeAudioFromVideo(url: URL) async -> String? {
        // Extract audio from video first
        let asset = AVURLAsset(url: url)
        
        // Check if video has audio track
        let audioTracks = try? await asset.loadTracks(withMediaType: .audio)
        guard let audioTracks = audioTracks, !audioTracks.isEmpty else {
            return nil
        }
        
        // Use same transcription method
        return await transcribeAudio(url: url)
    }
    
    /// Extract entities (people, places, organizations) from text using NaturalLanguage
    private func extractEntities(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, tags.contains(tag) {
                let entity = String(text[tokenRange])
                entities.append(entity)
            }
            return true
        }
        
        return Array(Set(entities))  // Remove duplicates
    }
    
    // MARK: - Story Element Extraction
    
    /// Extract story elements from media insights and documents
    private func extractStoryElements(from insights: [MediaInsight], documents: [Document]) async -> StoryElements {
        var elements = StoryElements()
        
        // Extract characters (people)
        var characters = Set<String>()
        for insight in insights {
            for entity in insight.entities {
                // People's names
                characters.insert(entity)
            }
            // Add face count as unnamed characters
            if insight.faceCount > 0 {
                for i in 1...insight.faceCount {
                    characters.insert("Person \(i)")
                }
            }
        }
        elements.characters = Array(characters)
        
        // Extract settings (locations, times)
        var settings = Set<String>()
        for insight in insights {
            if let location = insight.location {
                settings.insert(location)
            }
            for scene in insight.scenes {
                if scene.contains("indoor") || scene.contains("outdoor") || scene.contains("office") || scene.contains("street") {
                    settings.insert(scene)
                }
            }
        }
        elements.settings = Array(settings)
        
        // Build events from insights
        for insight in insights {
            let event = Event(
                date: insight.timestamp,
                location: insight.location,
                description: buildEventDescription(from: insight),
                mediaType: insight.mediaType,
                participants: insight.entities,
                significance: calculateSignificance(insight)
            )
            elements.events.append(event)
        }
        
        // Detect conflicts (legal terms, medical issues, negative sentiment)
        var conflicts = Set<String>()
        for insight in insights {
            if let text = insight.extractedText {
                let detectedConflicts = detectConflicts(in: text)
                conflicts.formUnion(detectedConflicts)
            }
        }
        elements.conflicts = Array(conflicts)
        
        // Detect resolutions (positive outcomes, agreements)
        var resolutions = Set<String>()
        for insight in insights {
            if let text = insight.extractedText {
                let detectedResolutions = detectResolutions(in: text)
                resolutions.formUnion(detectedResolutions)
            }
        }
        elements.resolutions = Array(resolutions)
        
        // Extract themes from all text
        let allText = insights.compactMap { $0.extractedText }.joined(separator: " ")
        elements.themes = extractThemes(from: allText)
        
        return elements
    }
    
    /// Build event description from media insight
    private func buildEventDescription(from insight: MediaInsight) -> String {
        var parts: [String] = []
        
        // Scene description
        if !insight.scenes.isEmpty {
            parts.append(insight.scenes.first ?? "scene")
        }
        
        // Participants
        if !insight.entities.isEmpty {
            parts.append("featuring \(insight.entities.prefix(2).joined(separator: ", "))")
        } else if insight.faceCount > 0 {
            parts.append("with \(insight.faceCount) people")
        }
        
        // Text content hint
        if let text = insight.extractedText, text.count > 20 {
            let preview = text.prefix(40)
            parts.append("mentioning \"\(preview)...\"")
        }
        
        return parts.joined(separator: ", ")
    }
    
    /// Calculate event significance (0-1)
    private func calculateSignificance(_ insight: MediaInsight) -> Double {
        var score = 0.5  // Base significance
        
        // More entities = more significant
        score += Double(min(insight.entities.count, 5)) * 0.05
        
        // Text content = more significant
        if let text = insight.extractedText, text.count > 100 {
            score += 0.15
        }
        
        // Faces = more significant
        score += Double(min(insight.faceCount, 5)) * 0.04
        
        return min(score, 1.0)
    }
    
    /// Detect conflicts in text (legal disputes, medical issues, problems)
    private func detectConflicts(in text: String) -> Set<String> {
        var conflicts = Set<String>()
        
        let conflictKeywords = [
            "dispute", "lawsuit", "breach", "violation", "conflict",
            "emergency", "urgent", "critical", "crisis", "issue",
            "problem", "complication", "disagreement", "tension"
        ]
        
        let lowercased = text.lowercased()
        for keyword in conflictKeywords {
            if lowercased.contains(keyword) {
                conflicts.insert(keyword.capitalized)
            }
        }
        
        return conflicts
    }
    
    /// Detect resolutions in text (agreements, solutions, positive outcomes)
    private func detectResolutions(in text: String) -> Set<String> {
        var resolutions = Set<String>()
        
        let resolutionKeywords = [
            "agreement", "settlement", "resolved", "solution", "signed",
            "approved", "complete", "success", "achieved", "improved",
            "recovery", "progress", "positive", "resolved"
        ]
        
        let lowercased = text.lowercased()
        for keyword in resolutionKeywords {
            if lowercased.contains(keyword) {
                resolutions.insert(keyword.capitalized)
            }
        }
        
        return resolutions
    }
    
    /// Extract themes using NaturalLanguage
    private func extractThemes(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var nouns: [String: Int] = [:]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if tag == .noun {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 4 {  // Only meaningful words
                    nouns[word, default: 0] += 1
                }
            }
            return true
        }
        
        // Return top 5 most frequent themes
        return nouns.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key.capitalized }
    }
    
    // MARK: - Timeline Building
    
    /// Build chronological timeline of events
    private func buildTimeline(from events: [Event]) -> [Event] {
        return events.sorted { $0.date < $1.date }
    }
    
    // MARK: - Narrative Arc Identification
    
    /// Identify narrative arc using Three-Act Structure
    private func identifyNarrativeArc(timeline: [Event], elements: StoryElements) -> NarrativeArc {
        let totalEvents = timeline.count
        
        // Divide into acts based on chronology
        let act1End = Int(Double(totalEvents) * 0.25)
        let act2End = Int(Double(totalEvents) * 0.75)
        
        let act1Events = Array(timeline.prefix(act1End))
        let act2Events = Array(timeline[act1End..<min(act2End, totalEvents)])
        let act3Events = Array(timeline[act2End..<totalEvents])
        
        return NarrativeArc(
            setup: act1Events,
            conflict: act2Events,
            resolution: act3Events,
            hasConflict: !elements.conflicts.isEmpty,
            hasResolution: !elements.resolutions.isEmpty
        )
    }
    
    // MARK: - Cinematic Narrative Generation
    
    /// Generate engaging cinematic narrative using story structure
    private func generateCinematicNarrative(
        arc: NarrativeArc,
        elements: StoryElements,
        timeline: [Event]
    ) -> String {
        var narrative = ""
        
        // Opening (Hook the audience) - NO newlines between sections
        narrative += generateOpening(elements: elements, timeline: timeline)
        narrative += " "
        
        // Act 1: Setup (Introduce world, characters, setting)
        if !arc.setup.isEmpty {
            narrative += generateActOne(events: arc.setup, elements: elements)
            narrative += " "
        }
        
        // Act 2: Conflict (Rising action, complications)
        if !arc.conflict.isEmpty || arc.hasConflict {
            narrative += generateActTwo(events: arc.conflict, elements: elements)
            narrative += " "
        }
        
        // Act 3: Resolution (Climax and denouement)
        if !arc.resolution.isEmpty || arc.hasResolution {
            narrative += generateActThree(events: arc.resolution, elements: elements)
            narrative += " "
        }
        
        // Closing (Reflection and themes)
        narrative += generateClosing(elements: elements, timeline: timeline)
        
        return narrative
    }
    
    /// Generate opening hook (like a movie opening)
    private func generateOpening(elements: StoryElements, timeline: [Event]) -> String {
        let timespan = calculateTimespan(timeline)
        let primarySetting = elements.settings.first ?? "your documents"
        
        var opening = ""
        
        // Cinematic opening (no meta info)
        if elements.conflicts.count > 0 {
            opening += "A story of tension unfolds"
        } else if elements.characters.count > 3 {
            opening += "Threads of connection emerge"
        } else {
            opening += "A narrative takes shape"
        }
        
        if !timespan.isEmpty {
            opening += " over \(timespan)"
        }
        
        opening += " in \(primarySetting). "
        
        return opening
    }
    
    /// Generate Act 1: Setup
    private func generateActOne(events: [Event], elements: StoryElements) -> String {
        var text = ""
        
        if let firstEvent = events.first {
            // No "our story opens" - just describe
            text += "On \(formatDate(firstEvent.date)), "
            
            // Describe the scene
            if !firstEvent.description.isEmpty {
                text += "\(firstEvent.description.lowercased()). "
            }
        }
        
        // Introduce characters (no "our cast")
        if !elements.characters.isEmpty {
            text += "Key figures: "
            text += elements.characters.prefix(3).joined(separator: ", ")
            if elements.characters.count > 3 {
                text += ", among others"
            }
            text += ". "
        }
        
        // Establish setting
        if elements.settings.count > 0 {
            text += "The stage is set across \(elements.settings.count) locations—"
            text += elements.settings.prefix(2).joined(separator: ", ")
            text += ". "
        }
        
        return text
    }
    
    /// Generate Act 2: Conflict
    private func generateActTwo(events: [Event], elements: StoryElements) -> String {
        var text = ""
        
        if !elements.conflicts.isEmpty {
            text += "Tension builds as \(elements.conflicts.first!.lowercased()) emerges. "
            text += "Complications arise. "
        } else {
            text += "Events unfold in succession. "
        }
        
        // Describe key midpoint events (remove "turning point" meta)
        if events.count > 0 {
            let midpoint = events.count / 2
            if let midEvent = events[safe: midpoint] {
                text += "On \(formatDate(midEvent.date)), "
                if !midEvent.description.isEmpty {
                    text += "\(midEvent.description.lowercased()). "
                } else {
                    text += "a significant shift occurs. "
                }
            }
        }
        
        // Build suspense (no "storylines interweave" meta)
        if elements.conflicts.count > 1 {
            text += "Layered complexities: \(elements.conflicts.prefix(2).joined(separator: ", ")). "
        }
        
        return text
    }
    
    /// Generate Act 3: Resolution
    private func generateActThree(events: [Event], elements: StoryElements) -> String {
        var text = ""
        
        if !elements.resolutions.isEmpty {
            text += "\(elements.resolutions.first!.capitalized) brings closure. "
        } else if let lastEvent = events.last {
            text += "As of \(formatDate(lastEvent.date)), the situation stands. "
        }
        
        // Climax description (no "climactic moment" meta)
        if let significantEvent = events.max(by: { $0.significance < $1.significance }) {
            text += "\(significantEvent.description.capitalized). "
        }
        
        // Denouement (no "threads" meta)
        if !elements.resolutions.isEmpty && elements.resolutions.count > 1 {
            text += "Resolution on multiple fronts: \(elements.resolutions.joined(separator: ", ")). "
        }
        
        return text
    }
    
    /// Generate closing reflection
    private func generateClosing(elements: StoryElements, timeline: [Event]) -> String {
        var closing = ""
        
        if !elements.themes.isEmpty {
            closing += "The central theme: \(elements.themes.first!.lowercased()). "
        }
        
        // Remove all meta references (epilogue, narrative arc, cinema)
        if elements.conflicts.count > 0 && elements.resolutions.count > 0 {
            closing += "From complication to resolution, the pattern is clear."
        } else {
            closing += "The story continues."
        }
        
        return closing
    }
    
    // MARK: - Helper Methods
    
    /// Calculate timespan between first and last event
    private func calculateTimespan(_ timeline: [Event]) -> String {
        guard let first = timeline.first, let last = timeline.last else {
            return ""
        }
        
        let days = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
        
        if days < 1 {
            return "a single day"
        } else if days == 1 {
            return "two days"
        } else if days < 7 {
            return "\(days) days"
        } else if days < 14 {
            return "one week"
        } else if days < 30 {
            return "\(days / 7) weeks"
        } else if days < 60 {
            return "one month"
        } else {
            return "\(days / 30) months"
        }
    }
    
    /// Format date for narrative
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct MediaInsight {
    let documentID: UUID
    let mediaType: String  // "image", "video", "audio"
    let timestamp: Date
    var scenes: [String] = []
    var faceCount: Int = 0
    var extractedText: String?
    var entities: [String] = []
    var location: String?
}

struct StoryElements {
    var characters: [String] = []
    var settings: [String] = []
    var events: [Event] = []
    var conflicts: [String] = []
    var resolutions: [String] = []
    var themes: [String] = []
}

struct Event {
    let date: Date
    let location: String?
    let description: String
    let mediaType: String
    let participants: [String]
    let significance: Double  // 0-1
}

struct NarrativeArc {
    let setup: [Event]        // Act 1: First 25%
    let conflict: [Event]      // Act 2: Middle 50%
    let resolution: [Event]    // Act 3: Final 25%
    let hasConflict: Bool
    let hasResolution: Bool
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

