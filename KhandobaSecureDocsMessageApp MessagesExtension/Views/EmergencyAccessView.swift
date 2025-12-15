//
//  EmergencyAccessView.swift
//  Khandoba Secure Docs
//
//  Apple Cash-style emergency access flow
//

import SwiftUI
import SwiftData
@preconcurrency import Messages

struct EmergencyAccessView: View {
    let conversation: MSConversation
    let onCancel: () -> Void
    let onSend: (Vault, String, String) -> Void // vault, reason, urgency
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vaults: [Vault] = []
    @State private var selectedVault: Vault?
    @State private var isLoading = true
    @State private var showVaultSelector = false
    @State private var reason: String = ""
    @State private var urgency: UrgencyLevel = .medium
    @State private var showFaceID = false
    @State private var isAuthenticating = false
    
    enum UrgencyLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                        .frame(width: 32, height: 32)
                }
                
                Spacer()
                
                Text("Khandoba Secure Docs")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    showVaultSelector.toggle()
                }) {
                    Text("Change Vault")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(colors.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(colors.surface)
            
            Divider()
            
            // Main Content
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading vaults...")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Recipient Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Request from")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(colors.textSecondary)
                            
                            Text("Recipient")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Large Vault Display (Apple Cash style - exact match)
                        if let vault = selectedVault {
                            VStack(spacing: 16) {
                                Text(vault.name)
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundColor(colors.textPrimary)
                                    .tracking(-1)
                                
                                Text("Emergency Access")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundColor(urgency.color)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        // Vault Rolodex
                        if showVaultSelector {
                            VaultRolodexView(
                                vaults: vaults,
                                selectedVault: $selectedVault
                            ) { vault in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showVaultSelector = false
                                }
                            }
                            .padding(.vertical, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Vault Card
                        if let vault = selectedVault {
                            VaultCardView(
                                vault: vault,
                                isSelected: true
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showVaultSelector.toggle()
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                        
                        // Reason Input (Apple Cash style)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reason for Emergency Access")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(colors.textPrimary)
                            
                            TextField("Enter reason...", text: $reason, axis: .vertical)
                                .font(.system(size: 16, design: .rounded))
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(colors.surface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(colors.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // Urgency Selector (Apple Cash style)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Urgency Level")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(colors.textPrimary)
                            
                            HStack(spacing: 12) {
                                ForEach(UrgencyLevel.allCases, id: \.self) { level in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            urgency = level
                                        }
                                    }) {
                                        Text(level.rawValue)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(urgency == level ? .white : level.color)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(
                                                urgency == level ?
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [level.color, level.color.opacity(0.9)]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ) : nil
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(level.color, lineWidth: urgency == level ? 0 : 2)
                                            )
                                            .cornerRadius(10)
                                            .scaleEffect(urgency == level ? 1.0 : 0.98)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
                
                // Action Button (Apple Cash style - exact match)
                VStack(spacing: 0) {
                    Button(action: {
                        guard let vault = selectedVault, !reason.isEmpty else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showFaceID = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 22, weight: .semibold))
                            Text("Request Emergency Access")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    urgency.color,
                                    urgency.color.opacity(0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: urgency.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(selectedVault == nil || reason.isEmpty || isAuthenticating)
                    .opacity(selectedVault == nil || reason.isEmpty || isAuthenticating ? 0.6 : 1.0)
                    .scaleEffect(selectedVault == nil || reason.isEmpty || isAuthenticating ? 0.98 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedVault)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: reason.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(colors.surface)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .overlay {
            if showFaceID {
                FaceIDOverlayView(
                    biometricType: BiometricAuthService.shared.biometricType()
                ) {
                    showFaceID = false
                }
                .transition(.opacity)
                .onAppear {
                    authenticateAndSend()
                }
            }
        }
        .task {
            await loadVaults()
        }
    }
    
    private func authenticateAndSend() {
        guard let vault = selectedVault, !reason.isEmpty else {
            showFaceID = false
            return
        }
        
        Task {
            isAuthenticating = true
            defer { isAuthenticating = false }
            
            do {
                let success = try await BiometricAuthService.shared.authenticate(
                    reason: "Authenticate to request emergency access"
                )
                
                if success {
                    await MainActor.run {
                        onSend(vault, reason, urgency.rawValue)
                        showFaceID = false
                    }
                } else {
                    await MainActor.run {
                        showFaceID = false
                    }
                }
            } catch {
                await MainActor.run {
                    showFaceID = false
                }
            }
        }
    }
    
    private func loadVaults() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
            let context = container.mainContext
            
            let descriptor = FetchDescriptor<Vault>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let allVaults = try context.fetch(descriptor)
            let userVaults = allVaults.filter { !$0.isSystemVault }
            
            await MainActor.run {
                self.vaults = userVaults
                self.selectedVault = userVaults.first
            }
        } catch {
            print("❌ Failed to load vaults: \(error.localizedDescription)")
        }
    }
}
