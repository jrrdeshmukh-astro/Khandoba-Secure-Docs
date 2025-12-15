//
//  VaultRolodexView.swift
//  Khandoba Secure Docs
//
//  Rolodex-style vault selector inspired by PassKit
//

import SwiftUI

struct VaultRolodexView: View {
    let vaults: [Vault]
    @Binding var selectedVault: Vault?
    let onVaultSelected: (Vault) -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var dragOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    @Namespace private var cardNamespace
    
    private let cardSpacing: CGFloat = 20
    private let cardHeight: CGFloat = 180
    private let cardWidth: CGFloat = 280
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        GeometryReader { geometry in
            ZStack {
                // Background cards (stacked effect)
                ForEach(Array(vaults.enumerated()), id: \.element.id) { index, vault in
                    if abs(index - currentIndex) <= 2 {
                        VaultCardView(
                            vault: vault,
                            isSelected: selectedVault?.id == vault.id
                        ) {
                            selectVault(vault, at: index)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .offset(
                            x: CGFloat(index - currentIndex) * (cardWidth + cardSpacing) + dragOffset,
                            y: CGFloat(abs(index - currentIndex)) * 10
                        )
                        .scaleEffect(1.0 - CGFloat(abs(index - currentIndex)) * 0.1)
                        .opacity(abs(index - currentIndex) <= 2 ? 1.0 - Double(abs(index - currentIndex)) * 0.3 : 0)
                        .zIndex(Double(vaults.count - abs(index - currentIndex)))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold && currentIndex > 0 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentIndex -= 1
                                if currentIndex < vaults.count {
                                    selectedVault = vaults[currentIndex]
                                }
                            }
                        } else if value.translation.width < -threshold && currentIndex < vaults.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentIndex += 1
                                if currentIndex < vaults.count {
                                    selectedVault = vaults[currentIndex]
                                }
                            }
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
            )
        }
        .frame(height: cardHeight + 40)
        .onAppear {
            if let firstVault = vaults.first {
                selectedVault = firstVault
                currentIndex = 0
            }
        }
    }
    
    private func selectVault(_ vault: Vault, at index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentIndex = index
            selectedVault = vault
            onVaultSelected(vault)
        }
    }
}
