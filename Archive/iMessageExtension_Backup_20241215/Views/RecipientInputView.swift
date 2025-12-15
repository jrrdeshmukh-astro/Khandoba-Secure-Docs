//
//  RecipientInputView.swift
//  Khandoba Secure Docs
//
//  Recipient input view for nominee invitations
//

import SwiftUI

struct RecipientInputView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    let vaultName: String
    let onSend: (String, String?, String?) -> Void
    let onCancel: () -> Void
    
    @State private var recipientName: String = ""
    @State private var recipientPhone: String = ""
    @State private var recipientEmail: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, phone, email
    }
    
    var isValid: Bool {
        !recipientName.trimmingCharacters(in: .whitespaces).isEmpty
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
                
                Text("Invite Nominee")
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
                    .padding(.top, 20)
                    
                    // Recipient Name (Required)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipient Name")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        TextField("Enter name", text: $recipientName)
                            .textFieldStyle(.plain)
                            .font(theme.typography.body)
                            .foregroundColor(colors.textPrimary)
                            .padding()
                            .background(colors.surface)
                            .cornerRadius(12)
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .phone
                            }
                    }
                    
                    // Recipient Phone (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Phone Number")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                            
                            Text("(Optional)")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        TextField("Enter phone number", text: $recipientPhone)
                            .textFieldStyle(.plain)
                            .font(theme.typography.body)
                            .foregroundColor(colors.textPrimary)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(colors.surface)
                            .cornerRadius(12)
                            .focused($focusedField, equals: .phone)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .email
                            }
                    }
                    
                    // Recipient Email (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Email Address")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                            
                            Text("(Optional)")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        TextField("Enter email", text: $recipientEmail)
                            .textFieldStyle(.plain)
                            .font(theme.typography.body)
                            .foregroundColor(colors.textPrimary)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(colors.surface)
                            .cornerRadius(12)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.done)
                            .onSubmit {
                                if isValid {
                                    sendInvitation()
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
                    sendInvitation()
                }) {
                    Text("Send Invitation")
                        .font(theme.typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? colors.primary : colors.textTertiary)
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
            // Auto-focus name field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .name
            }
        }
    }
    
    private func sendInvitation() {
        let name = recipientName.trimmingCharacters(in: .whitespaces)
        let phone = recipientPhone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : recipientPhone.trimmingCharacters(in: .whitespaces)
        let email = recipientEmail.trimmingCharacters(in: .whitespaces).isEmpty ? nil : recipientEmail.trimmingCharacters(in: .whitespaces)
        
        onSend(name, phone, email)
    }
}
