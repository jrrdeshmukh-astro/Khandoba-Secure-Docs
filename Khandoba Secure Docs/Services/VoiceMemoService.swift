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
    
    /// Generate comprehensive AI threat report as voice memo
    func generateThreatReportVoiceMemo(
        for vault: Vault,
        report: IntelReport,
        threatLevel: ThreatLevel,
        anomalyScore: Double
    ) async throws -> Document {
        // Create narrative
        let narrative = createThreatNarrative(
            vault: vault,
            report: report,
            threatLevel: threatLevel,
            anomalyScore: anomalyScore
        )
        
        // Generate voice memo
        let voiceURL = try await generateVoiceMemo(
            from: narrative,
            title: "Intel Report - \(vault.name)"
        )
        
        // Save to vault
        let document = try await saveVoiceMemoToVault(
            voiceURL,
            vault: vault,
            title: "🎙️ AI Threat Analysis - \(Date().formatted(date: .abbreviated, time: .shortened))",
            description: "Comprehensive AI-generated threat analysis and intelligence report"
        )
        
        return document
    }
    
    /// Create comprehensive threat narrative
    private func createThreatNarrative(
        vault: Vault,
        report: IntelReport,
        threatLevel: ThreatLevel,
        anomalyScore: Double
    ) -> String {
        var narrative = ""
        
        // Opening
        narrative += "Khandoba Security Intelligence Report. "
        narrative += "This is an AI-generated threat analysis for vault: \(vault.name). "
        narrative += "Report generated on \(Date().formatted(date: .long, time: .shortened)). "
        narrative += "\n\n"
        
        // Threat Level Assessment
        narrative += "Current Threat Level: \(threatLevel.rawValue). "
        narrative += "Anomaly Score: \(Int(anomalyScore)) out of 100. "
        
        switch threatLevel {
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
    
    // MARK: - Helper Functions
    
    private func isNightTime(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour > 22
    }
    
    private func hasGeographicAnomalies(_ logs: [VaultAccessLog]) -> Bool {
        guard logs.count >= 2 else { return false }
        
        let recentLogs = logs.sorted { $0.timestamp > $1.timestamp }.prefix(10)
        var locations: [(Double, Double, Date)] = []
        
        for log in recentLogs {
            if let lat = log.locationLatitude, let lon = log.locationLongitude {
                locations.append((lat, lon, log.timestamp))
            }
        }
        
        guard locations.count >= 2 else { return false }
        
        // Check for impossible travel
        for i in 0..<(locations.count - 1) {
            let distance = calculateDistance(
                from: (locations[i].0, locations[i].1),
                to: (locations[i + 1].0, locations[i + 1].1)
            )
            let timeDiff = abs(locations[i].2.timeIntervalSince(locations[i + 1].2))
            
            // 500km in less than 1 hour is suspicious
            if distance > 500 && timeDiff < 3600 {
                return true
            }
        }
        
        return false
    }
    
    private func calculateDistance(from: (Double, Double), to: (Double, Double)) -> Double {
        let earthRadius = 6371.0 // km
        
        let lat1Rad = from.0 * .pi / 180
        let lat2Rad = to.0 * .pi / 180
        let deltaLat = (to.0 - from.0) * .pi / 180
        let deltaLon = (to.1 - from.1) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    // MARK: - Actionable Insights Generation
    
    private func generateActionableInsights(
        threatLevel: ThreatLevel,
        anomalyScore: Double,
        vault: Vault
    ) -> [ActionableInsight] {
        var insights: [ActionableInsight] = []
        
        switch threatLevel {
        case .critical:
            // CRITICAL: Immediate actions required
            insights.append(ActionableInsight(
                action: "Immediately change all vault access credentials",
                rationale: "High anomaly score indicates potential security breach. Changing credentials prevents further unauthorized access",
                priority: .critical,
                timeframe: "next 1 hour"
            ))
            
            insights.append(ActionableInsight(
                action: "Enable dual-key authentication for this vault",
                rationale: "Dual-key protection with ML auto-approval adds an additional security layer, making unauthorized access significantly harder",
                priority: .critical,
                timeframe: "next 2 hours"
            ))
            
            insights.append(ActionableInsight(
                action: "Review and revoke suspicious access permissions",
                rationale: "Check all users with vault access. Remove any unauthorized or suspicious accounts immediately",
                priority: .critical,
                timeframe: "next 3 hours"
            ))
            
            insights.append(ActionableInsight(
                action: "Export and backup critical documents to a secure offline location",
                rationale: "In case of active breach, having offline backups ensures data recovery",
                priority: .high,
                timeframe: "today"
            ))
            
            insights.append(ActionableInsight(
                action: "Contact your IT security team or administrator",
                rationale: "Professional security review may reveal additional threats or compromised systems",
                priority: .high,
                timeframe: "within 24 hours"
            ))
            
        case .high:
            // HIGH: Urgent actions needed
            insights.append(ActionableInsight(
                action: "Review all access logs from the past 7 days",
                rationale: "Identify patterns of suspicious activity and confirm legitimate vs unauthorized access",
                priority: .high,
                timeframe: "today"
            ))
            
            insights.append(ActionableInsight(
                action: "Enable geofencing for your typical work locations",
                rationale: "Restrict access to approved geographic areas. Alerts will trigger for access from unusual locations",
                priority: .high,
                timeframe: "next 24 hours"
            ))
            
            insights.append(ActionableInsight(
                action: "Update vault access policies and permissions",
                rationale: "Remove unnecessary access. Follow principle of least privilege",
                priority: .medium,
                timeframe: "next 48 hours"
            ))
            
            insights.append(ActionableInsight(
                action: "Schedule a security audit of all vault documents",
                rationale: "Verify document integrity and identify any unauthorized modifications",
                priority: .medium,
                timeframe: "this week"
            ))
            
        case .medium:
            // MEDIUM: Important preventive actions
            insights.append(ActionableInsight(
                action: "Review recent access patterns for anomalies",
                rationale: "Early detection of unusual patterns prevents escalation to critical threats",
                priority: .medium,
                timeframe: "next 48 hours"
            ))
            
            insights.append(ActionableInsight(
                action: "Verify that all recent document uploads are legitimate",
                rationale: "Ensure no malicious files or unauthorized content has been added to your vault",
                priority: .medium,
                timeframe: "this week"
            ))
            
            insights.append(ActionableInsight(
                action: "Consider enabling dual-key authentication",
                rationale: "Proactive security measure. Dual-key with ML auto-approval balances security and convenience",
                priority: .low,
                timeframe: "next 2 weeks"
            ))
            
            insights.append(ActionableInsight(
                action: "Set up access notifications for future vault activity",
                rationale: "Real-time alerts help you stay informed of all vault access",
                priority: .low,
                timeframe: "next month"
            ))
            
        case .low:
            // LOW: Preventive best practices
            insights.append(ActionableInsight(
                action: "Continue current security practices",
                rationale: "Your vault shows normal activity with no significant concerns",
                priority: .low,
                timeframe: nil
            ))
            
            insights.append(ActionableInsight(
                action: "Schedule regular security reviews",
                rationale: "Proactive monitoring prevents future issues. Review vault activity monthly",
                priority: .low,
                timeframe: "monthly"
            ))
            
            insights.append(ActionableInsight(
                action: "Enable automatic voice intelligence reports",
                rationale: "Stay informed with weekly AI-generated security briefings",
                priority: .low,
                timeframe: "optional"
            ))
            
            insights.append(ActionableInsight(
                action: "Explore advanced security features like geofencing",
                rationale: "Additional layers of protection enhance overall vault security",
                priority: .low,
                timeframe: "as needed"
            ))
        }
        
        // Add source/sink specific insights
        let logs = vault.accessLogs ?? []
        if !logs.isEmpty {
            let sourceCount = (vault.documents ?? []).filter { $0.sourceSinkType == "source" }.count
            let sinkCount = (vault.documents ?? []).filter { $0.sourceSinkType == "sink" }.count
            
            if sinkCount > sourceCount * 2 {
                insights.append(ActionableInsight(
                    action: "Verify authenticity of all externally received documents",
                    rationale: "High volume of sink documents (\(sinkCount)) requires careful validation to prevent data poisoning or malicious content",
                    priority: .medium,
                    timeframe: "ongoing"
                ))
            }
        }
        
        return insights
    }
}

// MARK: - Actionable Insight Model

struct ActionableInsight {
    let action: String
    let rationale: String
    let priority: InsightPriority
    let timeframe: String?
}

enum InsightPriority: String {
    case critical = "CRITICAL"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

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

// NOTE: IntelReport struct is defined in IntelReportService.swift
// to avoid duplication and maintain single source of truth

