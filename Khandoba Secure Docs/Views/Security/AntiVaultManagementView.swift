//
//  AntiVaultManagementView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import SwiftUI
import SwiftData
import Foundation

struct AntiVaultManagementView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var antiVaultService = AntiVaultService()
    @StateObject private var intelReportService = IntelReportService()
    
    @State private var antiVaults: [AntiVault] = []
    @State private var isLoading = false
    @State private var showCreateAntiVault = false
    @State private var selectedVault: Vault?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if antiVaults.isEmpty {
                    EmptyStateView(
                        icon: "shield.lefthalf.filled",
                        title: "No Anti-Vaults",
                        message: "Create an anti-vault to monitor a vault for fraud detection"
                    )
                } else {
                    List {
                        ForEach(antiVaults) { antiVault in
                            NavigationLink {
                                AntiVaultDetailView(antiVault: antiVault)
                            } label: {
                                AntiVaultRow(antiVault: antiVault, colors: colors, theme: theme)
                                    .environmentObject(vaultService)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(colors.background)
                }
            }
            .navigationTitle("Anti-Vaults")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateAntiVault = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateAntiVault) {
                CreateAntiVaultView(
                    onCreated: { vault in
                        selectedVault = vault
                        Task {
                            await loadAntiVaults()
                        }
                    }
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .task {
                await configureServices()
                await loadAntiVaults()
            }
        }
    }
    
    private func configureServices() async {
        guard let userID = authService.currentUser?.id else { return }
        
        if AppConfig.useSupabase {
            antiVaultService.configure(
                supabaseService: supabaseService,
                userID: userID,
                intelReportService: intelReportService,
                vaultService: vaultService
            )
            intelReportService.configure(supabaseService: supabaseService)
        } else {
            antiVaultService.configure(
                modelContext: modelContext,
                userID: userID,
                intelReportService: intelReportService,
                vaultService: vaultService
            )
            intelReportService.configure(modelContext: modelContext)
        }
    }
    
    private func loadAntiVaults() async {
        isLoading = true
        defer { isLoading = false }
        
        // In a real implementation, this would load from database
        // For now, we'll use the service's published property
        await MainActor.run {
            antiVaults = antiVaultService.antiVaults
        }
    }
}

struct AntiVaultRow: View {
    let antiVault: AntiVault
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    @EnvironmentObject var vaultService: VaultService
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(colors.primary.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(colors.primary)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vaultName(for: antiVault.vaultID) ?? "Anti-Vault")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Text("Monitoring: \(vaultName(for: antiVault.monitoredVaultID) ?? "Unknown")")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                
                HStack(spacing: 8) {
                    StatusBadge(status: antiVault.status, colors: colors, theme: theme)
                    
                    if antiVault.lastUnlockedAt != nil {
                        Text("Last unlocked: \(antiVault.lastUnlockedAt!.formatted(date: .abbreviated, time: .shortened))")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            if antiVault.status == "active" {
                Image(systemName: "lock.open.fill")
                    .foregroundColor(colors.success)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func vaultName(for vaultID: UUID?) -> String? {
        guard let vaultID = vaultID else { return nil }
        return vaultService.vaults.first(where: { $0.id == vaultID })?.name
    }
}

struct StatusBadge: View {
    let status: String
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        Text(status.uppercased())
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor(status))
            .cornerRadius(4)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "active": return .green
        case "locked": return .gray
        case "archived": return .orange
        default: return .gray
        }
    }
}

struct CreateAntiVaultView: View {
    let onCreated: (Vault) -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var antiVaultService = AntiVaultService()
    @StateObject private var intelReportService = IntelReportService()
    
    @State private var selectedVault: Vault?
    @State private var threatSettings = ThreatDetectionSettings()
    @State private var autoUnlockPolicy = AutoUnlockPolicy()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            Form {
                Section("Select Vault to Monitor") {
                    Picker("Vault", selection: $selectedVault) {
                        Text("Select a vault").tag(nil as Vault?)
                        ForEach(vaultService.vaults.filter { !$0.isAntiVault && !$0.isSystemVault }) { vault in
                            Text(vault.name).tag(vault as Vault?)
                        }
                    }
                }
                
                Section("Auto-Unlock Policy") {
                    Toggle("Unlock on Session Nomination", isOn: $autoUnlockPolicy.unlockOnSessionNomination)
                    Toggle("Unlock on Subset Nomination", isOn: $autoUnlockPolicy.unlockOnSubsetNomination)
                    Toggle("Require Approval", isOn: $autoUnlockPolicy.requireApproval)
                }
                
                Section("Threat Detection Settings") {
                    Toggle("Detect Content Discrepancies", isOn: $threatSettings.detectContentDiscrepancies)
                    Toggle("Detect Metadata Mismatches", isOn: $threatSettings.detectMetadataMismatches)
                    Toggle("Detect Access Pattern Anomalies", isOn: $threatSettings.detectAccessPatternAnomalies)
                    Toggle("Detect Geographic Inconsistencies", isOn: $threatSettings.detectGeographicInconsistencies)
                    Toggle("Detect Edit History Discrepancies", isOn: $threatSettings.detectEditHistoryDiscrepancies)
                    
                    Picker("Minimum Threat Severity", selection: $threatSettings.minThreatSeverity) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                        Text("Critical").tag("critical")
                    }
                }
            }
            .navigationTitle("Create Anti-Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task {
                            await createAntiVault()
                        }
                    }
                    .disabled(selectedVault == nil || isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .task {
                await configureServices()
            }
        }
    }
    
    private func configureServices() async {
        guard let userID = authService.currentUser?.id else { return }
        
        if AppConfig.useSupabase {
            antiVaultService.configure(
                supabaseService: supabaseService,
                userID: userID,
                intelReportService: intelReportService,
                vaultService: vaultService
            )
            intelReportService.configure(supabaseService: supabaseService)
        } else {
            antiVaultService.configure(
                modelContext: modelContext,
                userID: userID,
                intelReportService: intelReportService,
                vaultService: vaultService
            )
            intelReportService.configure(modelContext: modelContext)
        }
    }
    
    private func createAntiVault() async {
        guard let vault = selectedVault,
              let userID = authService.currentUser?.id else {
            errorMessage = "Please select a vault to monitor"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let antiVault = try await antiVaultService.createAntiVault(
                monitoredVault: vault,
                ownerID: userID,
                settings: threatSettings
            )
            
            // Update auto-unlock policy
            antiVault.autoUnlockPolicy = autoUnlockPolicy
            
            // Save policy updates
            if AppConfig.useSupabase {
                // Convert and update in Supabase
                guard let vaultID = antiVault.vaultID,
                      let monitoredVaultID = antiVault.monitoredVaultID,
                      let ownerID = authService.currentUser?.id else {
                    errorMessage = "Invalid anti-vault data"
                    showError = true
                    return
                }
                
                let supabaseAntiVault = SupabaseAntiVault(
                    id: antiVault.id,
                    vaultID: vaultID,
                    monitoredVaultID: monitoredVaultID,
                    ownerID: ownerID,
                    status: antiVault.status,
                    autoUnlockPolicy: antiVault.autoUnlockPolicy,
                    threatDetectionSettings: antiVault.threatDetectionSettings,
                    lastIntelReportID: antiVault.lastIntelReportID,
                    createdAt: antiVault.createdAt,
                    updatedAt: Date(),
                    lastUnlockedAt: antiVault.lastUnlockedAt
                )
                _ = try await supabaseService.update("anti_vaults", id: antiVault.id, values: supabaseAntiVault)
            } else {
                try modelContext.save()
            }
            
            onCreated(vault)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct AntiVaultDetailView: View {
    let antiVault: AntiVault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var antiVaultService: AntiVaultService
    @EnvironmentObject var vaultService: VaultService
    
    @State private var detectedThreats: [ThreatDetection] = []
    @State private var isLoading = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                // Status Card
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        HStack {
                            Text("Status")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                            
                            StatusBadge(status: antiVault.status, colors: colors, theme: theme)
                        }
                        
                        if let unlockedAt = antiVault.lastUnlockedAt {
                            Text("Last unlocked: \(unlockedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                }
                
                // Monitored Vault
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Monitored Vault")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(vaultName(for: antiVault.monitoredVaultID) ?? "Unknown")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                // Detected Threats
                if !detectedThreats.isEmpty {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(colors.warning)
                                
                                Text("Detected Threats")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Spacer()
                                
                                NavigationLink {
                                    ThreatDetectionView(threats: detectedThreats)
                                } label: {
                                    Text("View All")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.primary)
                                }
                            }
                            
                            ForEach(detectedThreats.prefix(3), id: \.detectedAt) { threat in
                                AntiVaultThreatRow(threat: threat, colors: colors, theme: theme)
                            }
                            
                            if detectedThreats.count > 3 {
                                Text("+ \(detectedThreats.count - 3) more")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(colors.background)
        .navigationTitle(vaultName(for: antiVault.vaultID) ?? "Anti-Vault")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadThreats()
        }
    }
    
    private func vaultName(for vaultID: UUID?) -> String? {
        guard let vaultID = vaultID else { return nil }
        return vaultService.vaults.first(where: { $0.id == vaultID })?.name
    }
    
    private func loadThreats() async {
        isLoading = true
        defer { isLoading = false }
        
        await MainActor.run {
            detectedThreats = antiVaultService.detectedThreats.filter { threat in
                // Filter threats for this anti-vault's monitored vault
                // In a real implementation, this would be more sophisticated
                true
            }
        }
    }
}

private struct AntiVaultThreatRow: View {
    let threat: ThreatDetection
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: severityIcon(threat.severity))
                .foregroundColor(severityColor(threat.severity))
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(threat.type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                Text(threat.description)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(threat.severity.uppercased())
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(severityColor(threat.severity))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
    
    private func severityIcon(_ severity: String) -> String {
        switch severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "info.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
}
