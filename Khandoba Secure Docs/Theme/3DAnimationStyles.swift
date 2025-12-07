//
// 3DAnimationStyles.swift
// Khandoba Secure Docs
//
// Comprehensive 3D Animation System
//

import SwiftUI

// MARK: - 3D Animation Styles

struct Animation3D {
    
    // MARK: - 3D Transform Presets
    
    /// Smooth 3D card flip animation
    static let cardFlip = Animation.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.2)
    
    /// Vault door opening with depth
    static let vaultOpen = Animation.interpolatingSpring(stiffness: 80, damping: 12, initialVelocity: 0)
    
    /// Floating/parallax effect
    static let floating = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    
    /// Perspective transform for depth
    static let perspective = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.15)
    
    /// 3D rotation for interactive elements
    static let rotation3D = Animation.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)
    
    /// Depth zoom effect
    static let depthZoom = Animation.interpolatingSpring(stiffness: 100, damping: 15, initialVelocity: 0)
}

// MARK: - 3D Card Flip Component

struct Card3DFlip<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    let front: () -> Front
    let back: () -> Back
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let perspective: CGFloat
    
    init(
        isFlipped: Binding<Bool>,
        axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0, 1, 0),
        perspective: CGFloat = 0.5,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self._isFlipped = isFlipped
        self.axis = axis
        self.perspective = perspective
        self.front = front
        self.back = back
    }
    
    var body: some View {
        ZStack {
            front()
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: axis,
                    perspective: perspective
                )
            
            back()
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: axis,
                    perspective: perspective
                )
        }
        .animation(Animation3D.cardFlip, value: isFlipped)
    }
}

// MARK: - 3D Vault Card

struct VaultCard3D: View {
    let vault: Vault
    let hasActiveSession: Bool
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    @State private var isFlipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var rotationZ: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var lastPanValue: CGSize = .zero
    
    var body: some View {
        Card3DFlip(isFlipped: $isFlipped) {
            // Front: Vault Info
            VaultCardFront(
                vault: vault,
                hasActiveSession: hasActiveSession,
                colors: colors,
                theme: theme
            )
        } back: {
            // Back: Vault Stats
            VaultCardBack(
                vault: vault,
                colors: colors,
                theme: theme
            )
        }
        .scaleEffect(scale)
        .rotation3DEffect(
            .degrees(rotationX),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.3
        )
        .rotation3DEffect(
            .degrees(rotationY),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.3
        )
        .rotation3DEffect(
            .degrees(rotationZ),
            axis: (x: 0, y: 0, z: 1),
            perspective: 0.1
        )
        .offset(dragOffset)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Enhanced pan gesture with 3D rotation
                    let deltaX = value.translation.width - lastPanValue.width
                    let deltaY = value.translation.height - lastPanValue.height
                    
                    // Rotate around Y axis (horizontal pan)
                    rotationY += Double(deltaX / 5)
                    
                    // Rotate around X axis (vertical pan)
                    rotationX -= Double(deltaY / 5)
                    
                    // Add slight Z rotation for natural feel
                    rotationZ = Double(deltaX / 20)
                    
                    // Scale based on distance from center
                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    scale = max(0.9, 1.0 - distance / 2000)
                    
                    dragOffset = value.translation
                    lastPanValue = value.translation
                }
                .onEnded { _ in
                    withAnimation(Animation3D.cardFlip) {
                        dragOffset = .zero
                        rotationX = 0
                        rotationY = 0
                        rotationZ = 0
                        scale = 1.0
                        lastPanValue = .zero
                    }
                }
        )
        .onTapGesture {
            withAnimation(Animation3D.cardFlip) {
                isFlipped.toggle()
            }
        }
    }
}

// MARK: - Vault Card Front

struct VaultCardFront: View {
    let vault: Vault
    let hasActiveSession: Bool
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
            HStack {
                // 3D Lock Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .shadow(color: statusColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: hasActiveSession ? "lock.open.fill" : "lock.fill")
                        .font(.title2)
                        .foregroundColor(statusColor)
                        .rotation3DEffect(
                            .degrees(hasActiveSession ? 15 : 0),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.2
                        )
                }
                
                Spacer()
                
                // Flip indicator
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(colors.textTertiary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vault.name)
                    .font(theme.typography.title3)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.bold)
                
                if let description = vault.vaultDescription, !description.isEmpty {
                    Text(description)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(2)
                }
            }
            
            HStack {
                Label("\(vault.documents?.count ?? 0) documents", systemImage: "doc.fill")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textTertiary)
                
                Spacer()
                
                if vault.keyType == "dual" {
                    HStack(spacing: 2) {
                        Image(systemName: "key.fill")
                            .font(.caption2)
                        Image(systemName: "key.fill")
                            .font(.caption2)
                            .rotationEffect(.degrees(15))
                    }
                    .foregroundColor(colors.warning)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(colors.warning.opacity(0.2))
                    .cornerRadius(4)
                }
            }
        }
        .padding(UnifiedTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.primary.opacity(0.1), radius: 12, x: 0, y: 6)
        )
    }
    
    private var statusColor: Color {
        hasActiveSession ? colors.success : colors.error
    }
}

// MARK: - Vault Card Back

struct VaultCardBack: View {
    let vault: Vault
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: "chart.bar.fill")
                .font(.title)
                .foregroundColor(colors.primary)
            
            Text("Vault Statistics")
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
            
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                StatRow(label: "Documents", value: "\(vault.documents?.count ?? 0)")
                StatRow(label: "Created", value: formatDate(vault.createdAt))
                StatRow(label: "Type", value: vault.keyType == "dual" ? "Dual-Key" : "Single-Key")
            }
            
            Text("Tap to flip back")
                .font(theme.typography.caption)
                .foregroundColor(colors.textTertiary)
        }
        .padding(UnifiedTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.primary.opacity(0.1), radius: 12, x: 0, y: 6)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - 3D Floating Effect

struct Floating3DEffect: ViewModifier {
    @State private var offset: CGFloat = 0
    let intensity: CGFloat
    let duration: Double
    
    init(intensity: CGFloat = 10, duration: Double = 3.0) {
        self.intensity = intensity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    offset = intensity
                }
            }
    }
}

// MARK: - Enhanced Pan Gesture (moved to PanGesture3D.swift)

// MARK: - 3D Parallax Effect with Enhanced Pan

struct Parallax3DEffect: ViewModifier {
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var offset: CGSize = .zero
    @State private var lastPanValue: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(rotationX),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.3
            )
            .rotation3DEffect(
                .degrees(rotationY),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.3
            )
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let deltaX = value.translation.width - lastPanValue.width
                        let deltaY = value.translation.height - lastPanValue.height
                        
                        // Smooth 3D rotation based on pan direction
                        rotationY += Double(deltaX / 8)
                        rotationX -= Double(deltaY / 8)
                        
                        // Parallax offset
                        offset = CGSize(
                            width: value.translation.width / 2,
                            height: value.translation.height / 2
                        )
                        
                        lastPanValue = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(Animation3D.perspective) {
                            rotationX = 0
                            rotationY = 0
                            offset = .zero
                            lastPanValue = .zero
                        }
                    }
            )
    }
}

// MARK: - 3D Depth Card

struct DepthCard3D<Content: View>: View {
    let content: Content
    let depth: CGFloat
    let shadowIntensity: CGFloat
    
    init(
        depth: CGFloat = 20,
        shadowIntensity: CGFloat = 0.3,
        @ViewBuilder content: () -> Content
    ) {
        self.depth = depth
        self.shadowIntensity = shadowIntensity
        self.content = content()
    }
    
    var body: some View {
        content
            .shadow(color: .black.opacity(shadowIntensity), radius: depth, x: 0, y: depth / 2)
            .scaleEffect(1.0)
    }
}

// MARK: - 3D Vault Door Enhanced

struct VaultDoor3D: View {
    @Binding var isOpen: Bool
    let colors: UnifiedTheme.Colors
    
    @State private var doorRotation: Double = 0
    @State private var lockScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Vault door with 3D depth
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            colors.surface,
                            colors.surface.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    colors.primary.opacity(0.6),
                                    colors.primary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                )
                .overlay(
                    // Lock mechanism
                    Circle()
                        .fill(colors.primary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(colors.background, lineWidth: 3)
                        )
                        .scaleEffect(lockScale)
                        .offset(x: 30, y: -60)
                )
                .shadow(color: colors.primary.opacity(0.4), radius: 20, x: 0, y: 10)
                .rotation3DEffect(
                    .degrees(doorRotation),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.3
                )
            
            // Lock icon overlay
            Image(systemName: isOpen ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 50))
                .foregroundColor(colors.primary)
                .scaleEffect(lockScale)
                .opacity(isOpen ? 0 : 1)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isOpen)
        }
        .onChange(of: isOpen) { _, newValue in
            withAnimation(Animation3D.vaultOpen) {
                doorRotation = newValue ? -90 : 0
                lockScale = newValue ? 1.3 : 1.0
            }
        }
    }
}

// MARK: - 3D Perspective Stack

struct PerspectiveStack3D<Content: View>: View {
    let items: [AnyView]
    let spacing: CGFloat
    let perspective: CGFloat
    
    init<Data: RandomAccessCollection, ID: Hashable>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        spacing: CGFloat = 20,
        perspective: CGFloat = 0.5,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.spacing = spacing
        self.perspective = perspective
        self.items = data.enumerated().map { index, element in
            AnyView(
                content(element)
                    .rotation3DEffect(
                        .degrees(Double(index) * 2),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: perspective
                    )
                    .offset(z: CGFloat(index) * spacing)
            )
        }
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                item
                    .zIndex(Double(items.count - index))
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Add 3D floating animation
    func floating3D(intensity: CGFloat = 10, duration: Double = 3.0) -> some View {
        modifier(Floating3DEffect(intensity: intensity, duration: duration))
    }
    
    /// Add 3D parallax effect
    func parallax3D() -> some View {
        modifier(Parallax3DEffect())
    }
    
    /// Add 3D depth with shadow
    func depth3D(depth: CGFloat = 20, shadowIntensity: CGFloat = 0.3) -> some View {
        DepthCard3D(depth: depth, shadowIntensity: shadowIntensity) {
            self
        }
    }
    
    /// 3D rotation on interaction
    func rotate3D(angle: Binding<Double>, axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0, 1, 0)) -> some View {
        self.rotation3DEffect(
            .degrees(angle.wrappedValue),
            axis: axis,
            perspective: 0.3
        )
        .animation(Animation3D.rotation3D, value: angle.wrappedValue)
    }
}

// MARK: - 3D Document Card

struct DocumentCard3D: View {
    let document: Document
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    @State private var isHovered = false
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastPanValue: CGSize = .zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
            HStack {
                Image(systemName: iconForDocumentType(document.documentType))
                    .font(.title2)
                    .foregroundColor(colors.primary)
                    .rotation3DEffect(
                        .degrees(rotationY + (isHovered ? 15 : 0)),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.2
                    )
                
                Spacer()
                
                if document.isEncrypted {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(colors.success)
                }
            }
            
            Text(document.name)
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
                .lineLimit(2)
            
            if !document.aiTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(document.aiTags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(colors.primary.opacity(0.1))
                                .foregroundColor(colors.primary)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(UnifiedTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surface)
                .shadow(
                    color: (isHovered || dragOffset != .zero) ? colors.primary.opacity(0.3) : colors.primary.opacity(0.1),
                    radius: (isHovered || dragOffset != .zero) ? 16 : 8,
                    x: 0,
                    y: (isHovered || dragOffset != .zero) ? 8 : 4
                )
        )
        .scaleEffect(scale)
        .rotation3DEffect(
            .degrees(rotationX + (isHovered ? 5 : 0)),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.2
        )
        .rotation3DEffect(
            .degrees(rotationY),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.2
        )
        .offset(dragOffset)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let deltaX = value.translation.width - lastPanValue.width
                    let deltaY = value.translation.height - lastPanValue.height
                    
                    // Smooth 3D rotation
                    rotationY += Double(deltaX / 6)
                    rotationX -= Double(deltaY / 6)
                    
                    // Scale based on pan distance
                    let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    scale = max(0.95, 1.0 - distance / 1500)
                    
                    dragOffset = value.translation
                    lastPanValue = value.translation
                    isHovered = true
                }
                .onEnded { _ in
                    withAnimation(Animation3D.perspective) {
                        rotationX = 0
                        rotationY = 0
                        dragOffset = .zero
                        scale = 1.0
                        lastPanValue = .zero
                        isHovered = false
                    }
                }
        )
        .onTapGesture {
            withAnimation(Animation3D.perspective) {
                isHovered.toggle()
            }
        }
    }
    
    private func iconForDocumentType(_ type: String) -> String {
        switch type {
        case "image": return "photo.fill"
        case "video": return "video.fill"
        case "audio": return "waveform"
        case "pdf": return "doc.fill"
        default: return "doc.fill"
        }
    }
}

