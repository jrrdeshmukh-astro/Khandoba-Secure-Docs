//
//  SimpleVaultSelectionView.swift
//  Khandoba Secure Docs
//
//  Simplified vault selection for iMessage extension
//

import SwiftUI
import SwiftData

struct SimpleVaultSelectionView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    let onVaultSelected: (Vault) -> Void
    let onCancel: () -> Void
    
    @State private var vaults: [Vault] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    onCancel()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colors.primary)
                }
                
                Text("Select Vault")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
            }
            .padding()
            .background(colors.surface)
            
            Divider()
            
            // Content
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading vaults...")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(colors.warning)
                    Text(error)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vaults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 40))
                        .foregroundColor(colors.textSecondary)
                    Text("No vaults available")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    Text("Create a vault in the main app first")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(vaults) { vault in
                            Button(action: {
                                onVaultSelected(vault)
                            }) {
                                HStack {
                                    Image(systemName: vault.keyType == "dual" ? "key.fill" : "key")
                                        .font(.system(size: 20))
                                        .foregroundColor(colors.primary)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(vault.name)
                                            .font(theme.typography.headline)
                                            .foregroundColor(colors.textPrimary)
                                        
                                        // Show vault type indicator if needed
                                        if vault.keyType == "dual" {
                                            Text("Dual-Key")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(colors.textSecondary)
                                }
                                .padding()
                                .background(colors.surface)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .task {
            // #region agent log
            DebugLogger.shared.log(
                location: "SimpleVaultSelectionView.swift:127",
                message: "View appeared - Starting vault load task",
                data: ["step": "view_appeared"],
                hypothesisId: "G"
            )
            // #endregion
            await loadVaults()
        }
        .onAppear {
            // #region agent log
            DebugLogger.shared.log(
                location: "SimpleVaultSelectionView.swift:onAppear",
                message: "SimpleVaultSelectionView onAppear called",
                data: ["step": "onAppear"],
                hypothesisId: "G"
            )
            // #endregion
        }
    }
    
    private func loadVaults() async {
        // #region agent log
        let appGroupID = MessageAppConfig.appGroupIdentifier
        DebugLogger.shared.log(
            location: "SimpleVaultSelectionView.swift:132",
            message: "loadVaults entry - App Group check",
            data: [
                "appGroupIdentifier": appGroupID,
                "function": "loadVaults",
                "step": "entry"
            ],
            hypothesisId: "B"
        )
        // #endregion
        
        // CRITICAL: For nominee invitation, we show ALL vaults (even locked ones)
        // Face ID is only required to ACCESS vault contents, not to SELECT a vault
        isLoading = true
        errorMessage = nil
        
        do {
            // #region agent log
            let containerStartTime = Date().timeIntervalSince1970
            // #endregion
            
            let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
            let context = container.mainContext
            
            // #region agent log
            DebugLogger.shared.log(
                location: "SimpleVaultSelectionView.swift:182",
                message: "ModelContainer ready - About to query vaults",
                data: [
                    "appGroupIdentifier": appGroupID,
                    "step": "before_vault_query"
                ],
                hypothesisId: "H"
            )
            // #endregion
            
            // #region agent log
            let containerDuration = Date().timeIntervalSince1970 - containerStartTime
            DebugLogger.shared.log(
                location: "SimpleVaultSelectionView.swift:137",
                message: "ModelContainer initialized - Vault query check",
                data: [
                    "appGroupIdentifier": appGroupID,
                    "containerInitialized": true,
                    "duration": containerDuration,
                    "step": "container_created"
                ],
                hypothesisId: "C"
            )
            // #endregion
            
            // Fetch vaults (excluding system vaults)
            let descriptor = FetchDescriptor<Vault>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            // #region agent log
            let fetchStartTime = Date().timeIntervalSince1970
            // #endregion
            
            let allVaults = try context.fetch(descriptor)
            
            // #region agent log
            let fetchDuration = Date().timeIntervalSince1970 - fetchStartTime
            DebugLogger.shared.log(
                location: "SimpleVaultSelectionView.swift:145",
                message: "Vault fetch completed - Results check",
                data: [
                    "totalVaultsFetched": allVaults.count,
                    "fetchDuration": fetchDuration,
                    "vaultIds": allVaults.map { $0.id.uuidString },
                    "vaultNames": allVaults.map { $0.name },
                    "vaultStatuses": allVaults.map { $0.status },
                    "vaultOwners": allVaults.map { $0.owner?.fullName ?? "nil" },
                    "systemVaults": allVaults.filter { $0.isSystemVault }.count,
                    "lockedVaults": allVaults.filter { $0.status == "locked" }.count,
                    "activeVaults": allVaults.filter { $0.status == "active" }.count,
                    "step": "fetch_completed"
                ],
                hypothesisId: "D"
            )
            // #endregion
            
            let userVaults = allVaults.filter { !$0.isSystemVault }
            
            // #region agent log
            DebugLogger.shared.log(
                location: "SimpleVaultSelectionView.swift:146",
                message: "Vault filtering completed - Final results",
                data: [
                    "totalVaults": allVaults.count,
                    "userVaults": userVaults.count,
                    "systemVaults": allVaults.count - userVaults.count,
                    "filteredVaultIds": userVaults.map { $0.id.uuidString },
                    "filteredVaultNames": userVaults.map { $0.name },
                    "filteredVaultStatuses": userVaults.map { $0.status },
                    "lockedUserVaults": userVaults.filter { $0.status == "locked" }.count,
                    "activeUserVaults": userVaults.filter { $0.status == "active" }.count,
                    "step": "filter_completed"
                ],
                hypothesisId: "E"
            )
            // #endregion
            
            await MainActor.run {
                // #region agent log
                DebugLogger.shared.log(
                    location: "SimpleVaultSelectionView.swift:148",
                    message: "Vaults loaded successfully - Updating UI",
                    data: [
                        "vaultsCount": userVaults.count,
                        "vaultNames": userVaults.map { $0.name },
                        "step": "ui_update"
                    ],
                    hypothesisId: "E"
                )
                // #endregion
                
                self.vaults = userVaults
                self.isLoading = false
                print("✅ Loaded \(userVaults.count) vault(s)")
            }
            
        } catch {
            // #region agent log
            DebugLogger.shared.log(
                location: "SimpleVaultSelectionView.swift:154",
                message: "Vault loading error - Error details",
                data: [
                    "appGroupIdentifier": appGroupID,
                    "error": error.localizedDescription,
                    "errorType": String(describing: type(of: error)),
                    "errorDescription": (error as NSError).description,
                    "errorDomain": (error as NSError).domain,
                    "errorCode": (error as NSError).code,
                    "step": "error_occurred"
                ],
                hypothesisId: "F"
            )
            // #endregion
            
            await MainActor.run {
                self.errorMessage = "Failed to load vaults: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Failed to load vaults: \(error.localizedDescription)")
            }
        }
    }
}
