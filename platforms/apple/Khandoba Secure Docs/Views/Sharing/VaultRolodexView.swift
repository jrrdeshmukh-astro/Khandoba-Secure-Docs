//
//  VaultRolodexView.swift
//  Khandoba Secure Docs
//
//  Rolodex-style vault selector inspired by PassKit - Perfect Apple Cash style animations
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
    @State private var isDragging = false
    @Namespace private var cardNamespace
    
    private let cardSpacing: CGFloat = -120 // Overlap for stacked effect (PassKit style)
    private let cardHeight: CGFloat = 220
    private let cardWidth: CGFloat = 320
    private let maxVisibleCards = 3
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background blur effect (PassKit style)
                Color.clear
                    .background(.ultraThinMaterial)
                    .blur(radius: 20)
                
                // Stacked cards with perfect PassKit-style animations
                ForEach(Array(vaults.enumerated()), id: \.element.id) { index, vault in
                    let distance = abs(index - currentIndex)
                    
                    if distance <= maxVisibleCards {
                        VaultCardView(
                            vault: vault,
                            isSelected: selectedVault?.id == vault.id
                        ) {
                            selectVault(vault, at: index)
                        }
                        .frame(width: cardWidth, height: cardHeight)
                        .offset(
                            x: CGFloat(index - currentIndex) * (cardWidth + cardSpacing) + dragOffset,
                            y: CGFloat(distance) * 12 // Vertical stacking
                        )
                        .scaleEffect(calculateScale(for: distance))
                        .opacity(calculateOpacity(for: distance))
                        .zIndex(Double(vaults.count - distance))
                        .rotation3DEffect(
                            .degrees(calculateRotation(for: index)),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.5
                        )
                        .animation(
                            isDragging ? nil : .spring(response: 0.5, dampingFraction: 0.82, blendDuration: 0),
                            value: currentIndex
                        )
                        .animation(
                            isDragging ? nil : .spring(response: 0.5, dampingFraction: 0.82, blendDuration: 0),
                            value: dragOffset
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        isDragging = false
                        let threshold: CGFloat = cardWidth * 0.25 // 25% of card width
                        let velocity = value.predictedEndTranslation.width - value.translation.width
                        
                        // Determine direction based on drag distance and velocity
                        if abs(value.translation.width) > threshold || abs(velocity) > 200 {
                            if value.translation.width > 0 && currentIndex > 0 {
                                // Swipe right - previous card
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                                    currentIndex -= 1
                                    if currentIndex >= 0 && currentIndex < vaults.count {
                                        selectedVault = vaults[currentIndex]
                                        onVaultSelected(vaults[currentIndex])
                                    }
                                }
                            } else if value.translation.width < 0 && currentIndex < vaults.count - 1 {
                                // Swipe left - next card
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                                    currentIndex += 1
                                    if currentIndex < vaults.count {
                                        selectedVault = vaults[currentIndex]
                                        onVaultSelected(vaults[currentIndex])
                                    }
                                }
                            }
                        }
                        
                        // Snap back if threshold not met
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                            dragOffset = 0
                        }
                    }
            )
        }
        .frame(height: cardHeight + 60)
        .onAppear {
            if let firstVault = vaults.first {
                selectedVault = firstVault
                currentIndex = 0
            }
        }
    }
    
    // Calculate scale based on distance (PassKit style - cards get smaller behind)
    private func calculateScale(for distance: Int) -> CGFloat {
        let baseScale: CGFloat = 1.0
        let scaleReduction: CGFloat = 0.12 // 12% reduction per card
        return max(0.7, baseScale - CGFloat(distance) * scaleReduction)
    }
    
    // Calculate opacity based on distance (fade cards behind)
    private func calculateOpacity(for distance: Int) -> Double {
        if distance == 0 {
            return 1.0
        } else if distance == 1 {
            return 0.85
        } else if distance == 2 {
            return 0.6
        } else {
            return max(0.0, 0.6 - Double(distance - 2) * 0.2)
        }
    }
    
    // Calculate 3D rotation for perspective effect
    private func calculateRotation(for index: Int) -> Double {
        let offset = Double(index - currentIndex)
        return offset * 8.0 // Slight rotation for depth
    }
    
    private func selectVault(_ vault: Vault, at index: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            currentIndex = index
            selectedVault = vault
            onVaultSelected(vault)
        }
    }
}

