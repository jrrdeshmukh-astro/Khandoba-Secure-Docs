//
//  VoiceReportGeneratorView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import SwiftUI
import SwiftData

struct VoiceReportGeneratorView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    let vault: Vault
    
    @StateObject private var voiceMemoService = VoiceMemoService()
    @StateObject private var intelReportService = IntelReportService()
    @StateObject private var threatService = ThreatMonitoringService()
    
    @State private var isGenerating = false
    @State private var generatedDocument: Document?
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(colors.primary)
                            
                            Text("AI Voice Report")
                                .font(theme.typography.title2)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.bold)
                            
                            Text("Generate AI-narrated threat analysis")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // Info Card
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(colors.info)
                                Text("What This Does")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                FeatureCheckmark(
                                    text: "Analyzes all vault documents and access patterns",
                                    colors: colors
                                )
                                FeatureCheckmark(
                                    text: "Detects threats and security anomalies",
                                    colors: colors
                                )
                                FeatureCheckmark(
                                    text: "Generates comprehensive AI narrative",
                                    colors: colors
                                )
                                FeatureCheckmark(
                                    text: "Converts report to voice memo",
                                    colors: colors
                                )
                                FeatureCheckmark(
                                    text: "Saves to your Intel Vault automatically",
                                    colors: colors
                                )
                            }
                        }
                        .padding(UnifiedTheme.Spacing.md)
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                        
                        // Generate Button
                        if !isGenerating && generatedDocument == nil {
                            Button {
                                generateVoiceReport()
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Generate AI Voice Report")
                                    Image(systemName: "mic.fill")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, UnifiedTheme.Spacing.xl)
                        }
                        
                        // Generating State
                        if isGenerating {
                            VStack(spacing: UnifiedTheme.Spacing.md) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(colors.primary)
                                
                                Text("Analyzing vault and generating report...")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                    ProgressStep(text: "Scanning documents", colors: colors)
                                    ProgressStep(text: "Analyzing threat patterns", colors: colors)
                                    ProgressStep(text: "Generating AI narrative", colors: colors)
                                    ProgressStep(text: "Creating voice memo", colors: colors)
                                }
                                .padding(.top, UnifiedTheme.Spacing.md)
                            }
                            .padding(UnifiedTheme.Spacing.xl)
                        }
                        
                        // Success State
                        if let document = generatedDocument {
                            VStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(colors.success)
                                
                                Text("Voice Report Generated!")
                                    .font(theme.typography.title2)
                                    .foregroundColor(colors.textPrimary)
                                    .fontWeight(.bold)
                                
                                Text("Your AI-narrated threat analysis has been saved to the Intel Vault")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                // Document Info
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(colors.primary)
                                        Text(document.name)
                                            .font(theme.typography.headline)
                                            .foregroundColor(colors.textPrimary)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "waveform")
                                            .foregroundColor(colors.textSecondary)
                                        Text("Voice Memo • \(formatFileSize(document.fileSize))")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                }
                                .padding(UnifiedTheme.Spacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                
                                Button {
                                    dismiss()
                                } label: {
                                    Text("Done")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            .padding(UnifiedTheme.Spacing.xl)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                    .disabled(isGenerating)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func generateVoiceReport() {
        isGenerating = true
        
        Task {
            do {
                // Step 1: Generate intel report
                let report = await intelReportService.generateIntelReport(for: [vault])
                
                // Step 2: Analyze threat level
                let threatLevel = await threatService.analyzeThreatLevel(for: vault)
                let anomalyScore = threatService.anomalyScore
                
                // Step 3: Generate voice memo and save to vault
                let document = try await voiceMemoService.generateThreatReportVoiceMemo(
                    for: vault,
                    report: report,
                    threatLevel: threatLevel,
                    anomalyScore: anomalyScore
                )
                
                await MainActor.run {
                    generatedDocument = document
                    isGenerating = false
                    showSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - Supporting Views

struct FeatureCheckmark: View {
    let text: String
    let colors: UnifiedTheme.Colors
    @Environment(\.unifiedTheme) var theme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(colors.success)
                .font(.caption)
            
            Text(text)
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
            
            Spacer()
        }
    }
}

struct ProgressStep: View {
    let text: String
    let colors: UnifiedTheme.Colors
    @Environment(\.unifiedTheme) var theme
    
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)
            
            Text(text)
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
            
            Spacer()
        }
    }
}

#Preview {
    VoiceReportGeneratorView(vault: Vault(name: "Sample Vault", vaultDescription: nil, keyType: "single"))
        .environmentObject(AuthenticationService())
}

