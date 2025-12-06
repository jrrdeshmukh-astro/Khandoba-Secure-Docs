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
import AVFoundation
import Speech

class NLPTaggingService {
    
    /// Generate intelligent document name based on content using LLAMA-style understanding
    static func generateDocumentName(
        for data: Data,
        mimeType: String?,
        fallbackName: String
    ) async -> String {
        print("🦙 LLAMA: Generating intelligent name for \(mimeType ?? "unknown") file...")
        
        // Use LLAMA-style analysis for better naming
        let llamaDescription = await generateLlamaStyleDescription(
            for: data,
            mimeType: mimeType
        )
        
        // Extract meaningful name from LLAMA description
        if let intelligentName = extractNameFromLlamaDescription(
            llamaDescription,
            mimeType: mimeType,
            fallbackName: fallbackName
        ) {
            print("   ✅ LLAMA name: \(intelligentName)")
            return intelligentName
        }
        
        // Fallback to text-based extraction
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
    
    /// Generate LLAMA-style description for intelligent naming and tagging
    private static func generateLlamaStyleDescription(
        for data: Data,
        mimeType: String?
    ) async -> String {
        guard let mimeType = mimeType else { return "" }
        
        var description = ""
        
        // Image analysis (CLIP-style scene understanding)
        if mimeType.hasPrefix("image/") {
            description = await analyzeImageForLlama(data)
        }
        // Video analysis (Video-LLaMA style)
        else if mimeType.hasPrefix("video/") {
            description = await analyzeVideoForLlama(data)
        }
        // Audio analysis (transcription + context)
        else if mimeType.hasPrefix("audio/") {
            description = await analyzeAudioForLlama(data)
        }
        // Text/PDF analysis
        else if mimeType == "application/pdf" || mimeType.hasPrefix("text/") {
            description = await analyzeTextForLlama(data, mimeType: mimeType)
        }
        
        return description
    }
    
    /// Analyze image using LLAMA-style understanding
    private static func analyzeImageForLlama(_ data: Data) async -> String {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            return ""
        }
        
        var description = ""
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Scene classification (CLIP-style)
        let sceneRequest = VNClassifyImageRequest()
        try? handler.perform([sceneRequest])
        if let results = sceneRequest.results?.prefix(3) {
            let topScenes = results
                .filter { $0.confidence > 0.3 }
                .map { $0.identifier }
            if !topScenes.isEmpty {
                description += "Scene: \(topScenes.joined(separator: ", ")). "
            }
        }
        
        // Face detection
        let faceRequest = VNDetectFaceRectanglesRequest()
        try? handler.perform([faceRequest])
        if let faceCount = faceRequest.results?.count, faceCount > 0 {
            description += "\(faceCount) person\(faceCount > 1 ? "s" : "") present. "
        }
        
        // OCR for document understanding
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        try? handler.perform([textRequest])
        if let observations = textRequest.results, !observations.isEmpty {
            let ocrText = observations.compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            if !ocrText.isEmpty {
                // Extract document type from text
                let lowerText = ocrText.lowercased()
                if lowerText.contains("invoice") || lowerText.contains("bill") {
                    description += "Invoice or bill document. "
                } else if lowerText.contains("receipt") {
                    description += "Receipt document. "
                } else if lowerText.contains("medical") || lowerText.contains("patient") {
                    description += "Medical document. "
                } else if lowerText.contains("contract") || lowerText.contains("agreement") {
                    description += "Legal contract. "
                } else {
                    description += "Document with text: \(ocrText.prefix(50)). "
                }
            }
        }
        
        // Image characteristics
        let aspectRatio = image.size.width / image.size.height
        if aspectRatio > 1.5 {
            description += "Landscape orientation. "
        } else if aspectRatio < 0.7 {
            description += "Portrait orientation. "
        }
        
        return description
    }
    
    /// Analyze video using Video-LLaMA style understanding
    private static func analyzeVideoForLlama(_ data: Data) async -> String {
        var description = ""
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        do {
            try data.write(to: tempURL)
            let asset = AVURLAsset(url: tempURL)
            
            // Duration
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)
            description += "Video duration: \(Int(durationSeconds)) seconds. "
            
            // Audio transcription
            if let transcript = await transcribeAudio(url: tempURL) {
                description += "Audio content: \(transcript.prefix(100)). "
                
                // Infer video purpose from transcript
                let lowerTranscript = transcript.lowercased()
                if lowerTranscript.contains("meeting") {
                    description += "Meeting recording. "
                } else if lowerTranscript.contains("presentation") {
                    description += "Presentation recording. "
                } else if lowerTranscript.contains("note") {
                    description += "Voice note or memo. "
                }
            }
            
            // Frame analysis (start, middle, end)
            if let startFrame = await extractFrame(from: asset, at: 0.0) {
                let frameDesc = await describeImageFrame(data: startFrame)
                if !frameDesc.isEmpty {
                    description += "Opening scene: \(frameDesc). "
                }
            }
            
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            description += "Video file. "
        }
        
        return description
    }
    
    /// Analyze audio using transcription + context
    private static func analyzeAudioForLlama(_ data: Data) async -> String {
        var description = ""
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        do {
            try data.write(to: tempURL)
            let asset = AVURLAsset(url: tempURL)
            
            // Duration
            let duration = try await asset.load(.duration)
            let durationSeconds = CMTimeGetSeconds(duration)
            description += "Audio duration: \(Int(durationSeconds)) seconds. "
            
            // Transcription
            if let transcript = await transcribeAudio(url: tempURL) {
                description += "Content: \(transcript.prefix(150)). "
                
                // Infer purpose from content
                let lowerTranscript = transcript.lowercased()
                if lowerTranscript.contains("meeting") {
                    description += "Meeting recording. "
                } else if lowerTranscript.contains("note to self") || lowerTranscript.contains("reminder") {
                    description += "Personal voice note. "
                } else if lowerTranscript.contains("intel") || lowerTranscript.contains("report") {
                    description += "Intelligence briefing. "
                }
            } else {
                description += "Audio recording. "
            }
            
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            description += "Audio file. "
        }
        
        return description
    }
    
    /// Analyze text/PDF for LLAMA-style understanding
    private static func analyzeTextForLlama(_ data: Data, mimeType: String?) async -> String {
        var description = ""
        
        var text = ""
        if mimeType == "application/pdf" {
            text = PDFTextExtractor.extractFromPDF(data: data)
        } else if let stringText = String(data: data, encoding: .utf8) {
            text = stringText
        }
        
        if !text.isEmpty {
            let preview = text.prefix(200)
            description += "Content preview: \(preview). "
            
            // Extract document type from content
            let lowerText = text.lowercased()
            if lowerText.contains("invoice") || lowerText.contains("bill") {
                description += "Invoice document. "
            } else if lowerText.contains("receipt") {
                description += "Receipt. "
            } else if lowerText.contains("contract") || lowerText.contains("agreement") {
                description += "Legal contract. "
            } else if lowerText.contains("report") {
                description += "Report document. "
            } else if lowerText.contains("medical") || lowerText.contains("patient") {
                description += "Medical document. "
            }
            
            // Extract key entities
            let entities = extractNamedEntities(from: text)
            if !entities.isEmpty {
                description += "Contains: \(entities.prefix(3).joined(separator: ", ")). "
            }
        }
        
        return description
    }
    
    /// Extract meaningful name from LLAMA description
    private static func extractNameFromLlamaDescription(
        _ description: String,
        mimeType: String?,
        fallbackName: String
    ) -> String? {
        guard !description.isEmpty else { return nil }
        
        // Extract key phrases from description
        var nameComponents: [String] = []
        
        // Extract document type
        if description.lowercased().contains("invoice") {
            nameComponents.append("Invoice")
        } else if description.lowercased().contains("receipt") {
            nameComponents.append("Receipt")
        } else if description.lowercased().contains("contract") {
            nameComponents.append("Contract")
        } else if description.lowercased().contains("medical") {
            nameComponents.append("Medical")
        } else if description.lowercased().contains("meeting") {
            nameComponents.append("Meeting")
        } else if description.lowercased().contains("voice note") || description.lowercased().contains("memo") {
            nameComponents.append("VoiceMemo")
        } else if description.lowercased().contains("scene:") {
            // Extract scene name
            if let sceneRange = description.range(of: "Scene: ") {
                let sceneText = String(description[sceneRange.upperBound...])
                if let firstComma = sceneText.firstIndex(of: ",") {
                    let sceneName = String(sceneText[..<firstComma]).trimmingCharacters(in: .whitespaces)
                    nameComponents.append(sceneName.capitalized)
                } else if let firstPeriod = sceneText.firstIndex(of: ".") {
                    let sceneName = String(sceneText[..<firstPeriod]).trimmingCharacters(in: .whitespaces)
                    nameComponents.append(sceneName.capitalized)
                }
            }
        }
        
        // Extract person count for photos
        if description.contains("person") {
            if let personRange = description.range(of: "person") {
                let beforePerson = String(description[..<personRange.lowerBound])
                if let numberRange = beforePerson.range(of: #"\d+"#, options: .regularExpression) {
                    let number = String(description[numberRange])
                    if number == "1" {
                        nameComponents.append("Portrait")
                    } else {
                        nameComponents.append("GroupPhoto")
                    }
                }
            }
        }
        
        // If we have components, create name
        if !nameComponents.isEmpty {
            var name = nameComponents.joined(separator: "_")
            
            // Add timestamp for uniqueness
            let timestamp = Int(Date().timeIntervalSince1970)
            name += "_\(timestamp)"
            
            // Add file extension
            if let ext = fileExtension(from: mimeType) {
                name += ".\(ext)"
            }
            
            return name
        }
        
        return nil
    }
    
    /// Extract frame from video for analysis
    private static func extractFrame(from asset: AVURLAsset, at time: Double) async -> Data? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        
        do {
            let cgImage = try await generator.image(at: cmTime).image
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.8)
        } catch {
            return nil
        }
    }
    
    /// Describe image frame for video analysis
    private static func describeImageFrame(data: Data) async -> String {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            return ""
        }
        
        var description = ""
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let sceneRequest = VNClassifyImageRequest()
        try? handler.perform([sceneRequest])
        if let results = sceneRequest.results?.prefix(2) {
            let scenes = results
                .filter { $0.confidence > 0.3 }
                .map { $0.identifier }
                .joined(separator: ", ")
            if !scenes.isEmpty {
                description = scenes
            }
        }
        
        return description
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
    
    /// Generate comprehensive AI tags for a document using LLAMA-style understanding
    static func generateTags(
        for data: Data,
        mimeType: String?,
        documentName: String
    ) async -> [String] {
        var tags: [String] = []
        
        print("🦙 LLAMA: Generating intelligent tags for \(mimeType ?? "unknown") file...")
        
        // OPTIMIZATION: Skip heavy AI for files > 10MB to prevent hanging
        let maxSizeForDeepAnalysis = 10 * 1024 * 1024 // 10MB
        let shouldDoDeepAnalysis = data.count < maxSizeForDeepAnalysis
        
        // Add document type tags (fast)
        if let mimeType = mimeType {
            tags.append(contentsOf: tagsForMimeType(mimeType))
        }
        
        // Use LLAMA-style description for intelligent tagging
        if shouldDoDeepAnalysis {
            let llamaDescription = await generateLlamaStyleDescription(
                for: data,
                mimeType: mimeType
            )
            
            // Extract tags from LLAMA description
            let llamaTags = extractTagsFromLlamaDescription(llamaDescription)
            tags.append(contentsOf: llamaTags)
            print("   🦙 LLAMA tags: \(llamaTags.count) intelligent tags")
        } else {
            print("   ⚠️ Skipping LLAMA analysis (file too large: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))")
        }
        
        // OPTIMIZED: Only do deep analysis on smaller files
        if shouldDoDeepAnalysis, let mimeType = mimeType {
            if mimeType.hasPrefix("image/") {
                // Lightweight image analysis (supplement LLAMA)
                let imageTags = await analyzeImageContentOptimized(data)
                tags.append(contentsOf: imageTags)
                print("   Image AI: \(imageTags.count) additional tags")
                
            } else if mimeType.hasPrefix("video/") {
                // Basic video tags
                tags.append("Video Recording")
                print("   Video: Basic tags added")
                
            } else if mimeType.hasPrefix("audio/") {
                // Basic audio tags
                tags.append("Voice Memo")
                print("   Audio: Basic tags added")
            }
        }
        
        // Quick text extraction (optimized)
        if let text = await extractTextOptimized(from: data, mimeType: mimeType) {
            tags.append(contentsOf: await analyzeTextOptimized(text))
        }
        
        // Analyze filename (fast)
        tags.append(contentsOf: analyzeFilename(documentName))
        
        // Remove duplicates and return
        let uniqueTags = Array(Set(tags))
        print("   ✅ Total LLAMA tags: \(uniqueTags.count)")
        return uniqueTags
    }
    
    /// Extract intelligent tags from LLAMA-style description
    private static func extractTagsFromLlamaDescription(_ description: String) -> [String] {
        var tags: [String] = []
        let lowerDesc = description.lowercased()
        
        // Document type tags
        if lowerDesc.contains("invoice") || lowerDesc.contains("bill") {
            tags.append("Invoice")
            tags.append("Financial")
        }
        if lowerDesc.contains("receipt") {
            tags.append("Receipt")
            tags.append("Financial")
        }
        if lowerDesc.contains("contract") || lowerDesc.contains("agreement") {
            tags.append("Contract")
            tags.append("Legal")
        }
        if lowerDesc.contains("medical") || lowerDesc.contains("patient") {
            tags.append("Medical")
            tags.append("Healthcare")
        }
        if lowerDesc.contains("meeting") {
            tags.append("Meeting")
            tags.append("Recording")
        }
        if lowerDesc.contains("voice note") || lowerDesc.contains("memo") {
            tags.append("Voice Memo")
            tags.append("Personal Note")
        }
        if lowerDesc.contains("presentation") {
            tags.append("Presentation")
            tags.append("Recording")
        }
        
        // Scene tags
        if lowerDesc.contains("scene:") {
            if let sceneRange = description.range(of: "Scene: ") {
                let sceneText = String(description[sceneRange.upperBound...])
                if let firstPeriod = sceneText.firstIndex(of: ".") {
                    let sceneName = String(sceneText[..<firstPeriod])
                        .trimmingCharacters(in: .whitespaces)
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces).capitalized }
                    tags.append(contentsOf: sceneName)
                }
            }
        }
        
        // Person/portrait tags
        if lowerDesc.contains("person") {
            if lowerDesc.contains("1 person") {
                tags.append("Portrait")
                tags.append("Single Person")
            } else {
                tags.append("Group Photo")
                tags.append("Multiple People")
            }
        }
        
        // Orientation tags
        if lowerDesc.contains("landscape") {
            tags.append("Landscape")
        }
        if lowerDesc.contains("portrait") {
            tags.append("Portrait")
        }
        
        // Duration tags for media
        if let durationRange = description.range(of: "duration: ") {
            let durationText = String(description[durationRange.upperBound...])
            if let seconds = Int(durationText.components(separator: " ").first ?? "") {
                if seconds < 10 {
                    tags.append("Short Clip")
                } else if seconds < 60 {
                    tags.append("Brief Recording")
                } else if seconds < 300 {
                    tags.append("Medium Length")
                } else {
                    tags.append("Long Recording")
                }
            }
        }
        
        return tags
    }
    
    // OPTIMIZED: Lightweight image analysis
    private static func analyzeImageContentOptimized(_ data: Data) async -> [String] {
        var tags: [String] = []
        
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else { return tags }
        
        // Only do quick OCR, skip heavy scene analysis
        if let textTags = await recognizeTextContent(cgImage) {
            tags.append(contentsOf: textTags)
        }
        
        // Quick image characteristics (no Vision processing)
        tags.append(contentsOf: analyzeImageCharacteristics(image))
        
        return tags
    }
    
    // OPTIMIZED: Quick text extraction
    private static func extractTextOptimized(from data: Data, mimeType: String?) async -> String? {
        guard let mimeType = mimeType else { return nil }
        
        // Only extract from images and text files, skip PDFs to prevent hanging
        if mimeType.hasPrefix("image/") {
            return await extractTextFromImage(data)
        } else if mimeType.hasPrefix("text/") {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    // OPTIMIZED: Quick text analysis
    private static func analyzeTextOptimized(_ text: String) async -> [String] {
        var tags: [String] = []
        
        // Limit text length to prevent hanging
        let limitedText = String(text.prefix(1000))
        
        // Quick keyword extraction only (skip sentiment, NER for performance)
        tags.append(contentsOf: extractKeywords(from: limitedText).prefix(5))
        
        return tags
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
    
    // MARK: - GENERATIVE AI DEEP ANALYSIS
    
    /// Deep image analysis: scene understanding, objects, activities, context
    private static func analyzeImageContent(_ data: Data) async -> [String] {
        var tags: [String] = []
        
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else { return tags }
        
        // 1. Scene Classification
        if let sceneTag = await classifyScene(cgImage) {
            tags.append(sceneTag)
        }
        
        // 2. Object Detection
        let objects = await detectObjects(cgImage)
        tags.append(contentsOf: objects)
        
        // 3. Face Detection & Analysis
        let faceInfo = await analyzeFaces(cgImage)
        tags.append(contentsOf: faceInfo)
        
        // 4. Image Characteristics
        tags.append(contentsOf: analyzeImageCharacteristics(image))
        
        // 5. Contextual Inference
        let context = inferImageContext(tags: tags)
        if let context = context {
            tags.append("Context: \(context)")
        }
        
        return tags
    }
    
    /// Deep video analysis: extract frames, analyze motion, understand content
    private static func analyzeVideoContent(_ data: Data) async -> [String] {
        var tags: [String] = []
        
        // Save to temp file for AVAsset
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        do {
            try data.write(to: tempURL)
            
            let asset = AVAsset(url: tempURL)
            
            // 1. Duration analysis
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            
            if seconds < 10 {
                tags.append("Short Clip")
            } else if seconds < 60 {
                tags.append("Brief Video")
            } else if seconds < 300 {
                tags.append("Medium Video")
            } else {
                tags.append("Long Video")
            }
            
            // 2. Extract key frames and analyze
            let frameImages = try await extractKeyFrames(from: asset, count: 3)
            for frameImage in frameImages {
                if let cgImage = frameImage.cgImage {
                    let frameObjects = await detectObjects(cgImage)
                    tags.append(contentsOf: frameObjects.prefix(5))
                }
            }
            
            // 3. Audio track analysis
            if await hasAudioTrack(asset) {
                tags.append("With Audio")
                // Could transcribe here if needed
            } else {
                tags.append("Silent")
            }
            
            // 4. Infer video purpose
            let purpose = inferVideoPurpose(tags: tags, duration: seconds)
            if let purpose = purpose {
                tags.append("Purpose: \(purpose)")
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("Video analysis error: \(error)")
        }
        
        return tags
    }
    
    /// Deep audio analysis: transcription, speaker analysis, topic detection
    private static func analyzeAudioContent(_ data: Data) async -> [String] {
        var tags: [String] = []
        
        // Save to temp file for AVAsset
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        do {
            try data.write(to: tempURL)
            
            let asset = AVAsset(url: tempURL)
            
            // 1. Duration analysis
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            
            if seconds < 30 {
                tags.append("Quick Note")
            } else if seconds < 120 {
                tags.append("Voice Memo")
            } else if seconds < 600 {
                tags.append("Recording")
            } else {
                tags.append("Long Recording")
            }
            
            // 2. Speech-to-text transcription
            if let transcript = await transcribeAudio(url: tempURL) {
                print("   Audio transcript: \(transcript.prefix(100))...")
                
                // Analyze transcribed text
                let textTags = await analyzeText(transcript)
                tags.append(contentsOf: textTags)
                
                // Infer audio purpose from content
                if transcript.lowercased().contains("meeting") {
                    tags.append("Meeting Recording")
                } else if transcript.lowercased().contains("note to self") {
                    tags.append("Personal Note")
                } else if transcript.lowercased().contains("intel report") {
                    tags.append("Intelligence Briefing")
                }
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            print("Audio analysis error: \(error)")
        }
        
        return tags
    }
    
    // MARK: - Vision AI Helpers
    
    private static func classifyScene(_ image: CGImage) async -> String? {
        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard let observations = request.results as? [VNClassificationObservation],
                      let topObservation = observations.first,
                      topObservation.confidence > 0.3 else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Describe what's happening in the scene (context-aware)
                let identifier = topObservation.identifier.lowercased()
                var sceneDescription = ""
                
                if identifier.contains("office") || identifier.contains("workspace") {
                    sceneDescription = "Office or workspace setting"
                } else if identifier.contains("outdoor") || identifier.contains("nature") {
                    sceneDescription = "Outdoor environment"
                } else if identifier.contains("medical") || identifier.contains("hospital") {
                    sceneDescription = "Medical or healthcare facility"
                } else if identifier.contains("document") || identifier.contains("paper") {
                    sceneDescription = "Document or paperwork being scanned"
                } else if identifier.contains("indoor") || identifier.contains("room") {
                    sceneDescription = "Indoor setting"
                } else if identifier.contains("food") || identifier.contains("meal") {
                    sceneDescription = "Food or dining scene"
                } else if identifier.contains("people") || identifier.contains("person") {
                    sceneDescription = "People present in scene"
                } else {
                    sceneDescription = topObservation.identifier.capitalized
                }
                
                continuation.resume(returning: sceneDescription)
            }
            
            let handler = VNImageRequestHandler(cgImage: image)
            try? handler.perform([request])
        }
    }
    
    private static func detectObjects(_ image: CGImage) async -> [String] {
        var allTags: [String] = []
        
        // 1. Recognize text in image (documents, signs, labels)
        if let textContent = await recognizeTextContent(image) {
            allTags.append(contentsOf: textContent)
        }
        
        // 2. Detect rectangles (documents, cards, papers)
        let rectangles = await detectRectangles(image)
        allTags.append(contentsOf: rectangles)
        
        // 3. Detect barcodes/QR codes
        if let barcodes = await detectBarcodes(image) {
            allTags.append(contentsOf: barcodes)
        }
        
        return allTags
    }
    
    private static func recognizeTextContent(_ image: CGImage) async -> [String]? {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var tags: [String] = []
                let allText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                
                // Analyze what type of document this is based on text
                if allText.lowercased().contains("patient") || allText.lowercased().contains("medical") {
                    tags.append("Medical document being photographed")
                } else if allText.lowercased().contains("invoice") || allText.lowercased().contains("receipt") {
                    tags.append("Financial document or receipt")
                } else if allText.lowercased().contains("contract") || allText.lowercased().contains("agreement") {
                    tags.append("Legal document or contract")
                } else if !allText.isEmpty {
                    tags.append("Document with text content")
                }
                
                continuation.resume(returning: tags.isEmpty ? nil : tags)
            }
            
            request.recognitionLevel = .accurate
            let handler = VNImageRequestHandler(cgImage: image)
            try? handler.perform([request])
        }
    }
    
    private static func detectRectangles(_ image: CGImage) async -> [String] {
        return await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var tags: [String] = []
                if observations.count > 0 {
                    tags.append("Contains \(observations.count) document\(observations.count == 1 ? "" : "s") or card\(observations.count == 1 ? "" : "s")")
                }
                
                continuation.resume(returning: tags)
            }
            
            let handler = VNImageRequestHandler(cgImage: image)
            try? handler.perform([request])
        }
    }
    
    private static func detectBarcodes(_ image: CGImage) async -> [String]? {
        return await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                guard let observations = request.results as? [VNBarcodeObservation],
                      !observations.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: ["Contains barcode or QR code"])
            }
            
            let handler = VNImageRequestHandler(cgImage: image)
            try? handler.perform([request])
        }
    }
    
    private static func analyzeFaces(_ image: CGImage) async -> [String] {
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                var tags: [String] = []
                
                if let observations = request.results as? [VNFaceObservation] {
                    let faceCount = observations.count
                    if faceCount > 0 {
                        tags.append("Contains \(faceCount) face\(faceCount == 1 ? "" : "s")")
                        
                        if faceCount == 1 {
                            tags.append("Portrait")
                        } else {
                            tags.append("Group Photo")
                        }
                    }
                }
                
                continuation.resume(returning: tags)
            }
            
            let handler = VNImageRequestHandler(cgImage: image)
            try? handler.perform([request])
        }
    }
    
    private static func analyzeImageCharacteristics(_ image: UIImage) -> [String] {
        var tags: [String] = []
        
        let width = image.size.width
        let height = image.size.height
        let aspectRatio = width / height
        
        // Orientation
        if aspectRatio > 1.5 {
            tags.append("Landscape")
        } else if aspectRatio < 0.7 {
            tags.append("Portrait")
        } else {
            tags.append("Square")
        }
        
        // Resolution
        let megapixels = (width * height) / 1_000_000
        if megapixels > 8 {
            tags.append("High Resolution")
        } else if megapixels > 2 {
            tags.append("Standard Resolution")
        }
        
        return tags
    }
    
    private static func inferImageContext(tags: [String]) -> String? {
        let tagString = tags.joined(separator: " ").lowercased()
        
        // Medical context
        if tagString.contains("medical") || tagString.contains("hospital") || tagString.contains("patient") {
            return "Medical Documentation"
        }
        
        // Legal context
        if tagString.contains("legal") || tagString.contains("contract") || tagString.contains("agreement") {
            return "Legal Document"
        }
        
        // Personal context
        if tagString.contains("face") || tagString.contains("portrait") || tagString.contains("people") {
            return "Personal Photo"
        }
        
        // Document scan context
        if tagString.contains("document") || tagString.contains("text") {
            return "Scanned Document"
        }
        
        return nil
    }
    
    // MARK: - Video AI Helpers
    
    private static func extractKeyFrames(from asset: AVAsset, count: Int) async throws -> [UIImage] {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        var images: [UIImage] = []
        let interval = durationSeconds / Double(count + 1)
        
        for i in 1...count {
            let time = CMTime(seconds: interval * Double(i), preferredTimescale: 600)
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                images.append(UIImage(cgImage: cgImage))
            }
        }
        
        return images
    }
    
    private static func hasAudioTrack(_ asset: AVAsset) async -> Bool {
        do {
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            return !audioTracks.isEmpty
        } catch {
            return false
        }
    }
    
    private static func inferVideoPurpose(tags: [String], duration: Double) -> String? {
        let tagString = tags.joined(separator: " ").lowercased()
        
        // Short clips
        if duration < 10 {
            if tagString.contains("face") || tagString.contains("person") {
                return "Quick Selfie Video"
            }
            return "Brief Clip"
        }
        
        // Recording context
        if tagString.contains("meeting") || tagString.contains("conference") {
            return "Meeting Recording"
        }
        
        if tagString.contains("presentation") || tagString.contains("screen") {
            return "Presentation Capture"
        }
        
        // Personal context
        if tagString.contains("face") || tagString.contains("portrait") {
            return "Personal Video"
        }
        
        return nil
    }
    
    // MARK: - Audio AI Helpers
    
    private static func transcribeAudio(url: URL) async -> String? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("   Speech recognition not authorized")
            return nil
        }
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        return await withCheckedContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if let error = error {
                    print("   Transcription error: \(error)")
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

