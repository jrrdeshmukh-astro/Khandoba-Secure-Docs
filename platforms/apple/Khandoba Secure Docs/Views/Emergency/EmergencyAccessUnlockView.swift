//
//  EmergencyAccessUnlockView.swift
//  Khandoba Secure Docs
//
//  Emergency access unlock using identification pass code
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct EmergencyAccessUnlockView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var emergencyService = EmergencyApprovalService()
    @State private var passCode: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var accessPass: EmergencyAccessPass?
    
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
                            Image(systemName: "key.horizontal.fill")
                                .font(.system(size: 60))
                                .foregroundColor(colors.warning)
                            
                            Text("Emergency Access")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Enter your emergency access pass code")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // Vault Info
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                Text("Vault")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                
                                Text(vault.name)
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Pass Code Input
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Pass Code")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                                .padding(.horizontal)
                            
                            TextField("Enter pass code", text: $passCode)
                                .font(theme.typography.body.monospaced())
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                .padding(.horizontal)
                        }
                        
                        // Info Card
                        StandardCard {
                            HStack(spacing: UnifiedTheme.Spacing.sm) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(colors.info)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Security Note")
                                        .font(theme.typography.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text("Biometric verification is required even with a valid pass code.")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Unlock Button
                        Button {
                            Task {
                                await unlockWithPassCode()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "lock.open.fill")
                                    Text("Unlock Vault")
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(passCode.isEmpty || isLoading)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Emergency Unlock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Access Granted", isPresented: $showSuccess) {
                Button("Open Vault") {
                    // Open vault and dismiss
                    Task {
                        do {
                            try await vaultService.unlockVault(vaultId: vault.id, password: nil)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                if let pass = accessPass {
                    let timeRemaining = Int(pass.timeRemaining / 60)
                    Text("Emergency access granted. Pass code expires in \(timeRemaining) minutes.")
                } else {
                    Text("Emergency access granted.")
                }
            }
        }
        .task {
            emergencyService.configure(supabaseService: supabaseService)
            if !AppConfig.useSupabase {
                emergencyService.configure(modelContext: modelContext)
            }
        }
    }
    
    private func unlockWithPassCode() async {
        await MainActor.run {
            isLoading = true
            showError = false
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Step 1: Verify pass code
            guard let pass = try await emergencyService.verifyEmergencyPass(
                passCode: passCode.trimmingCharacters(in: .whitespacesAndNewlines),
                vaultID: vault.id
            ) else {
                await MainActor.run {
                    errorMessage = "Invalid or expired pass code. Please check and try again."
                    showError = true
                }
                return
            }
            
            // Step 2: Biometric verification
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                // Fallback to device passcode
                guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                    await MainActor.run {
                        errorMessage = "Biometric authentication not available"
                        showError = true
                    }
                    return
                }
            }
            
            let reason = "Verify your identity to access the vault with emergency pass code"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            guard success else {
                await MainActor.run {
                    errorMessage = "Biometric verification failed"
                    showError = true
                }
                return
            }
            
            // Step 3: Mark pass as used (optional - can allow multiple uses until expiry)
            // try await emergencyService.useEmergencyPass(pass)
            
            // Step 4: Grant access
            await MainActor.run {
                accessPass = pass
                showSuccess = true
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
