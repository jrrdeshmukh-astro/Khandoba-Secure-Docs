//
//  EmailSourceConfigurationView.swift
//  Khandoba Secure Docs
//
//  Email source configuration view
//

import SwiftUI

struct EmailSourceConfigurationView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var emailService = EmailIntegrationService.shared
    
    @State private var selectedProvider: EmailProvider = .gmail
    @State private var isConnecting = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Email Provider") {
                        Picker("Provider", selection: $selectedProvider) {
                            ForEach(EmailProvider.allCases, id: \.self) { provider in
                                Text(provider.displayName).tag(provider)
                            }
                        }
                    }
                    
                    Section {
                        if emailService.connectedProviders.contains(selectedProvider) {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundColor(colors.success)
                        } else {
                            Button {
                                Task {
                                    await connectProvider()
                                }
                            } label: {
                                HStack {
                                    if isConnecting {
                                        ProgressView()
                                    } else {
                                        Text("Connect \(selectedProvider.displayName)")
                                    }
                                }
                            }
                            .disabled(isConnecting)
                        }
                    }
                }
                .navigationTitle("Email Source")
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
    }
    
    private func connectProvider() async {
        isConnecting = true
        defer { isConnecting = false }
        
        do {
            try await emailService.connectProvider(selectedProvider)
        } catch {
            print("Failed to connect email provider: \(error)")
        }
    }
}

