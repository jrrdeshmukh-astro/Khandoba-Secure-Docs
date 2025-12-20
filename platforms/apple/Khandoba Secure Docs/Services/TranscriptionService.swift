//
//  TranscriptionService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import Combine
import Speech
import AVFoundation
import Vision
import SwiftData
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import NaturalLanguage

@MainActor
final class TranscriptionService: NSObject, ObservableObject {
    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0.0
    @Published var currentTranscription: String = ""
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechURLRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var modelContext: ModelContext?
    
    nonisolated override init() {
        super.init()
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Speech-to-Text Transcription
    
    /// Transcribe audio file to text
    func transcribeAudio(url: URL) async throws -> Transcription {
        isTranscribing = true
        defer { isTranscribing = false }
        
        print(" Transcribing audio: \(url.lastPathComponent)")
        
        // Request authorization
        let authorized = await requestSpeechAuthorization()
        guard authorized else {
            throw TranscriptionError.authorizationDenied
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechURLRecognitionRequest(url: url)
        recognitionRequest?.shouldReportPartialResults = true
        recognitionRequest?.requiresOnDeviceRecognition = false // Use cloud for better accuracy
        
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer else {
            throw TranscriptionError.recognizerUnavailable
        }
        
        // Start recognition
        return try await withCheckedThrowingContinuation { continuation in
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    Task { @MainActor in
                        self.currentTranscription = result.bestTranscription.formattedString
                        self.transcriptionProgress = result.isFinal ? 1.0 : 0.5
                    }
                    
                    if result.isFinal {
                        let transcription = self.createTranscription(from: result, url: url)
                        continuation.resume(returning: transcription)
                    }
                }
                
                if let error = error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createTranscription(from result: SFSpeechRecognitionResult, url: URL) -> Transcription {
        let transcription = Transcription(
            audioURL: url,
            text: result.bestTranscription.formattedString,
            segments: result.bestTranscription.segments.map { segment in
                TranscriptionSegment(
                    text: segment.substring,
                    timestamp: segment.timestamp,
                    duration: segment.duration,
                    confidence: segment.confidence
                )
            },
            confidence: result.bestTranscription.segments.map { Double($0.confidence) }.reduce(0, +) / Double(result.bestTranscription.segments.count),
            duration: result.bestTranscription.segments.last?.timestamp ?? 0,
            transcribedAt: Date()
        )
        
        return transcription
    }
    
    // MARK: - OCR for Images/PDFs
    
    /// Transcribe text from image using Vision OCR
    func transcribeImage(imageData: Data) async throws -> String {
        print("📄 OCR: Extracting text from image")
        
        #if os(iOS)
        guard let cgImage = UIImage(data: imageData)?.cgImage else {
            throw TranscriptionError.invalidImage
        }
        #elseif os(macOS)
        guard let image = NSImage(data: imageData),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw TranscriptionError.invalidImage
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
    
    // MARK: - Transcription Processing (No Summarization)
    
    /// Get full transcription text (no summarization - use Llama for unified description)
    func getFullTranscription(from transcription: Transcription) -> String {
        // Return full transcription - no second layer of summarization
        // Llama will handle unified media description
        return transcription.text
    }
    
    // MARK: - Authorization
    
    private func requestSpeechAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    // MARK: - Batch Processing
    
    /// Transcribe multiple audio documents
    func batchTranscribe(documents: [Document]) async throws -> [UUID: Transcription] {
        var transcriptions: [UUID: Transcription] = [:]
        
        for (index, document) in documents.enumerated() {
            guard document.documentType.contains("audio") else { continue }
            
            transcriptionProgress = Double(index) / Double(documents.count)
            
            // Extract audio URL from document
            if let audioData = document.encryptedFileData {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(document.id.uuidString + ".m4a")
                
                try audioData.write(to: tempURL)
                
                do {
                    let transcription = try await transcribeAudio(url: tempURL)
                    transcriptions[document.id] = transcription
                } catch {
                    print("Failed to transcribe \(document.name): \(error)")
                }
            }
        }
        
        transcriptionProgress = 1.0
        return transcriptions
    }
}

// MARK: - Models

struct Transcription: Codable {
    let audioURL: URL
    let text: String
    let segments: [TranscriptionSegment]
    let confidence: Double
    let duration: Double
    let transcribedAt: Date
    
    var wordCount: Int {
        text.split(separator: " ").count
    }
}

struct TranscriptionSegment: Codable {
    let text: String
    let timestamp: Double
    let duration: Double
    let confidence: Float
}

enum TranscriptionError: LocalizedError {
    case authorizationDenied
    case recognizerUnavailable
    case invalidImage
    case transcriptionFailed
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Speech recognition authorization denied"
        case .recognizerUnavailable:
            return "Speech recognizer not available"
        case .invalidImage:
            return "Invalid image data"
        case .transcriptionFailed:
            return "Transcription failed"
        }
    }
}

