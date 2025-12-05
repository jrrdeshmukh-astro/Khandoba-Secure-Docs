//
//  VoiceMemoService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import AVFoundation
import SwiftData
import Combine

@MainActor
final class VoiceMemoService: NSObject, ObservableObject {
    @Published var isGenerating = false
    @Published var isPlaying = false
    @Published var currentProgress: Double = 0.0
    
    private var speechSynthesizer = AVSpeechSynthesizer()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var currentOutputURL: URL?
    
    private var modelContext: ModelContext?
    
    nonisolated override init() {
        super.init()
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task { @MainActor in
            speechSynthesizer.delegate = self
        }
    }
    
    /// Generate voice memo from text using text-to-speech
    /// ROBUST APPROACH: Record system audio while synthesizer speaks
    func generateVoiceMemo(from text: String, title: String) async throws -> URL {
        isGenerating = true
        defer { isGenerating = false }
        
        print("🎤 ═══════════════════════════════════")
        print("🎤 VOICE MEMO GENERATION START")
        print("🎤 ═══════════════════════════════════")
        print("📝 Text length: \(text.count) characters")
        print("📝 Preview: \(String(text.prefix(150)))")
        print("")
        
        // Create output file
        let tempDir = FileManager.default.temporaryDirectory
        let outputURL = tempDir.appendingPathComponent("voice_memo_\(UUID().uuidString).m4a")
        
        print("📁 Output file: \(outputURL.lastPathComponent)")
        print("📁 Full path: \(outputURL.path)")
        print("")
        
        // Configure audio session for recording and playback
        print("🔧 Configuring audio session...")
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try audioSession.setActive(true)
        print("✅ Audio session configured")
        print("")
        
        // Create audio recorder with settings
        print("🎙️ Creating audio recorder...")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        let recorder = try AVAudioRecorder(url: outputURL, settings: settings)
        recorder.prepareToRecord()
        recorder.record()
        print("✅ Recorder started")
        print("")
        
        // Create utterance for synthesis
        print("🗣️ Creating speech utterance...")
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.50  // Natural speed
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        print("✅ Utterance created")
        print("   Language: en-US")
        print("   Rate: 0.50")
        print("   Estimated duration: ~\(text.count / 150) seconds")
        print("")
        
        // Use async/await to wait for speech completion
        return try await withCheckedThrowingContinuation { continuation in
            // Track if we've already resumed
            var hasResumed = false
            
            // Set up speech delegate
            speechSynthesizer.delegate = self
            
            // Store completion handler
            speechCompletionHandler = { [weak recorder] in
                guard !hasResumed else { return }
                hasResumed = true
                
                print("")
                print("🛑 Speech completed - stopping recorder...")
                recorder?.stop()
                
                // Small delay to ensure final audio is captured
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                    // Check file size
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
                        let fileSize = attributes[.size] as? UInt64 ?? 0
                        
                        print("📊 Final audio file:")
                        print("   Size: \(fileSize) bytes")
                        print("   Path: \(outputURL.lastPathComponent)")
                        
                        if fileSize > 10000 {  // At least 10KB = has audio content
                            print("✅ SUCCESS: Voice memo generated with audio content")
                            print("🎤 ═══════════════════════════════════")
                            print("")
                            await MainActor.run {
                                self.currentOutputURL = outputURL
                            }
                            continuation.resume(returning: outputURL)
                        } else {
                            print("❌ FAILURE: Audio file too small (\(fileSize) bytes)")
                            print("   Expected: >10,000 bytes")
                            print("   This indicates no audio was captured")
                            print("🎤 ═══════════════════════════════════")
                            print("")
                            continuation.resume(throwing: VoiceMemoError.generationFailed)
                        }
                    } catch {
                        print("❌ Error checking file: \(error)")
                        continuation.resume(throwing: VoiceMemoError.generationFailed)
                    }
                }
            }
            
            // Start speaking
            print("🗣️ Starting speech synthesis...")
            print("   This will capture system audio while speaking")
            print("")
            speechSynthesizer.speak(utterance)
        }
    }
    
    // MARK: - Completion Handler
    private var speechCompletionHandler: (() -> Void)?
    
    /// Play voice memo
    func playVoiceMemo(url: URL) async throws {
        isPlaying = true
        
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
    
    /// Stop playing voice memo
    func stopPlaying() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentProgress = 0.0
    }
    
    /// Save voice memo to vault as a document
    func saveVoiceMemoToVault(_ url: URL, vault: Vault, title: String, description: String?) async throws -> Document {
        guard let modelContext = modelContext else {
            throw VoiceMemoError.contextNotAvailable
        }
        
        // Read audio data
        let audioData = try Data(contentsOf: url)
        
        // Create document
        let document = Document(
            name: title,
            fileExtension: "caf",
            mimeType: "audio/x-caf",
            fileSize: Int64(audioData.count),
            documentType: "audio"
        )
        document.encryptedFileData = audioData
        document.sourceSinkType = "source" // AI-generated content is "source"
        document.vault = vault
        document.aiTags = ["intel-report", "voice-memo", "ai-generated", "threat-analysis", "ai-narrated"]
        document.status = "active"
        
        modelContext.insert(document)
        try modelContext.save()
        
        print("✅ Voice memo saved to vault: \(title)")
        return document
    }
    
    // Intel Report functions - ARCHIVED (IntelReport type no longer available)
    
    // MARK: - Helper Functions
    
    private func isNightTime(_ date: Date) -> Bool {
        case .low:
            narrative += "Your vault shows normal activity patterns with no significant security concerns. "
        case .medium:
            narrative += "Some suspicious patterns have been detected. Continued monitoring is recommended. "
        case .high:
            narrative += "Multiple security red flags detected. Immediate review of access logs is advised. "
        case .critical:
            narrative += "Critical security threat detected. Immediate action required. Review all recent access activity. "
        }
        narrative += "\n\n"
        
        // Document Analysis
        narrative += "Document Intelligence Summary: "
        narrative += report.narrative
        narrative += "\n\n"
        
        // Key Insights from report
        if !report.insights.isEmpty {
            narrative += "Key Findings: "
            narrative += report.insights.prefix(3).joined(separator: ". ")
            narrative += ". "
            narrative += "\n\n"
        }
        
        // Access Pattern Analysis
        let logs = vault.accessLogs ?? []
        if !logs.isEmpty {
            narrative += "Access Pattern Analysis: "
            narrative += "Your vault has \(logs.count) recorded access events. "
            
            let recentLogs = logs.sorted { $0.timestamp > $1.timestamp }.prefix(5)
            narrative += "The most recent access was on \(recentLogs.first?.timestamp.formatted(date: .abbreviated, time: .shortened) ?? "unknown date"). "
            
            // Night access detection
            let nightAccess = logs.filter { isNightTime($0.timestamp) }
            if !nightAccess.isEmpty {
                let nightPercentage = (Double(nightAccess.count) / Double(logs.count)) * 100
                narrative += "Note: \(Int(nightPercentage)) percent of accesses occurred during nighttime hours, which may indicate unusual activity patterns. "
            }
            
            narrative += "\n\n"
        }
        
        // Geographic Analysis
        let logsWithLocation = logs.filter { $0.locationLatitude != nil && $0.locationLongitude != nil }
        if !logsWithLocation.isEmpty {
            narrative += "Geographic Intelligence: "
            narrative += "Location data has been recorded for \(logsWithLocation.count) access events. "
            
            // Check for geographic anomalies
            if hasGeographicAnomalies(logs) {
                narrative += "Warning: Geographic anomalies detected. Some access events show impossible travel distances, suggesting potential account compromise or location spoofing. "
            } else {
                narrative += "Access locations appear consistent with normal usage patterns. "
            }
            narrative += "\n\n"
        }
        
        // ACTIONABLE INSIGHTS - Step-by-step recommendations
        narrative += "Actionable Security Insights: "
        narrative += "\n\n"
        
        let insights = generateActionableInsights(
            threatLevel: threatLevel,
            anomalyScore: anomalyScore,
            vault: vault
        )
        
        for (index, insight) in insights.enumerated() {
            narrative += "Action \(index + 1): \(insight.action). "
            narrative += "\(insight.rationale). "
            narrative += "Priority: \(insight.priority.rawValue). "
            if let timeframe = insight.timeframe {
                narrative += "Complete within \(timeframe). "
            }
            narrative += "\n\n"
        }
        
        narrative += "\n\n"
        
        // Closing
        narrative += "This concludes the Khandoba Security Intelligence Report. "
        narrative += "For detailed analysis, please review the written report in your Intel Vault. "
        narrative += "Stay secure. "
        
        return narrative
    }
    
    // MARK: - Helper Functions (Intel-related functions removed)
}

// Actionable Insight Model - ARCHIVED with Intel Reports

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceMemoService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            print("🎙️ Speech synthesis finished - calling completion handler")
            speechCompletionHandler?()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            print("🎤 Speech synthesis started")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceMemoService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            currentProgress = 0.0
            print("✅ Audio playback finished")
        }
    }
}

// MARK: - Errors

enum VoiceMemoError: LocalizedError {
    case contextNotAvailable
    case audioSessionError
    case synthesisError
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context not available"
        case .audioSessionError:
            return "Failed to configure audio session"
        case .synthesisError:
            return "Failed to synthesize speech"
        case .generationFailed:
            return "Failed to generate voice memo audio"
        }
    }
}
