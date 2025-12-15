//
//  EmergencyRequestMessageView.swift
//  Khandoba Secure Docs
//
//  Emergency access request view for nominees
//

import SwiftUI

struct EmergencyRequestMessageView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    let vaultName: String
    let onSend: (String, String) -> Void
    let onCancel: () -> Void
    
    @State private var reason: String = ""
    @State private var selectedUrgency: EmergencyUrgency = .medium
    @FocusState private var isReasonFocused: Bool
    
    enum EmergencyUrgency: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            case .critical: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "info.circle"
            case .medium: return "exclamationmark.triangle"
            case .high: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
    
    var isValid: Bool {
        !reason.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    onCancel()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colors.primary)
                }
                
                Text("Emergency Access")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
            }
            .padding()
            .background(colors.surface)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Info Card
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(colors.primary)
                            Text("Emergency Protocol")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                        }
                        Text("This request requires manual approval from the vault owner. Access will be granted for 24 hours if approved.")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(colors.primary.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.top, 20)
                    
                    // Vault Info
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(colors.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vault")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                            Text(vaultName)
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(colors.surface)
                    .cornerRadius(12)
                    
                    // Urgency Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Urgency Level")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            ForEach(EmergencyUrgency.allCases, id: \.self) { urgency in
                                Button(action: {
                                    selectedUrgency = urgency
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: urgency.icon)
                                            .font(.system(size: 20))
                                        Text(urgency.rawValue)
                                            .font(theme.typography.caption)
                                    }
                                    .foregroundColor(selectedUrgency == urgency ? .white : colors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedUrgency == urgency ? urgency.color : colors.surface)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Reason (Required)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason for Emergency Access")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        TextField("Explain why you need emergency access...", text: $reason, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(theme.typography.body)
                            .foregroundColor(colors.textPrimary)
                            .lineLimit(4...8)
                            .padding()
                            .background(colors.surface)
                            .cornerRadius(12)
                            .focused($isReasonFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                if isValid {
                                    sendRequest()
                                }
                            }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            
            // Send Button
            VStack(spacing: 0) {
                Divider()
                
                Button(action: {
                    sendRequest()
                }) {
                    Text("Send Emergency Request")
                        .font(theme.typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? selectedUrgency.color : colors.textTertiary)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding()
            }
            .background(colors.background)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .onAppear {
            // Auto-focus reason field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isReasonFocused = true
            }
        }
    }
    
    private func sendRequest() {
        let requestReason = reason.trimmingCharacters(in: .whitespaces)
        onSend(requestReason, selectedUrgency.rawValue)
    }
}
