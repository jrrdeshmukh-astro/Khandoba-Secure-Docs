//
//  PanicButtonView.swift
//  Khandoba Secure Docs
//
//  Panic Button view for emergency security actions
//

import SwiftUI
import LocalAuthentication

struct PanicButtonView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var panicService: PanicButtonService
    
    @State private var showingActivationConfirmation = false
    @State private var showingDeactivationConfirmation = false
    @State private var activationReason: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                // Panic Button
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    if panicService.isPanicModeActive {
                        // Deactivate Button
                        Button {
                            showingDeactivationConfirmation = true
                        } label: {
                            VStack(spacing: UnifiedTheme.Spacing.sm) {
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("Panic Mode Active")
                                    .font(theme.typography.title2)
                                    .foregroundColor(.white)
                                
                                Text("Tap to deactivate")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(UnifiedTheme.Spacing.xl)
                            .background(colors.error)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                    } else {
                        // Activate Button
                        Button {
                            showingActivationConfirmation = true
                        } label: {
                            VStack(spacing: UnifiedTheme.Spacing.sm) {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text("Activate Panic Mode")
                                    .font(theme.typography.title2)
                                    .foregroundColor(.white)
                                
                                Text("Emergency security lockdown")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(UnifiedTheme.Spacing.xl)
                            .background(
                                LinearGradient(
                                    colors: [colors.error, colors.error.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            .shadow(color: colors.error.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                
                // What Happens Section
                Section {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("What happens when you activate Panic Mode:")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.primary)
                        
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            PanicActionRow(
                                icon: "lock.fill",
                                title: "Close All Vault Sessions",
                                description: "All open vaults will be immediately locked"
                            )
                            
                            PanicActionRow(
                                icon: "iphone.slash",
                                title: "Revoke All Devices",
                                description: "All authorized devices (except this one) will be revoked"
                            )
                            
                            PanicActionRow(
                                icon: "lock.shield.fill",
                                title: "Lock All Vaults",
                                description: "All vaults will be locked and require re-authentication"
                            )
                            
                            PanicActionRow(
                                icon: "trash.fill",
                                title: "Clear Sensitive Cache",
                                description: "All cached sensitive data will be cleared"
                            )
                            
                            PanicActionRow(
                                icon: "bell.fill",
                                title: "Send Security Alerts",
                                description: "Security alerts will be sent to all devices"
                            )
                        }
                    }
                    .padding(UnifiedTheme.Spacing.md)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                } header: {
                    Text("Emergency Actions")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.primary)
                }
                
                // Last Activation
                if let lastActivation = panicService.lastPanicActivation {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Last Activated")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.secondary)
                        
                        Text(formatDate(lastActivation))
                            .font(theme.typography.headline)
                            .foregroundColor(colors.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(UnifiedTheme.Spacing.md)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                }
                
                // Action History
                if !panicService.panicActionsExecuted.isEmpty {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("Last Activation Actions")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.primary)
                        
                        ForEach(panicService.panicActionsExecuted) { action in
                            HStack {
                                Image(systemName: action.status == .completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(action.status == .completed ? colors.success : colors.error)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(action.type.rawValue)
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.primary)
                                    
                                    Text(action.message)
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(UnifiedTheme.Spacing.sm)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.sm)
                        }
                    }
                    .padding(UnifiedTheme.Spacing.md)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                }
            }
            .padding(UnifiedTheme.Spacing.lg)
        }
        .navigationTitle("Panic Button")
        .navigationBarTitleDisplayMode(.large)
        .alert("Activate Panic Mode", isPresented: $showingActivationConfirmation) {
            TextField("Reason (Optional)", text: $activationReason)
            Button("Cancel", role: .cancel) {
                activationReason = ""
            }
            Button("Activate", role: .destructive) {
                Task {
                    await activatePanicMode()
                }
            }
        } message: {
            Text("This will immediately lock all vaults, close all sessions, and revoke all devices (except this one). This action requires biometric authentication.")
        }
        .alert("Deactivate Panic Mode", isPresented: $showingDeactivationConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Deactivate") {
                Task {
                    await deactivatePanicMode()
                }
            }
        } message: {
            Text("Are you sure you want to deactivate panic mode? This will restore normal access.")
        }
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
    
    private func activatePanicMode() async {
        do {
            try await panicService.activatePanicMode(reason: activationReason.isEmpty ? nil : activationReason)
            activationReason = ""
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func deactivatePanicMode() async {
        do {
            try await panicService.deactivatePanicMode()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PanicActionRow: View {
    let icon: String
    let title: String
    let description: String
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(colors.error)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.primary)
                
                Text(description)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.secondary)
            }
        }
    }
}

