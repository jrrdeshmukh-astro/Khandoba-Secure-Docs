//
//  AboutView.swift
//  Khandoba Secure Docs
//
//  About the app

import SwiftUI
import Combine

struct AboutView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.xl) {
                        // App Icon
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(colors.primary)
                            .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // App Name
                        Text("Khandoba Secure Docs")
                            .font(theme.typography.title)
                            .foregroundColor(colors.textPrimary)
                        
                        // Version
                        Text("Version 1.0 (Build \(AppConfig.appBuildNumber))")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        Divider()
                            .padding(.vertical)
                        
                        // Description
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("About Khandoba Secure Docs")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Your personal secure vault for documents. Military-grade AES-256 encryption with AI-powered intelligence, zero-knowledge architecture, and HIPAA compliance.")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal)
                        
                        // Features
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Key Features")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            FeatureItem(icon: "lock.fill", text: "Military-grade encryption")
                            FeatureItem(icon: "brain.fill", text: "AI-powered intelligence")
                            FeatureItem(icon: "shield.checkered", text: "Zero-knowledge architecture")
                            FeatureItem(icon: "heart.text.square.fill", text: "HIPAA compliant")
                        }
                        .padding(.horizontal)
                        
                        // Copyright
                        Text("© 2025 Khandoba. All rights reserved.")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textTertiary)
                            .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.colors(for: colorScheme).primary)
                .frame(width: 24)
            
            Text(text)
                .font(theme.typography.body)
                .foregroundColor(theme.colors(for: colorScheme).textSecondary)
        }
    }
}

