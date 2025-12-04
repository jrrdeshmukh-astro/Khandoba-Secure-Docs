//
//  EmergencyAccessView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct EmergencyAccessView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var reason = ""
    @State private var urgency: Urgency = .medium
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum Urgency: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "info.circle.fill"
            case .medium: return "exclamationmark.circle.fill"
            case .high: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Warning
                        StandardCard {
                            HStack(spacing: UnifiedTheme.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title)
                                    .foregroundColor(colors.error)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Emergency Protocol")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                        .fontWeight(.bold)
                                    
                                    Text("Only use in genuine emergencies. Requires admin approval. Access granted for 24 hours.")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Urgency Selection
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Urgency Level")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                                .padding(.horizontal)
                            
                            ForEach(Urgency.allCases, id: \.self) { level in
                                Button {
                                    urgency = level
                                } label: {
                                    StandardCard {
                                        HStack {
                                            Image(systemName: level.icon)
                                                .foregroundColor(level.color)
                                            
                                            Text(level.rawValue)
                                                .font(theme.typography.subheadline)
                                                .foregroundColor(colors.textPrimary)
                                            
                                            Spacer()
                                            
                                            if urgency == level {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(colors.primary)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Reason
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Emergency Reason")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                                .padding(.horizontal)
                            
                            TextField("Explain the emergency situation...", text: $reason, axis: .vertical)
                                .font(theme.typography.body)
                                .lineLimit(4...8)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                .padding(.horizontal)
                        }
                        
                        // Submit
                        Button {
                            submitRequest()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("Submit Emergency Request")
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(reason.isEmpty || isLoading)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Emergency Access")
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
        }
    }
    
    private func submitRequest() {
        guard let requesterID = authService.currentUser?.id else { return }
        
        isLoading = true
        
        let request = EmergencyAccessRequest(
            reason: reason,
            urgency: urgency.rawValue.lowercased()
        )
        request.vault = vault
        request.requesterID = requesterID
        
        modelContext.insert(request)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

