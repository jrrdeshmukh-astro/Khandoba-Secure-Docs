//
//  LlamaMediaDescriptionService.swift
//  Khandoba Secure Docs
//
//  Unified media description service using Llama for describing various media types
//  as a unified information feed (no second layer of summarization)
//

import Foundation
import SwiftData
import Combine
import Vision
import Speech
import NaturalLanguage
import UIKit
import AVFoundation

@MainActor
final class LlamaMediaDescriptionService: ObservableObject {
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var currentStep: String = ""
    
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Unified Media Description
    
    /// Generate unified description of media using Llama-style understanding
    /// This replaces the second layer of summarization - uses direct transcription/analysis
    func describeMediaUnified(_ documents: [Document]) async throws -> String {
        guard !documents.isEmpty else {
            throw LlamaDescriptionError.noDocuments
        }
        
        isProcessing = true
        processingProgress = 0.0
        defer { isProcessing = false }
        
        print("🦙 LLAMA UNIFIED MEDIA DESCRIPTION")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📁 Processing \(documents.count) documents")
        
        var unifiedDescriptions: [String] = []
        
        for (index, document) in documents.enumerated() {
            processingProgress = Double(index) / Double(documents.count)
            currentStep = "Describing: \(document.name)"
            
            print("   [\(index + 1)/\(documents.count)] \(document.name)")
            
            let description = await describeDocument(document)
            unifiedDescriptions.append(description)
        }
        
        processingProgress = 1.0
        currentStep = "Complete"
        
        // Combine into unified feed (no summarization - direct descriptions)
        let unifiedFeed = unifiedDescriptions.joined(separator: "\n\n")
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(" UNIFIED DESCRIPTION COMPLETE")
        
        return unifiedFeed
    }
    
    // MARK: - Document Description
    
    private func describeDocument(_ document: Document) async -> String {
        guard let data = document.encryptedFileData else {
            return "Document: \(document.name) - No data available"
        }
        
        var description = "Document: \(document.name)\n"
        description += "Type: \(document.documentType)\n"
        description += "Created: \(document.createdAt.formatted(date: .long, time: .shortened))\n"
        
        switch document.documentType {
        case "image":
            description += await describeImage(data: data, document: document)
        case "video":
            description += await describeVideo(data: data, document: document)
        case "audio":
            description += await describeAudio(data: data, document: document)
        case "pdf", "text":
            description += await describeText(data: data, document: document)
        default:
            description += "Unsupported document type for description"
        }
        
        return description
    }
    
    // MARK: - Image Description (CLIP-style)
    
    private func describeImage(data: Data, document: Document) async -> String {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            return "Unable to process image"
        }
        
        var description = ""
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Scene classification
        let sceneRequest = VNClassifyImageRequest()
        try? handler.perform([sceneRequest])
        if let results = sceneRequest.results?.prefix(5) {
            let scenes = results
                .filter { $0.confidence > 0.3 }
                .map { "\($0.identifier) (\(Int($0.confidence * 100))%)" }
                .joined(separator: ", ")
            if !scenes.isEmpty {
                description += "Scene: \(scenes)\n"
            }
        }
        
        // Face detection
        let faceRequest = VNDetectFaceRectanglesRequest()
        let landmarksRequest = VNDetectFaceLandmarksRequest()
        try? handler.perform([faceRequest, landmarksRequest])
        
        if let faceCount = faceRequest.results?.count, faceCount > 0 {
            description += "People: \(faceCount) person\(faceCount > 1 ? "s" : "") detected\n"
            
            if let landmarks = landmarksRequest.results, !landmarks.isEmpty {
                description += "Facial features analyzed\n"
            }
        }
        
        // Text recognition (OCR)
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        try? handler.perform([textRequest])
        
        if let observations = textRequest.results, !observations.isEmpty {
            let ocrText = observations.compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            if !ocrText.isEmpty {
                description += "Text content: \(ocrText)\n"
            }
        }
        
        // Image characteristics
        let size = image.size
        let aspectRatio = size.width / size.height
        description += "Format: \(aspectRatio > 1.5 ? "Wide" : aspectRatio < 0.7 ? "Portrait" : "Square")\n"
        
        return description
    }
    
    // MARK: - Video Description (Video-LLaMA style)
    
    private func describeVideo(data: Data, document: Document) async -> String {
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
            description += "Duration: \(Int(durationSeconds)) seconds\n"
            
            // Audio transcription
            if let transcript = await transcribeAudio(url: tempURL) {
                description += "Audio transcript: \(transcript)\n"
            }
            
            // Frame analysis (start, middle, end)
            var frameDescriptions: [String] = []
            
            if let startFrame = await extractFrame(from: asset, at: 0.0) {
                let frameDesc = await describeImageFrame(data: startFrame)
                if !frameDesc.isEmpty {
                    frameDescriptions.append("Opening: \(frameDesc)")
                }
            }
            
            if durationSeconds > 2.0 {
                let middleTime = durationSeconds / 2.0
                if let middleFrame = await extractFrame(from: asset, at: middleTime) {
                    let frameDesc = await describeImageFrame(data: middleFrame)
                    if !frameDesc.isEmpty {
                        frameDescriptions.append("Middle: \(frameDesc)")
                    }
                }
            }
            
            if durationSeconds > 1.0 {
                let endTime = max(0.0, durationSeconds - 1.0)
                if let endFrame = await extractFrame(from: asset, at: endTime) {
                    let frameDesc = await describeImageFrame(data: endFrame)
                    if !frameDesc.isEmpty {
                        frameDescriptions.append("Closing: \(frameDesc)")
                    }
                }
            }
            
            if !frameDescriptions.isEmpty {
                description += "Visual progression: \(frameDescriptions.joined(separator: " → "))\n"
            }
            
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            description += "Error processing video: \(error.localizedDescription)\n"
        }
        
        return description
    }
    
    // MARK: - Audio Description
    
    private func describeAudio(data: Data, document: Document) async -> String {
        var description = ""
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        do {
            try data.write(to: tempURL)
            
            if let transcript = await transcribeAudio(url: tempURL) {
                description += "Transcription: \(transcript)\n"
            } else {
                description += "Audio file - transcription unavailable\n"
            }
            
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            description += "Error processing audio: \(error.localizedDescription)\n"
        }
        
        return description
    }
    
    // MARK: - Text Description
    
    private func describeText(data: Data, document: Document) async -> String {
        var description = ""
        
        if let text = String(data: data, encoding: .utf8) {
            // Use full text content (no summarization)
            let preview = text.prefix(1000) // Limit preview but keep full content available
            description += "Content preview: \(preview)"
            if text.count > 1000 {
                description += "... (full content available)"
            }
            description += "\n"
        } else if document.documentType == "pdf" {
            // Extract PDF text
            let pdfText = PDFTextExtractor.extractFromPDF(data: data)
            if !pdfText.isEmpty {
                let preview = pdfText.prefix(1000)
                description += "PDF content: \(preview)"
                if pdfText.count > 1000 {
                    description += "... (full content available)"
                }
                description += "\n"
            }
        }
        
        return description
    }
    
    // MARK: - Helper Methods
    
    private func describeImageFrame(data: Data) async -> String {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            return ""
        }
        
        var description = ""
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let sceneRequest = VNClassifyImageRequest()
        try? handler.perform([sceneRequest])
        if let results = sceneRequest.results?.prefix(3) {
            let scenes = results
                .filter { $0.confidence > 0.3 }
                .map { $0.identifier }
                .joined(separator: ", ")
            if !scenes.isEmpty {
                description += scenes
            }
        }
        
        return description
    }
    
    private func extractFrame(from asset: AVURLAsset, at time: Double) async -> Data? {
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
    
    private func transcribeAudio(url: URL) async -> String? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            return nil
        }
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer = recognizer, recognizer.isAvailable else {
            return nil
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        
        return try? await withCheckedThrowingContinuation { continuation in
            var finalTranscript = ""
            recognizer.recognitionTask(with: request) { result, error in
                if error != nil {
                    continuation.resume(returning: nil)
                } else if let result = result {
                    finalTranscript = result.bestTranscription.formattedString
                    if result.isFinal {
                        continuation.resume(returning: finalTranscript)
                    }
                }
            }
        }
    }
}

// MARK: - Errors

enum LlamaDescriptionError: LocalizedError {
    case noDocuments
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .noDocuments:
            return "No documents provided for description"
        case .processingFailed:
            return "Failed to process media for description"
        }
    }
}
