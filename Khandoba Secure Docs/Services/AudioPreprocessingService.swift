//
//  AudioPreprocessingService.swift
//  Khandoba Secure Docs
//
//  Created by AI Assistant on 12/5/25.
//
//  Converts all document types (images, videos, PDFs, text) to audio
//

import Foundation
import Vision
import AVFoundation
import PDFKit
import SwiftUI
import Combine

@MainActor
final class AudioPreprocessingService: ObservableObject {
    @Published var processingProgress: Double = 0.0
    @Published var currentStep: String = ""
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    /// Convert any document to audio
    func preprocessToAudio(document: Document) async throws -> URL {
        print("🔄 Preprocessing \(document.name) to audio...")
        
        guard let data = document.encryptedFileData else {
            throw PreprocessingError.noData
        }
        
        switch document.documentType {
        case "image":
            return try await imageToAudio(imageData: data, fileName: document.name)
        case "video":
            return try await videoToAudio(videoData: data, fileName: document.name)
        case "pdf", "document":
            return try await pdfToAudio(pdfData: data, fileName: document.name)
        case "audio":
            return try await saveAudioFile(audioData: data, fileName: document.name)
        case "text":
            let text = String(data: data, encoding: .utf8) ?? ""
            return try await textToAudio(text: text, fileName: document.name)
        default:
            throw PreprocessingError.unsupportedType
        }
    }
    
    /// Convert image to audio via OCR
    func imageToAudio(imageData: Data, fileName: String) async throws -> URL {
        currentStep = "Extracting text from image..."
        processingProgress = 0.2
        
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw PreprocessingError.invalidImage
        }
        
        // Perform OCR
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let observations = request.results else {
            throw PreprocessingError.ocrFailed
        }
        
        // Extract text
        let extractedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: " ")
        
        processingProgress = 0.6
        
        if extractedText.isEmpty {
            // No text found, describe it's an image document
            let fallbackText = "Image document: \(fileName). No text content detected."
            return try await textToAudio(text: fallbackText, fileName: fileName)
        }
        
        currentStep = "Converting text to audio..."
        return try await textToAudio(text: extractedText, fileName: fileName)
    }
    
    /// Extract audio from video
    func videoToAudio(videoData: Data, fileName: String) async throws -> URL {
        currentStep = "Extracting audio from video..."
        processingProgress = 0.3
        
        // Save video to temp file
        let tempVideoURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        try videoData.write(to: tempVideoURL)
        
        let asset = AVURLAsset(url: tempVideoURL)
        
        // Check if video has audio track
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        
        if audioTracks.isEmpty {
            // No audio in video, return silent marker
            print("⚠️ Video has no audio track")
            let fallbackText = "Video document: \(fileName). No audio content."
            return try await textToAudio(text: fallbackText, fileName: fileName)
        }
        
        // Extract audio
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .m4a
        
        await exportSession?.export()
        
        // Cleanup temp video
        try? FileManager.default.removeItem(at: tempVideoURL)
        
        processingProgress = 0.9
        
        if let exportedURL = exportSession?.outputURL,
           FileManager.default.fileExists(atPath: exportedURL.path) {
            print("✅ Extracted audio from video")
            return exportedURL
        } else {
            throw PreprocessingError.audioExtractionFailed
        }
    }
    
    /// Convert PDF to audio via text extraction
    func pdfToAudio(pdfData: Data, fileName: String) async throws -> URL {
        currentStep = "Extracting text from PDF..."
        processingProgress = 0.3
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            throw PreprocessingError.invalidPDF
        }
        
        var allText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex),
               let pageText = page.string {
                allText += pageText + " "
            }
        }
        
        processingProgress = 0.6
        
        if allText.isEmpty {
            let fallbackText = "PDF document: \(fileName). No text content extracted."
            return try await textToAudio(text: fallbackText, fileName: fileName)
        }
        
        currentStep = "Converting PDF text to audio..."
        return try await textToAudio(text: allText, fileName: fileName)
    }
    
    /// Convert text to audio
    func textToAudio(text: String, fileName: String) async throws -> URL {
        currentStep = "Synthesizing speech..."
        processingProgress = 0.7
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        utterance.volume = 1.0
        
        // Use VoiceMemoService approach for audio generation
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
        
        processingProgress = 1.0
        
        print("✅ Text converted to audio")
        return outputURL
    }
    
    /// Save existing audio file to temp location
    func saveAudioFile(audioData: Data, fileName: String) async throws -> URL {
        currentStep = "Processing audio file..."
        processingProgress = 0.5
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        try audioData.write(to: outputURL)
        
        processingProgress = 1.0
        print("✅ Audio file ready")
        return outputURL
    }
}

// MARK: - Errors

enum PreprocessingError: LocalizedError {
    case noData
    case unsupportedType
    case invalidImage
    case invalidPDF
    case ocrFailed
    case audioExtractionFailed
    case synthesisFailed
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "Document has no data"
        case .unsupportedType:
            return "Document type not supported for audio conversion"
        case .invalidImage:
            return "Invalid image data"
        case .invalidPDF:
            return "Invalid PDF data"
        case .ocrFailed:
            return "Failed to extract text from image"
        case .audioExtractionFailed:
            return "Failed to extract audio from video"
        case .synthesisFailed:
            return "Failed to synthesize speech"
        }
    }
}

