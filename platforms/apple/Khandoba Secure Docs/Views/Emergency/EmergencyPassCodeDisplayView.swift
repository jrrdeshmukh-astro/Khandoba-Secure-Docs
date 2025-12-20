//
//  EmergencyPassCodeDisplayView.swift
//  Khandoba Secure Docs
//
//  Display emergency access pass code after approval
//

import SwiftUI

struct EmergencyPassCodeDisplayView: View {
    let passCode: String
    let expiresAt: Date
    let vaultName: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var copied = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let timeRemaining = Int(expiresAt.timeIntervalSinceNow / 60)
        
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
                                .foregroundColor(colors.success)
                            
                            Text("Emergency Access Approved")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Share this pass code with the requester")
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
                                
                                Text(vaultName)
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Pass Code Display
                        StandardCard {
                            VStack(spacing: UnifiedTheme.Spacing.md) {
                                Text("Pass Code")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textSecondary)
                                
                                Text(passCode)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(colors.textPrimary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(colors.surface)
                                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                                
                                Button {
                                    #if os(iOS)
                                    UIPasteboard.general.string = passCode
                                    #endif
                                    withAnimation {
                                        copied = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            copied = false
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                        Text(copied ? "Copied!" : "Copy Pass Code")
                                    }
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(colors.primary.opacity(0.1))
                                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Expiration Info
                        StandardCard {
                            HStack(spacing: UnifiedTheme.Spacing.sm) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(colors.warning)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Expires In")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                    
                                    Text("\(timeRemaining) minutes")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Instructions
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                Text("Instructions")
                                    .font(theme.typography.subheadline)
                                    .fontWeight(.semibold)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    InstructionRow(number: "1", text: "Share this pass code with the requester securely")
                                    InstructionRow(number: "2", text: "Requester will need the pass code AND biometric verification")
                                    InstructionRow(number: "3", text: "Access will expire in 24 hours")
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Close Button
                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(theme.typography.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.primary)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Pass Code Generated")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(alignment: .top, spacing: UnifiedTheme.Spacing.sm) {
            Text(number)
                .font(theme.typography.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(colors.primary)
                .clipShape(Circle())
            
            Text(text)
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
            
            Spacer()
        }
    }
}
