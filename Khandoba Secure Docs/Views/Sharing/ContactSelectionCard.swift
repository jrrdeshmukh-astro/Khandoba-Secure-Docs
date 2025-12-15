//
//  ContactSelectionCard.swift
//  Khandoba Secure Docs
//
//  Apple Pay-style contact selection card
//

import SwiftUI
import Contacts

struct ContactSelectionCard: View {
    let contact: CNContact?
    let onTap: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var cardScale: CGFloat = 1.0
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: onTap) {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                // Contact Avatar or Placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colors.primary.opacity(0.25),
                                    colors.primary.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    if let contact = contact {
                        Image(systemName: "person.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(colors.primary)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(colors.primary)
                    }
                }
                
                // Contact Info or Placeholder
                VStack(alignment: .leading, spacing: 6) {
                    if let contact = contact {
                        Text("\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(colors.textPrimary)
                        
                        if let phone = contact.phoneNumbers.first?.value.stringValue {
                            Text(phone)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(colors.textSecondary)
                        } else if let email = contact.emailAddresses.first?.value as String? {
                            Text(email)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(colors.textSecondary)
                        }
                    } else {
                        Text("Select Contact")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Choose who to invite")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(colors.textTertiary)
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colors.surface,
                                colors.surface.opacity(0.95)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colors.primary.opacity(0.4),
                                        colors.primary.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: colors.primary.opacity(0.15), radius: 8, x: 0, y: 3)
            )
            .scaleEffect(cardScale)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                cardScale = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    cardScale = 1.0
                }
                onTap()
            }
        }
    }
}

