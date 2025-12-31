//
//  PrivacyPolicyView.swift
//  Khandoba Secure Docs
//
//  In-app privacy policy

import SwiftUI

struct PrivacyPolicyView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                    Text("Privacy Policy")
                        .font(theme.typography.title)
                        .foregroundColor(colors.textPrimary)
                        .padding(.bottom)
                    
                    PolicySection(
                        title: "Data Collection",
                        content: "We collect only essential information: your name and email from Apple Sign In, and the documents you choose to store. All data is encrypted on your device before storage."
                    )
                    
                    PolicySection(
                        title: "Zero-Knowledge Architecture",
                        content: "Your documents are encrypted with keys that never leave your device. Even our administrators cannot access your document content. We can only see metadata like file names and sizes."
                    )
                    
                    PolicySection(
                        title: "Data Storage",
                        content: "All documents are stored encrypted using AES-256-GCM encryption. Data is synced via Apple's CloudKit service and follows Apple's privacy standards."
                    )
                    
                    PolicySection(
                        title: "Location Data",
                        content: "Location data is collected only when accessing vaults, solely for security logging. This helps you track where your vaults were accessed. Location data is never shared with third parties."
                    )
                    
                    PolicySection(
                        title: "Data Sharing",
                        content: "We never share your data with third parties. Your documents remain private and encrypted. Vault sharing features are controlled entirely by you."
                    )
                    
                    PolicySection(
                        title: "HIPAA Compliance",
                        content: "Our encryption and zero-knowledge architecture support HIPAA compliance for medical document storage. Redaction tools help protect protected health information (PHI)."
                    )
                    
                    PolicySection(
                        title: "Your Rights",
                        content: "You can export all your data at any time. You can delete your account and all associated data. You control all sharing and access permissions."
                    )
                    
                    PolicySection(
                        title: "Access Logs in Shared Vaults",
                        content: "If you delete your account and you were granted access to someone else's vault as a nominee, your access will be terminated immediately. However, access logs and location data from your previous vault access will remain with the vault owner. This includes access timestamps, access types, location data, device information, and document access records. This data retention is necessary for security compliance, audit trails, and to protect the vault owner's security interests."
                    )
                    
                    PolicySection(
                        title: "Contact",
                        content: "For privacy questions, contact us at privacy@khandoba.org"
                    )
                    
                    // Functional Privacy Policy Link (Required by App Store)
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        Link(destination: URL(string: "https://khandoba.org/privacy")!) {
                            HStack {
                                Text("View Full Privacy Policy")
                                    .foregroundColor(colors.primary)
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(colors.primary)
                            }
                        }
                        
                        Link(destination: URL(string: "https://khandoba.org/terms")!) {
                            HStack {
                                Text("View Terms of Service")
                                    .foregroundColor(colors.primary)
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(colors.primary)
                            }
                        }
                    }
                    .padding(.top, UnifiedTheme.Spacing.md)
                }
                .padding()
            }
            .background(colors.background)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
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
