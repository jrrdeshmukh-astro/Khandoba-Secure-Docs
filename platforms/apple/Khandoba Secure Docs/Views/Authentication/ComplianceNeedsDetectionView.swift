//
//  ComplianceNeedsDetectionView.swift
//  Khandoba Secure Docs
//
//  View to detect and select compliance regime needs
//  Replaces Role Selection with intelligent compliance detection
//

import SwiftUI
import SwiftData

struct ComplianceNeedsDetectionView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var complianceDetectionService: ComplianceDetectionService
    
    @State private var detectedRecommendations: [ComplianceRecommendation] = []
    @State private var selectedFrameworks: Set<ComplianceFramework> = []
    @State private var isDetecting = false
    @State private var showProfessionalKYC = false
    @State private var errorMessage: String?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.xl) {
                    // Header
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        Text("Compliance Needs")
                            .font(theme.typography.title)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.bold)
                        
                        Text("We'll automatically detect which compliance frameworks you need based on your data")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, UnifiedTheme.Spacing.xl)
                    .padding(.horizontal, UnifiedTheme.Spacing.lg)
                    
                    // Auto-Detect Button
                    if detectedRecommendations.isEmpty {
                        Button {
                            detectComplianceNeeds()
                        } label: {
                            HStack {
                                if isDetecting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Auto-Detect Compliance Needs")
                                }
                            }
                            .font(theme.typography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(UnifiedTheme.Spacing.lg)
                            .background(
                                LinearGradient(
                                    colors: [colors.primary, colors.primary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            .shadow(color: colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isDetecting)
                        .padding(.horizontal, UnifiedTheme.Spacing.lg)
                    }
                    
                    // Detected Recommendations
                    if !detectedRecommendations.isEmpty {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Detected Compliance Needs")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            ForEach(detectedRecommendations) { recommendation in
                                ComplianceFrameworkCard(
                                    recommendation: recommendation,
                                    isSelected: selectedFrameworks.contains(recommendation.framework),
                                    onToggle: {
                                        if selectedFrameworks.contains(recommendation.framework) {
                                            selectedFrameworks.remove(recommendation.framework)
                                        } else {
                                            selectedFrameworks.insert(recommendation.framework)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, UnifiedTheme.Spacing.lg)
                    }
                    
                    // Manual Selection
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("Or Select Manually")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        ForEach(ComplianceFramework.allCases) { framework in
                            if !detectedRecommendations.contains(where: { $0.framework == framework }) {
                                ComplianceFrameworkCard(
                                    recommendation: ComplianceRecommendation(
                                        framework: framework,
                                        priority: .optional,
                                        confidence: 0.0,
                                        reason: "Manual selection",
                                        requirements: []
                                    ),
                                    isSelected: selectedFrameworks.contains(framework),
                                    onToggle: {
                                        if selectedFrameworks.contains(framework) {
                                            selectedFrameworks.remove(framework)
                                        } else {
                                            selectedFrameworks.insert(framework)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.lg)
                    
                    // Professional KYC Option
                    if !selectedFrameworks.isEmpty {
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Toggle(isOn: $showProfessionalKYC) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Professional KYC Verification")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text("Required for certain compliance frameworks")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                            .tint(colors.primary)
                        }
                        .padding(UnifiedTheme.Spacing.md)
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                        .padding(.horizontal, UnifiedTheme.Spacing.lg)
                    }
                    
                    // Continue Button
                    if !selectedFrameworks.isEmpty {
                        Button {
                            completeComplianceSelection()
                        } label: {
                            Text("Continue")
                                .font(theme.typography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(UnifiedTheme.Spacing.lg)
                                .background(colors.primary)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .padding(.horizontal, UnifiedTheme.Spacing.lg)
                        .padding(.top, UnifiedTheme.Spacing.md)
                    }
                    
                    // Skip Option
                    Button {
                        // Skip compliance selection - proceed with defaults
                        UserDefaults.standard.set(true, forKey: "compliance_selection_complete")
                    } label: {
                        Text("Skip for Now")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding(.top, UnifiedTheme.Spacing.sm)
                }
            }
        }
        .navigationTitle("Compliance Needs")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func detectComplianceNeeds() {
        isDetecting = true
        
        Task {
            guard let user = authService.currentUser else {
                await MainActor.run {
                    isDetecting = false
                    errorMessage = "User not found"
                }
                return
            }
            
            // Fetch user's vaults and documents
            // Note: SwiftData predicates don't handle optional chaining well, so fetch all and filter
            let vaultDescriptor = FetchDescriptor<Vault>()
            let documentDescriptor = FetchDescriptor<Document>()
            
            let allVaults = (try? modelContext.fetch(vaultDescriptor)) ?? []
            let vaults = allVaults.filter { $0.owner?.id == user.id }
            let allDocuments = (try? modelContext.fetch(documentDescriptor)) ?? []
            let userDocuments = allDocuments.filter { document in
                vaults.contains { $0.id == document.vault?.id }
            }
            
            let recommendations = await complianceDetectionService.detectComplianceRegime(
                for: user,
                vaults: vaults,
                documents: userDocuments
            )
            
            await MainActor.run {
                detectedRecommendations = recommendations
                // Auto-select required frameworks
                selectedFrameworks = Set(recommendations.filter { $0.priority == .required }.map { $0.framework })
                isDetecting = false
            }
        }
    }
    
    private func completeComplianceSelection() {
        // Save selected frameworks
        let frameworkNames = selectedFrameworks.map { $0.rawValue }
        UserDefaults.standard.set(frameworkNames, forKey: "selected_compliance_frameworks")
        UserDefaults.standard.set(showProfessionalKYC, forKey: "professional_kyc_enabled")
        UserDefaults.standard.set(true, forKey: "compliance_selection_complete")
        
        // If professional KYC is enabled, navigate to KYC view
        // This will be handled by ContentView checking the flag
    }
}

struct ComplianceFrameworkCard: View {
    let recommendation: ComplianceRecommendation
    let isSelected: Bool
    let onToggle: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button {
            onToggle()
        } label: {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? colors.primary : colors.textTertiary)
                    .font(.title3)
                
                // Framework Icon
                Image(systemName: recommendation.framework.icon)
                    .foregroundColor(colors.primary)
                    .font(.title2)
                    .frame(width: 40)
                
                // Framework Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(recommendation.framework.rawValue)
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Spacer()
                        
                        // Priority Badge
                        Text(recommendation.priority.rawValue)
                            .font(theme.typography.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor(for: recommendation.priority, colors: colors))
                            .cornerRadius(8)
                    }
                    
                    Text(recommendation.framework.description)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(2)
                    
                    if !recommendation.reason.isEmpty {
                        Text(recommendation.reason)
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textTertiary)
                            .padding(.top, 2)
                    }
                    
                    if recommendation.confidence > 0 {
                        HStack {
                            Text("Confidence: \(Int(recommendation.confidence * 100))%")
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textTertiary)
                            
                            ProgressView(value: recommendation.confidence)
                                .progressViewStyle(LinearProgressViewStyle(tint: colors.primary))
                                .frame(height: 4)
                        }
                    }
                }
            }
            .padding(UnifiedTheme.Spacing.md)
            .background(isSelected ? colors.primary.opacity(0.1) : colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: UnifiedTheme.CornerRadius.md)
                    .stroke(isSelected ? colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func priorityColor(for priority: CompliancePriority, colors: UnifiedTheme.Colors) -> Color {
        switch priority {
        case .required:
            return colors.error
        case .recommended:
            return colors.warning
        case .optional:
            return colors.secondary
        }
    }
}

extension ComplianceFramework: Identifiable {
    public var id: String { rawValue }
}

