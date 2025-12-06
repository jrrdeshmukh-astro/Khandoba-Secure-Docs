//
//  TriageView.swift
//  Khandoba Secure Docs
//
//  Real-time threat triage and remediation center
//

import SwiftUI
import SwiftData
import Charts

struct TriageView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var threatService = ThreatMonitoringService()
    @StateObject private var mlService = MLThreatAnalysisService()
    @StateObject private var vaultService = VaultService()
    
    @State private var allThreats: [ThreatItem] = []
    @State private var dataLeaks: [DataLeak] = []
    @State private var isAnalyzing = false
    @State private var selectedThreat: ThreatItem?
    @State private var showRemediation = false
    @State private var refreshTimer: Timer?
    
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
                        
                        // Empty State
                        if allThreats.isEmpty && dataLeaks.isEmpty {
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
                }
            }
            .task {
                await analyzeAllThreats()
                startRealTimeMonitoring()
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
        
        // Analyze each vault
        for vault in vaults {
            // Traditional threat detection
            let threatLevel = await threatService.analyzeThreatLevel(for: vault)
            let threats = threatService.detectThreats(for: vault)
            
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
            let geoMetrics = mlService.analyzeGeoClassification(for: vault)
            let accessMetrics = mlService.analyzeAccessPatterns(for: vault)
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
            }
        }
    }
    
    private func stopRealTimeMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Alert System
    
    private func sendRealTimeAlerts(threats: [ThreatItem], leaks: [DataLeak]) async {
        // Send push notifications for critical threats
        let criticalThreats = threats.filter { $0.severity == .critical }
        
        for threat in criticalThreats {
            PushNotificationService.shared.sendSecurityAlertNotification(
                title: "🚨 Critical Threat Detected",
                body: threat.title,
                threatType: threat.type.rawValue
            )
        }
        
        // Send alerts for data leaks
        for leak in leaks.filter({ $0.severity == .critical || $0.severity == .high }) {
            PushNotificationService.shared.sendSecurityAlertNotification(
                title: "⚠️ Data Leak Detected",
                body: leak.title,
                threatType: leak.type.rawValue
            )
        }
    }
    
    // MARK: - Resolution
    
    private func resolveThreat(_ threat: ThreatItem) {
        // Mark threat as resolved
        allThreats.removeAll { $0.id == threat.id }
        
        // Log resolution
        print("✅ Threat resolved: \(threat.title)")
    }
    
    private func resolveLeak(_ leak: DataLeak) {
        // Mark leak as resolved
        dataLeaks.removeAll { $0.id == leak.id }
        
        // Log resolution
        print("✅ Data leak resolved: \(leak.title)")
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
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    ForEach(generateRemediations(), id: \.id) { remediation in
                        RemediationRow(remediation: remediation)
                    }
                }
            }
        }
    }
    
    private func generateRemediations() -> [Remediation] {
        var remediations: [Remediation] = []
        
        // Check for rapid access
        if threats.contains(where: { 
            if case .threat(.rapidAccess) = $0.type { return true }
            return false
        }) {
            remediations.append(Remediation(
                id: UUID(),
                priority: .high,
                title: "Secure Account Access",
                description: "Rapid access patterns detected. Change your vault password and enable two-factor authentication.",
                steps: [
                    "Change vault password immediately",
                    "Review recent access logs",
                    "Enable dual-key protection for sensitive vaults",
                    "Contact support if you didn't make these accesses"
                ]
            ))
        }
        
        // Check for geographic anomalies
        if threats.contains(where: {
            if case .geographicAnomaly = $0.type { return true }
            return false
        }) {
            remediations.append(Remediation(
                id: UUID(),
                priority: .high,
                title: "Review Account Sharing",
                description: "Vault accessed from multiple locations. Verify all access is authorized.",
                steps: [
                    "Review all access locations",
                    "Revoke access for unknown devices",
                    "Enable location-based alerts",
                    "Consider enabling dual-key protection"
                ]
            ))
        }
        
        // Check for data leaks
        if !leaks.isEmpty {
            remediations.append(Remediation(
                id: UUID(),
                priority: .critical,
                title: "Address Data Leaks",
                description: "Potential data leaks detected. Take immediate action to secure your data.",
                steps: [
                    "Review affected vaults and documents",
                    "Archive or delete sensitive documents if compromised",
                    "Change all vault passwords",
                    "Enable enhanced security monitoring",
                    "Report incident if data breach confirmed"
                ]
            ))
        }
        
        // Check for mass deletions
        if leaks.contains(where: { $0.type == .massDeletion }) {
            remediations.append(Remediation(
                id: UUID(),
                priority: .critical,
                title: "Stop Mass Deletions",
                description: "High deletion rate detected. This may indicate unauthorized access or data destruction.",
                steps: [
                    "Immediately lock affected vaults",
                    "Review deletion logs",
                    "Restore deleted documents from version history if available",
                    "Change vault passwords",
                    "Enable dual-key protection"
                ]
            ))
        }
        
        // Default: General security
        if remediations.isEmpty {
            remediations.append(Remediation(
                id: UUID(),
                priority: .medium,
                title: "Maintain Security Best Practices",
                description: "Continue monitoring and follow security best practices.",
                steps: [
                    "Regularly review access logs",
                    "Use strong, unique passwords",
                    "Enable dual-key protection for sensitive vaults",
                    "Keep app updated"
                ]
            ))
        }
        
        return remediations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}

struct Remediation: Identifiable {
    let id: UUID
    let priority: RemediationPriority
    let title: String
    let description: String
    let steps: [String]
}

enum RemediationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
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
                
                Text(remediation.priority.rawValue == 4 ? "Critical" : remediation.priority.rawValue == 3 ? "High" : "Medium")
                    .font(theme.typography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(remediation.priority.rawValue == 4 ? colors.error : colors.warning)
                    .cornerRadius(4)
            }
            
            Text(remediation.description)
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
            
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
                    
                    // Remediation Steps
                    RemediationStepsCard(threat: threat)
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

struct RemediationStepsCard: View {
    let threat: ThreatItem
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let steps = getRemediationSteps(for: threat)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(colors.warning)
                    
                    Text("Remediation Steps")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                
                Divider()
                
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

// MARK: - Secondary Button Style
// Note: SecondaryButtonStyle is defined in ThemeModifiers.swift
