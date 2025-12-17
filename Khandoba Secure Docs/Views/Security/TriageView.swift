//
//  TriageView.swift
//  Khandoba Secure Docs
//
//  Real-time threat triage and remediation center
//

import SwiftUI
import SwiftData
import Charts
import UIKit

struct TriageView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @EnvironmentObject var vaultService: VaultService
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var threatService = ThreatMonitoringService()
    @StateObject private var mlService = MLThreatAnalysisService()
    @StateObject private var autoTriageService = AutomaticTriageService()
    
    @State private var allThreats: [ThreatItem] = []
    @State private var dataLeaks: [DataLeak] = []
    @State private var isAnalyzing = false
    @State private var selectedThreat: ThreatItem?
    @State private var showRemediation = false
    @State private var showGuidedRemediation = false
    @State private var refreshTimer: Timer?
    @State private var screenMonitoringTimer: Timer?
    @State private var isScreenCaptured = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Overall Threat Status
                        OverallThreatStatusCard(
                            threats: allThreats,
                            leaks: dataLeaks
                        )
                        .padding(.horizontal)
                        
                        // Active Threats Section
                        if !allThreats.isEmpty {
                            ThreatsSection(
                                threats: allThreats,
                                onSelect: { threat in
                                    selectedThreat = threat
                                    showRemediation = true
                                },
                                onResolve: { threat in
                                    resolveThreat(threat)
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // Data Leaks Section
                        if !dataLeaks.isEmpty {
                            DataLeaksSection(
                                leaks: dataLeaks,
                                onSelect: { leak in
                                    selectedThreat = ThreatItem.fromLeak(leak)
                                    showRemediation = true
                                },
                                onResolve: { leak in
                                    resolveLeak(leak)
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // Automatic Triage Results
                        if !autoTriageService.triageResults.isEmpty {
                            AutomaticTriageResultsSection(
                                results: autoTriageService.triageResults,
                                onStartRemediation: { result in
                                    Task {
                                        await autoTriageService.startGuidedRemediation(for: result)
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // Empty State
                        if allThreats.isEmpty && dataLeaks.isEmpty && autoTriageService.triageResults.isEmpty {
                            EmptyTriageState()
                                .padding()
                        }
                        
                        // Remediation Suggestions
                        if !allThreats.isEmpty || !dataLeaks.isEmpty {
                            RemediationSuggestionsCard(
                                threats: allThreats,
                                leaks: dataLeaks
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Triage")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await analyzeAllThreats()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showRemediation) {
                if let threat = selectedThreat {
                    ThreatRemediationView(threat: threat) {
                        showRemediation = false
                        Task {
                            await analyzeAllThreats()
                        }
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showGuidedRemediation) {
                GuidedRemediationWizard(triageService: autoTriageService) {
                    showGuidedRemediation = false
                    Task {
                        await autoTriageService.performAutomaticTriage()
                        await analyzeAllThreats()
                    }
                }
            }
            .onChange(of: autoTriageService.currentRemediationFlow) { oldValue, newValue in
                // Auto-show guided remediation when flow starts
                if newValue != nil && oldValue == nil {
                    showGuidedRemediation = true
                }
            }
            .task {
                // Configure automatic triage service
                if let userID = authService.currentUser?.id {
                    autoTriageService.configure(modelContext: modelContext, userID: userID)
                }
                
                // Run automatic triage first
                await autoTriageService.performAutomaticTriage()
                
                // Then run traditional analysis
                await analyzeAllThreats()
                startRealTimeMonitoring()
                
                // Execute auto-actions for critical threats
                await executeAutoActions()
            }
            .onDisappear {
                stopRealTimeMonitoring()
            }
            .refreshable {
                await analyzeAllThreats()
            }
        }
    }
    
    // MARK: - Threat Analysis
    
    private func analyzeAllThreats() async {
        isAnalyzing = true
        
        guard let userID = authService.currentUser?.id else {
            isAnalyzing = false
            return
        }
        
        // Load all vaults
        vaultService.configure(modelContext: modelContext, userID: userID)
        try? await vaultService.loadVaults()
        let vaults = vaultService.vaults
        
        var detectedThreats: [ThreatItem] = []
        var detectedLeaks: [DataLeak] = []
        
        // Configure services
        threatService.configure(vaultService: vaultService, supabaseService: supabaseService)
        mlService.configure(vaultService: vaultService)
        
        // Analyze each vault
        for vault in vaults {
            // Traditional threat detection
            // Note: threatLevel is calculated but not used in this loop
            _ = await threatService.analyzeThreatLevel(for: vault)
            let threats = await threatService.detectThreats(for: vault)
            
            for threat in threats {
                detectedThreats.append(ThreatItem(
                    id: UUID(),
                    type: .threat(threat.type),
                    severity: threat.severity,
                    title: threatTypeTitle(threat.type),
                    description: threat.description,
                    vaultName: vault.name,
                    vaultID: vault.id,
                    timestamp: threat.timestamp,
                    source: .threatMonitoring
                ))
            }
            
            // ML-based analysis
            let geoMetrics = await mlService.analyzeGeoClassification(for: vault)
            let accessMetrics = await mlService.analyzeAccessPatterns(for: vault)
            let tagMetrics = mlService.analyzeTagPatterns(for: vault)
            
            // Detect data leaks
            let leaks = detectDataLeaks(
                vault: vault,
                geoMetrics: geoMetrics,
                accessMetrics: accessMetrics,
                tagMetrics: tagMetrics
            )
            detectedLeaks.append(contentsOf: leaks)
            
            // High-risk ML detections
            if geoMetrics.riskScore > 0.7 {
                detectedThreats.append(ThreatItem(
                    id: UUID(),
                    type: .geographicAnomaly,
                    severity: .high,
                    title: "Geographic Anomaly Detected",
                    description: "ML detected unusual location patterns in vault '\(vault.name)'",
                    vaultName: vault.name,
                    vaultID: vault.id,
                    timestamp: Date(),
                    source: .mlAnalysis
                ))
            }
            
            if accessMetrics.burstsDetected > 0 {
                detectedThreats.append(ThreatItem(
                    id: UUID(),
                    type: .accessBurst,
                    severity: .high,
                    title: "Access Burst Detected",
                    description: "\(accessMetrics.burstsDetected) burst pattern(s) detected in vault '\(vault.name)'",
                    vaultName: vault.name,
                    vaultID: vault.id,
                    timestamp: Date(),
                    source: .mlAnalysis
                ))
            }
            
            if tagMetrics.exfiltrationRisk > 0.6 {
                detectedThreats.append(ThreatItem(
                    id: UUID(),
                    type: .dataExfiltration,
                    severity: .critical,
                    title: "Potential Data Exfiltration",
                    description: "High exfiltration risk detected in vault '\(vault.name)'",
                    vaultName: vault.name,
                    vaultID: vault.id,
                    timestamp: Date(),
                    source: .mlAnalysis
                ))
            }
        }
        
        // Sort by severity and timestamp
        detectedThreats.sort { threat1, threat2 in
            if threat1.severity != threat2.severity {
                return threat1.severity.rawValue > threat2.severity.rawValue
            }
            return threat1.timestamp > threat2.timestamp
        }
        
        await MainActor.run {
            allThreats = detectedThreats
            dataLeaks = detectedLeaks
            isAnalyzing = false
        }
        
        // Send real-time alerts
        await sendRealTimeAlerts(threats: detectedThreats, leaks: detectedLeaks)
    }
    
    // MARK: - Data Leak Detection
    
    private func detectDataLeaks(
        vault: Vault,
        geoMetrics: GeoThreatMetrics,
        accessMetrics: AccessPatternMetrics,
        tagMetrics: TagThreatMetrics
    ) -> [DataLeak] {
        var leaks: [DataLeak] = []
        
        // Leak 1: Unusual document uploads (potential data dump)
        if let documents = vault.documents {
            let last24h = documents.filter {
                $0.uploadedAt > Date().addingTimeInterval(-86400)
            }
            
            if last24h.count > 20 {
                leaks.append(DataLeak(
                    id: UUID(),
                    type: .massUpload,
                    severity: .high,
                    title: "Mass Document Upload Detected",
                    description: "\(last24h.count) documents uploaded in last 24 hours to vault '\(vault.name)'",
                    vaultName: vault.name,
                    vaultID: vault.id,
                    timestamp: Date(),
                    affectedDocuments: last24h.count
                ))
            }
        }
        
        // Leak 2: Geographic anomaly (account sharing)
        if geoMetrics.uniqueLocations > 5 {
            leaks.append(DataLeak(
                id: UUID(),
                type: .accountSharing,
                severity: .medium,
                title: "Potential Account Sharing",
                description: "Vault '\(vault.name)' accessed from \(geoMetrics.uniqueLocations) different locations",
                vaultName: vault.name,
                vaultID: vault.id,
                timestamp: Date(),
                affectedDocuments: 0
            ))
        }
        
        // Leak 3: Suspicious tag patterns
        if !tagMetrics.suspiciousTags.isEmpty {
            leaks.append(DataLeak(
                id: UUID(),
                type: .suspiciousContent,
                severity: .high,
                title: "Suspicious Content Patterns",
                description: "Suspicious tags detected in vault '\(vault.name)': \(tagMetrics.suspiciousTags.joined(separator: ", "))",
                vaultName: vault.name,
                vaultID: vault.id,
                timestamp: Date(),
                affectedDocuments: 0
            ))
        }
        
        // Leak 4: High deletion rate
        if let logs = vault.accessLogs {
            let deletions = logs.filter { $0.accessType == "deleted" }
            let deletionRate = Double(deletions.count) / Double(max(logs.count, 1))
            
            if deletionRate > 0.3 {
                leaks.append(DataLeak(
                    id: UUID(),
                    type: .massDeletion,
                    severity: .critical,
                    title: "Mass Deletion Detected",
                    description: "\(Int(deletionRate * 100))% of access events are deletions in vault '\(vault.name)'",
                    vaultName: vault.name,
                    vaultID: vault.id,
                    timestamp: Date(),
                    affectedDocuments: deletions.count
                ))
            }
        }
        
        return leaks
    }
    
    // MARK: - Real-Time Monitoring
    
    private func startRealTimeMonitoring() {
        // Refresh every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await analyzeAllThreats()
                await autoTriageService.performAutomaticTriage()
            }
        }
        
        // Monitor screen capture continuously
        screenMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkScreenCapture()
        }
        
        // Listen for screen capture notifications
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            checkScreenCapture()
        }
    }
    
    private func stopRealTimeMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        screenMonitoringTimer?.invalidate()
        screenMonitoringTimer = nil
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    private func checkScreenCapture() {
        // Use screen from context instead of deprecated UIScreen.main
        // Note: UIApplication.shared is unavailable in app extensions
        
        // Check if we're in an app extension
        let isExtension = Bundle.main.bundlePath.hasSuffix(".appex")
        
        if isExtension {
            // Screen capture detection not available in app extensions
            // Skip this check in extensions
            return
        }
        
        // Get screen capture status
        // For now, use UIScreen.main (deprecated but still functional)
        // In iOS 26+, we'd prefer to use windowScene.screen, but UIApplication.shared
        // is unavailable in extensions, so we use the deprecated API as fallback
        let captured = UIScreen.main.isCaptured
        
        if captured && !isScreenCaptured {
            // Screen capture just started - trigger automatic triage
            print("Screen monitoring detected - triggering automatic triage")
            Task {
                await autoTriageService.performAutomaticTriage()
                // Auto-execute critical actions
                await executeAutoActions()
            }
        }
        
        isScreenCaptured = captured
    }
    
    // MARK: - Alert System
    
    private func sendRealTimeAlerts(threats: [ThreatItem], leaks: [DataLeak]) async {
        // Send push notifications for critical threats
        let criticalThreats = threats.filter { $0.severity == .critical }
        
        for threat in criticalThreats {
            PushNotificationService.shared.sendSecurityAlertNotification(
                title: "Critical Threat Detected",
                body: threat.title,
                threatType: threat.type.rawValue
            )
        }
        
        // Send alerts for data leaks
        for leak in leaks.filter({ $0.severity == .critical || $0.severity == .high }) {
            PushNotificationService.shared.sendSecurityAlertNotification(
                title: "Data Leak Detected",
                body: leak.title,
                threatType: leak.type.rawValue
            )
        }
    }
    
    // MARK: - Auto Actions
    
    private func executeAutoActions() async {
        // Execute automatic actions for critical threats
        for result in autoTriageService.triageResults where result.severity == .critical {
            // Create a temporary flow for auto-actions if one doesn't exist
            var flow = autoTriageService.currentRemediationFlow
            if flow == nil {
                flow = RemediationFlow(
                    id: UUID(),
                    triageResult: result,
                    currentStep: 0,
                    answers: [:],
                    recommendedActions: result.recommendedActions,
                    completedActions: []
                )
                autoTriageService.currentRemediationFlow = flow
            }
            
            guard let flow = flow else { continue }
            
            for action in result.autoActions {
                do {
                    try await autoTriageService.executeAction(action, in: flow)
                    print("Auto-executed action: \(actionTitle(action))")
                } catch {
                    print(" Failed to execute auto-action: \(error.localizedDescription)")
                }
            }
            
            // If screen monitoring detected, start guided remediation
            if result.type == .screenMonitoring {
                await autoTriageService.startGuidedRemediation(for: result)
            }
        }
    }
    
    private func actionTitle(_ action: RemediationAction) -> String {
        switch action {
        case .closeAllVaults: return "Close All Vaults"
        case .lockVault: return "Lock Vault"
        case .revokeNominees: return "Revoke Nominees"
        case .revokeAllNominees: return "Revoke All Nominees"
        case .revokeAllSessions: return "Revoke All Sessions"
        case .redactDocuments: return "Redact Documents"
        case .restrictDocumentAccess: return "Restrict Document Access"
        case .changeVaultPassword: return "Change Vault Password"
        case .changeAllPasswords: return "Change All Passwords"
        case .recordMonitoringIP: return "Record Monitoring IP"
        case .reviewAccessLogs: return "Review Access Logs"
        case .reviewDocumentSharing: return "Review Document Sharing"
        case .enableDualKeyProtection: return "Enable Dual-Key Protection"
        case .enableEnhancedMonitoring: return "Enable Enhanced Monitoring"
        }
    }
    
    // MARK: - Resolution
    
    private func resolveThreat(_ threat: ThreatItem) {
        // Mark threat as resolved
        allThreats.removeAll { $0.id == threat.id }
        
        // Log resolution
        print("Threat resolved: \(threat.title)")
    }
    
    private func resolveLeak(_ leak: DataLeak) {
        // Mark leak as resolved
        dataLeaks.removeAll { $0.id == leak.id }
        
        // Log resolution
        print("Data leak resolved: \(leak.title)")
    }
    
    // MARK: - Helpers
    
    private func threatTypeTitle(_ type: ThreatType) -> String {
        switch type {
        case .rapidAccess: return "Rapid Access Pattern"
        case .unusualLocation: return "Unusual Location"
        case .suspiciousDeletion: return "Suspicious Deletion"
        case .bruteForce: return "Brute Force Attempt"
        case .unauthorizedAccess: return "Unauthorized Access"
        }
    }
}

// MARK: - Threat Item Model

struct ThreatItem: Identifiable {
    let id: UUID
    let type: ThreatItemType
    let severity: ThreatLevel
    let title: String
    let description: String
    let vaultName: String
    let vaultID: UUID
    let timestamp: Date
    let source: ThreatSource
    
    static func fromLeak(_ leak: DataLeak) -> ThreatItem {
        ThreatItem(
            id: leak.id,
            type: .dataLeak(leak.type),
            severity: leak.severity,
            title: leak.title,
            description: leak.description,
            vaultName: leak.vaultName,
            vaultID: leak.vaultID,
            timestamp: leak.timestamp,
            source: .mlAnalysis
        )
    }
}

enum ThreatItemType {
    case threat(ThreatType)
    case geographicAnomaly
    case accessBurst
    case dataExfiltration
    case dataLeak(DataLeakType)
    
    var rawValue: String {
        switch self {
        case .threat(let type):
            switch type {
            case .rapidAccess: return "rapid_access"
            case .unusualLocation: return "unusual_location"
            case .suspiciousDeletion: return "suspicious_deletion"
            case .bruteForce: return "brute_force"
            case .unauthorizedAccess: return "unauthorized_access"
            }
        case .geographicAnomaly: return "geographic_anomaly"
        case .accessBurst: return "access_burst"
        case .dataExfiltration: return "data_exfiltration"
        case .dataLeak(let type): return type.rawValue
        }
    }
}

enum ThreatSource {
    case threatMonitoring
    case mlAnalysis
    case userReport
}

// MARK: - Data Leak Model

struct DataLeak: Identifiable {
    let id: UUID
    let type: DataLeakType
    let severity: ThreatLevel
    let title: String
    let description: String
    let vaultName: String
    let vaultID: UUID
    let timestamp: Date
    let affectedDocuments: Int
}

enum DataLeakType: String {
    case massUpload = "mass_upload"
    case accountSharing = "account_sharing"
    case suspiciousContent = "suspicious_content"
    case massDeletion = "mass_deletion"
    case unauthorizedAccess = "unauthorized_access"
    
    var icon: String {
        switch self {
        case .massUpload: return "arrow.up.doc.fill"
        case .accountSharing: return "person.2.fill"
        case .suspiciousContent: return "exclamationmark.shield.fill"
        case .massDeletion: return "trash.fill"
        case .unauthorizedAccess: return "lock.triangle.fill"
        }
    }
}

// MARK: - Overall Threat Status Card

struct OverallThreatStatusCard: View {
    let threats: [ThreatItem]
    let leaks: [DataLeak]
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        let criticalCount = threats.filter { $0.severity == .critical }.count + leaks.filter { $0.severity == .critical }.count
        let highCount = threats.filter { $0.severity == .high }.count + leaks.filter { $0.severity == .high }.count
        let totalCount = threats.count + leaks.count
        
        let overallSeverity: ThreatLevel = {
            if criticalCount > 0 { return .critical }
            if highCount > 0 { return .high }
            if totalCount > 0 { return .medium }
            return .low
        }()
        
        StandardCard {
            VStack(spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Security Status")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        Text(overallSeverity.rawValue)
                            .font(theme.typography.largeTitle)
                            .foregroundColor(overallSeverity.color)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(totalCount)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(overallSeverity.color)
                        
                        Text("Active Issues")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                if totalCount > 0 {
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        if criticalCount > 0 {
                            ThreatBadge(count: criticalCount, level: .critical)
                        }
                        if highCount > 0 {
                            ThreatBadge(count: highCount, level: .high)
                        }
                        ThreatBadge(count: totalCount - criticalCount - highCount, level: .medium)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(colors.success)
                        Text("All systems secure")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textPrimary)
                    }
                }
            }
        }
    }
}

struct ThreatBadge: View {
    let count: Int
    let level: ThreatLevel
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if count > 0 {
            HStack(spacing: 4) {
                Text("\(count)")
                    .font(theme.typography.caption)
                    .fontWeight(.bold)
                Text(level.rawValue)
                    .font(theme.typography.caption2)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(level.color)
            .cornerRadius(UnifiedTheme.CornerRadius.sm)
        }
    }
}

// MARK: - Threats Section

struct ThreatsSection: View {
    let threats: [ThreatItem]
    let onSelect: (ThreatItem) -> Void
    let onResolve: (ThreatItem) -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
            HStack {
                Text("Active Threats")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                Text("\(threats.count)")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textSecondary)
            }
            .padding(.horizontal)
            
            ForEach(threats) { threat in
                ThreatRow(
                    threat: threat,
                    onTap: { onSelect(threat) },
                    onResolve: { onResolve(threat) }
                )
            }
        }
    }
}

struct ThreatRow: View {
    let threat: ThreatItem
    let onTap: () -> Void
    let onResolve: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                HStack {
                    Image(systemName: iconForThreatType(threat.type))
                        .foregroundColor(threat.severity.color)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(threat.title)
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text(threat.severity.rawValue)
                                .font(theme.typography.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(threat.severity.color)
                                .cornerRadius(4)
                        }
                        
                        Text(threat.description)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                            .lineLimit(2)
                        
                        HStack {
                            Label(threat.vaultName, systemImage: "lock.shield.fill")
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textTertiary)
                            
                            Spacer()
                            
                            Text(threat.timestamp, style: .relative)
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textTertiary)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Spacer()
                    
                    Button {
                        onResolve()
                    } label: {
                        Label("Resolve", systemImage: "checkmark.circle.fill")
                            .font(theme.typography.caption)
                    }
                    .foregroundColor(colors.success)
                }
            }
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private func iconForThreatType(_ type: ThreatItemType) -> String {
        switch type {
        case .threat(let threatType):
            switch threatType {
            case .rapidAccess: return "bolt.fill"
            case .unusualLocation: return "mappin.circle.fill"
            case .suspiciousDeletion: return "trash.fill"
            case .bruteForce: return "lock.shield.fill"
            case .unauthorizedAccess: return "person.crop.circle.badge.xmark"
            }
        case .geographicAnomaly: return "map.fill"
        case .accessBurst: return "waveform.path"
        case .dataExfiltration: return "arrow.up.doc.fill"
        case .dataLeak(let leakType): return leakType.icon
        }
    }
}

// MARK: - Data Leaks Section

struct DataLeaksSection: View {
    let leaks: [DataLeak]
    let onSelect: (DataLeak) -> Void
    let onResolve: (DataLeak) -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
            HStack {
                Text("Data Leaks")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                Text("\(leaks.count)")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.error)
            }
            .padding(.horizontal)
            
            ForEach(leaks) { leak in
                DataLeakRow(
                    leak: leak,
                    onTap: { onSelect(leak) },
                    onResolve: { onResolve(leak) }
                )
            }
        }
    }
}

struct DataLeakRow: View {
    let leak: DataLeak
    let onTap: () -> Void
    let onResolve: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                HStack {
                    Image(systemName: leak.type.icon)
                        .foregroundColor(leak.severity.color)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(leak.title)
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text(leak.severity.rawValue)
                                .font(theme.typography.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(leak.severity.color)
                                .cornerRadius(4)
                        }
                        
                        Text(leak.description)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                            .lineLimit(2)
                        
                        if leak.affectedDocuments > 0 {
                            HStack {
                                Label("\(leak.affectedDocuments) documents affected", systemImage: "doc.fill")
                                    .font(theme.typography.caption2)
                                    .foregroundColor(colors.error)
                            }
                        }
                        
                        HStack {
                            Label(leak.vaultName, systemImage: "lock.shield.fill")
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textTertiary)
                            
                            Spacer()
                            
                            Text(leak.timestamp, style: .relative)
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textTertiary)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Button {
                        onTap()
                    } label: {
                        Label("View Details", systemImage: "info.circle")
                            .font(theme.typography.caption)
                    }
                    .foregroundColor(colors.primary)
                    
                    Spacer()
                    
                    Button {
                        onResolve()
                    } label: {
                        Label("Resolve", systemImage: "checkmark.circle.fill")
                            .font(theme.typography.caption)
                    }
                    .foregroundColor(colors.success)
                }
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Remediation Suggestions Card

struct RemediationSuggestionsCard: View {
    let threats: [ThreatItem]
    let leaks: [DataLeak]
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var autoTriageService: AutomaticTriageService
    @StateObject private var aiService = ThreatRemediationAIService()
    @State private var remediations: [Remediation] = []
    @State private var isLoading = true
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(colors.warning)
                    
                    Text("Remediation Suggestions")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                Divider()
                
                if isLoading && remediations.isEmpty {
                    // Show placeholder while loading
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.surface)
                            .frame(height: 80)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.surface)
                            .frame(height: 80)
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        ForEach(remediations) { remediation in
                            RemediationRow(remediation: remediation)
                        }
                    }
                }
            }
        }
        .task {
            await generateAIRemediations()
        }
    }
    
    private func generateAIRemediations() async {
        // Show quick remediation steps immediately (no AI needed)
        var quickRemediations: [Remediation] = []
        
        for threat in threats {
            let quickSteps = getQuickRemediationSteps(for: threat)
            let priority: RemediationPriority = threat.severity == .critical ? .immediate :
                                                threat.severity == .high ? .high :
                                                threat.severity == .medium ? .medium : .low
            
            quickRemediations.append(Remediation(
                id: UUID(),
                priority: priority,
                title: generateRemediationTitle(for: threat),
                description: generateRemediationDescription(for: threat),
                steps: quickSteps
            ))
        }
        
        for leak in leaks {
            let threatItem = ThreatItem.fromLeak(leak)
            let quickSteps = getQuickRemediationSteps(for: threatItem)
            let priority: RemediationPriority = leak.severity == .critical ? .immediate :
                                                leak.severity == .high ? .high :
                                                leak.severity == .medium ? .medium : .low
            
            quickRemediations.append(Remediation(
                id: UUID(),
                priority: priority,
                title: generateRemediationTitle(for: leak),
                description: generateRemediationDescription(for: leak),
                steps: quickSteps
            ))
        }
        
        // Show quick steps immediately
        await MainActor.run {
            remediations = quickRemediations.sorted { $0.priority.rawValue > $1.priority.rawValue }
            isLoading = false
        }
        
        // Optionally enhance with AI in background (with timeout)
        Task {
            var aiRemediations: [Remediation] = []
            
            // Generate AI-powered remediation for each threat (with timeout)
            for threat in threats.prefix(3) { // Limit to 3 to avoid long waits
                let context = ThreatContext(
                    timeWindow: extractTimeWindow(from: threat.description),
                    accessCount: extractAccessCount(from: threat.description),
                    location: extractLocation(from: threat.description),
                    distance: nil,
                    deletedCount: threat.description.contains("deletion") ? 1 : nil,
                    documentCount: nil,
                    locationCount: nil,
                    burstCount: nil
                )
                
                let steps = await withTimeout(seconds: 3) {
                    await aiService.generateRemediationSteps(
                        for: threat,
                        vaultName: threat.vaultName,
                        threatDetails: context
                    )
                } ?? getQuickRemediationSteps(for: threat)
                
                let priority: RemediationPriority = threat.severity == .critical ? .immediate :
                                                    threat.severity == .high ? .high :
                                                    threat.severity == .medium ? .medium : .low
                
                aiRemediations.append(Remediation(
                    id: UUID(),
                    priority: priority,
                    title: generateRemediationTitle(for: threat),
                    description: generateRemediationDescription(for: threat),
                    steps: steps
                ))
            }
            
            // Update with AI-enhanced steps if available
            if !aiRemediations.isEmpty {
                await MainActor.run {
                    // Merge AI steps with quick steps, preferring AI when available
                    var merged = remediations
                    for aiRemediation in aiRemediations {
                        if let index = merged.firstIndex(where: { $0.title == aiRemediation.title }) {
                            merged[index] = aiRemediation
                        } else {
                            merged.append(aiRemediation)
                        }
                    }
                    remediations = merged.sorted { $0.priority.rawValue > $1.priority.rawValue }
                }
            }
        }
    }
    
    /// Get quick remediation steps (no AI, instant)
    private func getQuickRemediationSteps(for threat: ThreatItem) -> [String] {
        switch threat.type {
        case .threat(let type):
            switch type {
            case .rapidAccess:
                return [
                    "Review recent access logs",
                    "Change vault password if unauthorized",
                    "Enable dual-key protection"
                ]
            case .unusualLocation:
                return [
                    "Verify if you accessed from this location",
                    "Review all recent access locations",
                    "Change password if unauthorized"
                ]
            case .suspiciousDeletion:
                return [
                    "Check version history for deleted documents",
                    "Restore important documents if needed",
                    "Review deletion logs"
                ]
            case .bruteForce:
                return [
                    "Immediately change vault password",
                    "Enable dual-key protection",
                    "Review all access attempts"
                ]
            case .unauthorizedAccess:
                return [
                    "Lock the vault immediately",
                    "Change all vault passwords",
                    "Review all access logs"
                ]
            }
        case .geographicAnomaly:
            return [
                "Review access locations",
                "Verify all locations are authorized",
                "Enable location-based alerts"
            ]
        case .accessBurst:
            return [
                "Review burst access patterns",
                "Verify if burst was from automated script",
                "Change password if unauthorized"
            ]
        case .dataExfiltration:
            return [
                "Immediately lock affected vaults",
                "Review all document access",
                "Change all passwords"
            ]
        case .dataLeak:
            return [
                "Review document sharing settings",
                "Revoke unauthorized access",
                "Lock affected vaults"
            ]
        }
    }
    
    /// Helper to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
    
    private func generateRemediationTitle(for threat: ThreatItem) -> String {
        switch threat.type {
        case .threat(let type):
            switch type {
            case .rapidAccess: return "Secure Account from Rapid Access"
            case .unusualLocation: return "Verify Unusual Location Access"
            case .suspiciousDeletion: return "Address Suspicious Deletions"
            case .bruteForce: return "Stop Brute Force Attack"
            case .unauthorizedAccess: return "Lock Down Unauthorized Access"
            }
        case .geographicAnomaly: return "Review Geographic Anomalies"
        case .accessBurst: return "Investigate Access Burst Pattern"
        case .dataExfiltration: return "Contain Data Exfiltration"
        case .dataLeak(let leakType):
            switch leakType {
            case .massUpload: return "Review Mass Upload Activity"
            case .accountSharing: return "Secure Account Sharing"
            case .suspiciousContent: return "Review Suspicious Content"
            case .massDeletion: return "Stop Mass Deletion"
            case .unauthorizedAccess: return "Lock Down Unauthorized Access"
            }
        }
    }
    
    private func generateRemediationDescription(for threat: ThreatItem) -> String {
        return "\(threat.description) Take immediate action to secure your vault."
    }
    
    private func generateRemediationTitle(for leak: DataLeak) -> String {
        switch leak.type {
        case .massUpload: return "Review Mass Upload Activity"
        case .accountSharing: return "Secure Account Sharing"
        case .suspiciousContent: return "Review Suspicious Content"
        case .massDeletion: return "Stop Mass Deletion"
        case .unauthorizedAccess: return "Lock Down Unauthorized Access"
        }
    }
    
    private func generateRemediationDescription(for leak: DataLeak) -> String {
        return "\(leak.description) Immediate remediation required."
    }
    
    private func extractTimeWindow(from description: String) -> String? {
        if let range = description.range(of: #"\d+\s*(second|minute|hour)"#, options: .regularExpression) {
            return String(description[range])
        }
        return nil
    }
    
    private func extractAccessCount(from description: String) -> Int? {
        if let range = description.range(of: #"\d+\s*access"#, options: .regularExpression) {
            let match = String(description[range])
            if let number = Int(match.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return number
            }
        }
        return nil
    }
    
    private func extractLocation(from description: String) -> String? {
        if description.contains("location") {
            return "Multiple locations detected"
        }
        return nil
    }
}

struct Remediation: Identifiable {
    let id: UUID
    let priority: RemediationPriority
    let title: String
    let description: String
    let steps: [String]
}

struct RemediationRow: View {
    let remediation: Remediation
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
            HStack {
                Text(remediation.title)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(priorityLabel(for: remediation.priority))
                    .font(theme.typography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor(for: remediation.priority, colors: colors))
                    .cornerRadius(4)
            }
            
            Text(remediation.description)
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
                .lineLimit(2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Steps:")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .fontWeight(.semibold)
                
                ForEach(Array(remediation.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.primary)
                            .fontWeight(.bold)
                        
                        Text(step)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textPrimary)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(colors.surface.opacity(0.5))
        .cornerRadius(UnifiedTheme.CornerRadius.md)
    }
    
    private func priorityLabel(for priority: RemediationPriority) -> String {
        switch priority {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .immediate: return "Immediate"
        }
    }
    
    private func priorityColor(for priority: RemediationPriority, colors: UnifiedTheme.Colors) -> Color {
        switch priority {
        case .low: return colors.success
        case .medium: return colors.warning
        case .high: return colors.warning
        case .immediate: return colors.error
        }
    }
}

// MARK: - Empty State

struct EmptyTriageState: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.success)
            
            Text("All Clear")
                .font(theme.typography.title)
                .foregroundColor(colors.textPrimary)
            
            Text("No active threats or data leaks detected. Your vaults are secure.")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, UnifiedTheme.Spacing.xl)
    }
}

// MARK: - Threat Remediation View

struct ThreatRemediationView: View {
    let threat: ThreatItem
    let onDismiss: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                    // Threat Details
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(threat.severity.color)
                                    .font(.title)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(threat.title)
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text(threat.severity.rawValue)
                                        .font(theme.typography.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(threat.severity.color)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Divider()
                            
                            Text(threat.description)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textPrimary)
                            
                            HStack {
                                Label(threat.vaultName, systemImage: "lock.shield.fill")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                
                                Spacer()
                                
                                Text(threat.timestamp, style: .date)
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Remediation Steps (optimized - shows quick steps immediately)
                    RemediationStepsCard(threat: threat)
                        .padding(.horizontal)
                    
                    // Available Actions (filtered by app capabilities)
                    AvailableActionsCard(threat: threat)
                        .padding(.horizontal)
                    
                    // Actions
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        Button {
                            // Navigate to vault
                            onDismiss()
                        } label: {
                            Label("View Vault", systemImage: "lock.shield.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button {
                            onDismiss()
                        } label: {
                            Label("Mark as Resolved", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Threat Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
        }
    }
}

// MARK: - Available Actions Card
struct AvailableActionsCard: View {
    let threat: ThreatItem
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var autoTriageService: AutomaticTriageService
    @State private var availableActions: [RemediationAction] = []
    @State private var isLoading = true
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(colors.primary)
                    
                    Text("Available Actions")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                Divider()
                
                if isLoading && availableActions.isEmpty {
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.surface)
                            .frame(height: 40)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.surface)
                            .frame(height: 40)
                    }
                    .padding(.vertical, 8)
                } else if availableActions.isEmpty {
                    Text("No actions available for this threat")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        ForEach(availableActions, id: \.id) { action in
                            HStack {
                                Image(systemName: iconForAction(action))
                                    .foregroundColor(colors.primary)
                                    .frame(width: 24)
                                
                                Text(titleForAction(action))
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .task {
            await loadAvailableActions()
        }
    }
    
    private func loadAvailableActions() async {
        // Get triage result for this threat (match by vault ID and threat type)
        let triageResult = autoTriageService.triageResults.first { result in
            result.vaultID == threat.vaultID
        }
        
        if let result = triageResult {
            // Use filtered actions from triage result (already filtered by app capabilities)
            await MainActor.run {
                availableActions = result.recommendedActions
                isLoading = false
            }
        } else {
            // Fallback: Get basic available actions based on threat type
            // These are actions that are always available in the app
            await MainActor.run {
                availableActions = getBasicActions(for: threat)
                isLoading = false
            }
        }
    }
    
    private func getBasicActions(for threat: ThreatItem) -> [RemediationAction] {
        var actions: [RemediationAction] = []
        
        switch threat.type {
        case .threat(let type):
            switch type {
            case .rapidAccess, .bruteForce, .unauthorizedAccess:
                actions.append(.lockVault(threat.vaultID))
                actions.append(.reviewAccessLogs)
            case .unusualLocation:
                actions.append(.reviewAccessLogs)
            case .suspiciousDeletion:
                actions.append(.reviewAccessLogs)
                actions.append(.reviewDocumentSharing)
            }
        case .dataExfiltration, .dataLeak:
            actions.append(.lockVault(threat.vaultID))
            actions.append(.reviewDocumentSharing)
        default:
            actions.append(.reviewAccessLogs)
        }
        
        return actions
    }
    
    private func iconForAction(_ action: RemediationAction) -> String {
        switch action {
        case .lockVault: return "lock.fill"
        case .closeAllVaults: return "lock.shield.fill"
        case .revokeAllSessions: return "xmark.circle.fill"
        case .reviewAccessLogs: return "clock.fill"
        case .reviewDocumentSharing: return "person.2.fill"
        case .enableDualKeyProtection: return "key.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    private func titleForAction(_ action: RemediationAction) -> String {
        switch action {
        case .lockVault: return "Lock Vault"
        case .closeAllVaults: return "Close All Vaults"
        case .revokeAllSessions: return "Revoke All Sessions"
        case .reviewAccessLogs: return "Review Access Logs"
        case .reviewDocumentSharing: return "Review Document Sharing"
        case .enableDualKeyProtection: return "Enable Dual-Key Protection"
        default: return "Action"
        }
    }
}

struct RemediationStepsCard: View {
    let threat: ThreatItem
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var aiService = ThreatRemediationAIService()
    @State private var steps: [String] = []
    @State private var isLoading = true
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(colors.warning)
                    
                    Text("Remediation Steps")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                Divider()
                
                if isLoading && steps.isEmpty {
                    // Show placeholder while loading
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        HStack {
                            Circle()
                                .fill(colors.surface)
                                .frame(width: 24, height: 24)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colors.surface)
                                .frame(height: 16)
                        }
                        HStack {
                            Circle()
                                .fill(colors.surface)
                                .frame(width: 24, height: 24)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colors.surface)
                                .frame(height: 16)
                        }
                        HStack {
                            Circle()
                                .fill(colors.surface)
                                .frame(width: 24, height: 24)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colors.surface)
                                .frame(height: 16)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: UnifiedTheme.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(colors.primary.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                
                                Text("\(index + 1)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.primary)
                                    .fontWeight(.bold)
                            }
                            
                            Text(step)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textPrimary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .task {
            // Generate AI-powered remediation steps asynchronously
            await loadRemediationSteps()
        }
    }
    
    private func loadRemediationSteps() async {
        // Show cached/quick steps immediately if available
        let quickSteps = getQuickRemediationSteps(for: threat)
        if !quickSteps.isEmpty {
            await MainActor.run {
                steps = quickSteps
                isLoading = false
            }
        }
        
        // Then load AI-powered steps asynchronously (optimized)
        Task {
            // Build threat context
            let context = ThreatContext(
                timeWindow: extractTimeWindow(from: threat.description),
                accessCount: extractAccessCount(from: threat.description),
                location: extractLocation(from: threat.description),
                distance: nil,
                deletedCount: threat.description.contains("deletion") ? 1 : nil,
                documentCount: nil,
                locationCount: nil,
                burstCount: nil
            )
            
            // Generate AI-powered steps (with timeout)
            let aiSteps = await withTimeout(seconds: 5) {
                await aiService.generateRemediationSteps(
                    for: threat,
                    vaultName: threat.vaultName,
                    threatDetails: context
                )
            } ?? quickSteps // Fallback to quick steps if timeout
            
            await MainActor.run {
                steps = aiSteps
                isLoading = false
            }
        }
    }
    
    /// Get quick remediation steps based on threat type (no AI needed)
    private func getQuickRemediationSteps(for threat: ThreatItem) -> [String] {
        switch threat.type {
        case .threat(let type):
            switch type {
            case .rapidAccess:
                return [
                    "Review recent access logs",
                    "Change vault password if unauthorized",
                    "Enable dual-key protection"
                ]
            case .unusualLocation:
                return [
                    "Verify if you accessed from this location",
                    "Review all recent access locations",
                    "Change password if unauthorized"
                ]
            case .suspiciousDeletion:
                return [
                    "Check version history for deleted documents",
                    "Restore important documents if needed",
                    "Review deletion logs"
                ]
            case .bruteForce:
                return [
                    "Immediately change vault password",
                    "Enable dual-key protection",
                    "Review all access attempts"
                ]
            case .unauthorizedAccess:
                return [
                    "Lock the vault immediately",
                    "Change all vault passwords",
                    "Review all access logs"
                ]
            }
        case .geographicAnomaly:
            return [
                "Review access locations",
                "Verify all locations are authorized",
                "Enable location-based alerts"
            ]
        case .accessBurst:
            return [
                "Review burst access patterns",
                "Verify if burst was from automated script",
                "Change password if unauthorized"
            ]
        case .dataExfiltration:
            return [
                "Immediately lock affected vaults",
                "Review all document access",
                "Change all passwords"
            ]
        case .dataLeak:
            return [
                "Review document sharing settings",
                "Revoke unauthorized access",
                "Lock affected vaults"
            ]
        }
    }
    
    /// Helper to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
    
    private func extractTimeWindow(from description: String) -> String? {
        // Extract time information from description
        if let range = description.range(of: #"\d+\s*(second|minute|hour)"#, options: .regularExpression) {
            return String(description[range])
        }
        return nil
    }
    
    private func extractAccessCount(from description: String) -> Int? {
        // Extract access count from description
        if let range = description.range(of: #"\d+\s*access"#, options: .regularExpression) {
            let match = String(description[range])
            if let number = Int(match.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                return number
            }
        }
        return nil
    }
    
    private func extractLocation(from description: String) -> String? {
        // Extract location if mentioned
        if description.contains("location") {
            return "Multiple locations detected"
        }
        return nil
    }
    
    // Legacy method kept for fallback (not used)
    private func getRemediationSteps(for threat: ThreatItem) -> [String] {
        switch threat.type {
        case .threat(let type):
            switch type {
            case .rapidAccess:
                return [
                    "Change vault password immediately",
                    "Review recent access logs for unauthorized activity",
                    "Enable dual-key protection for this vault",
                    "Contact support if you didn't make these accesses"
                ]
            case .unusualLocation:
                return [
                    "Verify if you accessed the vault from this location",
                    "If unauthorized, change vault password immediately",
                    "Review all recent access locations",
                    "Enable location-based alerts"
                ]
            case .suspiciousDeletion:
                return [
                    "Check version history for deleted documents",
                    "Restore any important deleted documents",
                    "Review deletion logs",
                    "Change vault password if deletions were unauthorized"
                ]
            case .bruteForce:
                return [
                    "Immediately change vault password",
                    "Enable dual-key protection",
                    "Review all access attempts",
                    "Report to support if attack continues"
                ]
            case .unauthorizedAccess:
                return [
                    "Lock the vault immediately",
                    "Change all vault passwords",
                    "Review all access logs",
                    "Enable enhanced security monitoring",
                    "Report incident to support"
                ]
            }
        case .geographicAnomaly:
            return [
                "Review access locations in vault settings",
                "Verify all locations are authorized",
                "Enable location-based alerts",
                "Consider enabling dual-key protection"
            ]
        case .accessBurst:
            return [
                "Review burst access patterns",
                "Verify if burst was from automated script",
                "Change vault password if unauthorized",
                "Enable rate limiting alerts"
            ]
        case .dataExfiltration:
            return [
                "Immediately lock affected vaults",
                "Review all recent document uploads",
                "Check for unauthorized document sharing",
                "Change all vault passwords",
                "Enable enhanced monitoring",
                "Report potential breach to support"
            ]
        case .dataLeak(let leakType):
            switch leakType {
            case .massUpload:
                return [
                    "Review uploaded documents",
                    "Verify all uploads were authorized",
                    "Archive or delete sensitive documents if needed",
                    "Change vault password if unauthorized"
                ]
            case .accountSharing:
                return [
                    "Review all access locations",
                    "Revoke access for unknown devices",
                    "Change vault password",
                    "Enable dual-key protection"
                ]
            case .suspiciousContent:
                return [
                    "Review documents with suspicious tags",
                    "Archive or delete sensitive documents",
                    "Enable content monitoring",
                    "Change vault password if needed"
                ]
            case .massDeletion:
                return [
                    "Immediately lock the vault",
                    "Restore deleted documents from version history",
                    "Review deletion logs",
                    "Change vault password",
                    "Report incident if data was destroyed"
                ]
            case .unauthorizedAccess:
                return [
                    "Lock vault immediately",
                    "Change all passwords",
                    "Review access logs",
                    "Report to support"
                ]
            }
        }
    }
}

// MARK: - Automatic Triage Results Section

struct AutomaticTriageResultsSection: View {
    let results: [TriageResult]
    let onStartRemediation: (TriageResult) -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(colors.primary)
                
                Text("Automatic Triage Results")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                Text("\(results.count)")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.primary)
            }
            .padding(.horizontal)
            
            ForEach(results) { result in
                AutomaticTriageResultRow(
                    result: result,
                    onStartRemediation: { onStartRemediation(result) }
                )
            }
        }
    }
}

struct AutomaticTriageResultRow: View {
    let result: TriageResult
    let onStartRemediation: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                HStack {
                    Image(systemName: iconForType(result.type))
                        .foregroundColor(result.severity.color)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(result.title)
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text(result.severity.rawValue)
                                .font(theme.typography.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(result.severity.color)
                                .cornerRadius(4)
                        }
                        
                        Text(result.description)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                            .lineLimit(2)
                        
                        if let entities = result.affectedEntities, !entities.isEmpty {
                            Text("Affected: \(entities.joined(separator: ", "))")
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.error)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Label(result.vaultName, systemImage: "lock.shield.fill")
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textTertiary)
                    
                    Spacer()
                    
                    Button {
                        onStartRemediation()
                    } label: {
                        Label("Start Remediation", systemImage: "arrow.right.circle.fill")
                            .font(theme.typography.caption)
                    }
                    .foregroundColor(colors.primary)
                }
            }
        }
    }
    
    private func iconForType(_ type: TriageResultType) -> String {
        switch type {
        case .screenMonitoring: return "eye.slash.fill"
        case .compromisedNominee: return "person.crop.circle.badge.xmark"
        case .sensitiveDocuments: return "doc.text.fill"
        case .dataLeak: return "arrow.up.doc.fill"
        case .bruteForce: return "bolt.shield.fill"
        case .unauthorizedAccess: return "lock.triangle.fill"
        case .suspiciousActivity: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Secondary Button Style
// Note: SecondaryButtonStyle is defined in ThemeModifiers.swift
