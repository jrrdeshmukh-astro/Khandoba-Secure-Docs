//
//  TermsOfServiceView.swift
//  Khandoba Secure Docs
//
//  In-app terms of service

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                    Text("Terms of Service")
                        .font(theme.typography.title)
                        .foregroundColor(colors.textPrimary)
                        .padding(.bottom)
                    
                    TermsSection(
                        title: "Subscription",
                        content: "Khandoba Secure Docs is a subscription service at $5.99/month. Payment is processed through the App Store. Subscription auto-renews unless cancelled 24 hours before the end of the period. Manage or cancel in iOS Settings → Subscriptions."
                    )
                    
                    TermsSection(
                        title: "Service Description",
                        content: "Premium subscription provides unlimited vaults, unlimited document storage, AI-powered features, threat monitoring, and secure collaboration tools."
                    )
                    
                    TermsSection(
                        title: "User Responsibilities",
                        content: "You are responsible for maintaining the confidentiality of your Apple Sign In credentials. You agree not to use the service for illegal purposes or to store prohibited content."
                    )
                    
                    TermsSection(
                        title: "Data Security",
                        content: "We employ military-grade AES-256 encryption and zero-knowledge architecture. While we implement strong security measures, you are responsible for backing up critical documents."
                    )
                    
                    TermsSection(
                        title: "Cancellation & Refunds",
                        content: "Cancel anytime in App Store subscriptions. Refund requests are handled by Apple according to their refund policy. No prorated refunds for partial months."
                    )
                    
                    TermsSection(
                        title: "Service Modifications",
                        content: "We may modify or discontinue features with notice. Price changes require your consent. Major changes will be communicated via email or in-app notification."
                    )
                    
                    TermsSection(
                        title: "Limitation of Liability",
                        content: "Service provided 'as is'. We are not liable for data loss (backup your critical documents). Maximum liability limited to subscription fees paid."
                    )
                    
                    TermsSection(
                        title: "Contact",
                        content: "For terms questions: legal@khandoba.com\nFull terms: https://khandoba.com/terms"
                    )
                }
                .padding()
            }
            .background(colors.background)
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

struct TermsSection: View {
    let title: String
    let content: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
            Text(title)
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
            
            Text(content)
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, UnifiedTheme.Spacing.md)
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
}
