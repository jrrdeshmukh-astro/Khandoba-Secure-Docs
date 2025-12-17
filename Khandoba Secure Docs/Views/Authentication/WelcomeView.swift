//
//  WelcomeView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: UnifiedTheme.Spacing.xl) {
                Spacer()
                
                // App Icon/Logo
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(colors.primary)
                
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    Text("Khandoba")
                        .font(theme.typography.largeTitle)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.bold)
                    
                    Text("Secure Document Management")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                }
                
                // Feature highlights
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    WelcomeFeatureRow(icon: "lock.shield.fill", text: "End-to-end encryption", colors: colors)
                    WelcomeFeatureRow(icon: "icloud.fill", text: "Secure cloud backup", colors: colors)
                    WelcomeFeatureRow(icon: "checkmark.seal.fill", text: "Privacy first", colors: colors)
                }
                .padding(.horizontal, UnifiedTheme.Spacing.xl)
                
                Spacer()
                
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    // Sign in with Apple Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                            // Generate nonce and set it in the request
                            // The nonce must be hashed with SHA-256 for Apple
                            let hashedNonce = authService.generateNonce()
                            request.nonce = hashedNonce
                            print("🔐 Apple Sign In request configured with nonce")
                        },
                        onCompletion: { result in
                            handleSignIn(result)
                        }
                    )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                    
                    Text("New or returning user? One button does it all.")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, UnifiedTheme.Spacing.xl)
                
                Spacer()
            }
            .padding(UnifiedTheme.Spacing.xl)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                LoadingView("Signing in...")
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isLoading = true
            print("🔄 Starting sign-in process...")
            Task {
                do {
                    try await authService.signIn(with: authorization)
                    print("✅ Sign-in completed successfully")
                    print("   isAuthenticated: \(authService.isAuthenticated)")
                    print("   currentUser: \(authService.currentUser?.fullName ?? "nil")")
                    await MainActor.run {
                        isLoading = false
                    }
                } catch {
                    print("❌ Sign-in failed: \(error.localizedDescription)")
                    await MainActor.run {
                        isLoading = false
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
            
        case .failure(let error):
            // Provide more helpful error messages
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .unknown:
                    errorMessage = "Apple Sign In failed. Please ensure:\n• Your device is signed into iCloud\n• Two-factor authentication is enabled\n• Try testing on a real device (simulators have limitations)"
                case .canceled:
                    errorMessage = "Sign in was canceled."
                case .invalidResponse:
                    errorMessage = "Invalid response from Apple. Please try again."
                case .notHandled:
                    errorMessage = "Sign in request could not be handled."
                case .failed:
                    errorMessage = "Sign in failed. Please check your iCloud sign-in status."
                @unknown default:
                    errorMessage = "Apple Sign In error: \(authError.localizedDescription)\n\nTip: Ensure your device is signed into iCloud."
                }
            } else {
                errorMessage = error.localizedDescription
            }
            showError = true
        }
    }
}

// MARK: - Welcome Feature Row Component
private struct WelcomeFeatureRow: View {
    let icon: String
    let text: String
    let colors: UnifiedTheme.Colors
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(colors.primary)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
            
            Spacer()
        }
    }
}

