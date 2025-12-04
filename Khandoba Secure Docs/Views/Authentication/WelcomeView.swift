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
                    FeatureRow(icon: "lock.shield.fill", text: "End-to-end encryption", colors: colors)
                    FeatureRow(icon: "icloud.fill", text: "Secure cloud backup", colors: colors)
                    FeatureRow(icon: "checkmark.seal.fill", text: "Privacy first", colors: colors)
                }
                .padding(.horizontal, UnifiedTheme.Spacing.xl)
                
                Spacer()
                
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    // Sign in with Apple Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
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
            Task {
                do {
                    try await authService.signIn(with: authorization)
                    isLoading = false
                } catch {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
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

