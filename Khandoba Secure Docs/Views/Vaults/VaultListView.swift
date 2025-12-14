//
//  VaultListView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct VaultListView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    @Environment(\.modelContext) private var modelContext
    
    @State private var showCreateVault = false
    @State private var isLoading = false
    @State private var selectedVaultID: UUID?
    @State private var navigateToVaultID: UUID?
    @State private var cardsAppeared = false
    
    // Face ID authentication state
    @State private var pendingVaultID: UUID?
    @State private var isAuthenticating = false
    @State private var showFaceIDPrompt = false
    
    // Rolodex state
    @Namespace private var cardNamespace
    @State private var scrollOffset: CGFloat = 0
    @State private var isDragging = false
    private let cardHeight: CGFloat = 220
    private let cardSpacing: CGFloat = -160 // overlap
    private let snapThreshold: CGFloat = 0.33
    
    // Filter out system vaults (Intel Reports, etc.)
    private var userVaults: [Vault] {
        vaultService.vaults.filter { vault in
            vault.name != "Intel Reports" && !vault.isSystemVault
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    LoadingView("Loading vaults...")
                } else if userVaults.isEmpty {
                    VStack(spacing: UnifiedTheme.Spacing.xl) {
                        let emptyVault = Vault(
                            name: "Create Your First Vault",
                            vaultDescription: "Tap to get started",
                            status: "locked",
                            keyType: "single"
                        )
                        WalletCard(
                            vault: emptyVault,
                            index: 0,
                            totalCount: 1,
                            hasActiveSession: false,
                            onTap: { showCreateVault = true },
                            onLongPress: nil,
                            rotation: 0,
                            scale: 1.0,
                            yOffset: 0,
                            z: 1,
                            namespace: cardNamespace,
                            isFrontCard: true
                        )
                        .frame(height: cardHeight)
                        .padding(.horizontal, UnifiedTheme.Spacing.lg)
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Text("No Vaults Yet")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Create your first secure vault to store documents")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    }
                } else {
                    // Circular rolodex view (PassKit-inspired)
                    CircularRolodexView(
                        vaults: userVaults,
                        vaultService: vaultService,
                        cardHeight: cardHeight,
                        cardSpacing: cardSpacing,
                        cardNamespace: cardNamespace,
                        selectedVaultID: $pendingVaultID, // Use pendingVaultID to intercept taps
                        cardsAppeared: cardsAppeared
                    )
                    .background(
                        // Hidden NavigationLink for programmatic navigation
                        ForEach(userVaults) { vault in
                            NavigationLink(
                                destination: VaultDetailView(vault: vault),
                                tag: vault.id,
                                selection: $selectedVaultID
                            ) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                    )
                    .onChange(of: pendingVaultID) { oldValue, newValue in
                        // Intercept vault selection - require Face ID first
                        if let vaultID = newValue {
                            Task {
                                await authenticateAndOpenVault(vaultID: vaultID)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vaults")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateVault = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateVault) {
                CreateVaultView()
            }
            .refreshable {
                await loadVaults()
            }
            .overlay {
                // Face ID prompt overlay
                if showFaceIDPrompt {
                    FaceIDPromptOverlay(
                        isAuthenticating: isAuthenticating,
                        onCancel: {
                            pendingVaultID = nil
                            showFaceIDPrompt = false
                        }
                    )
                }
            }
        }
        .task {
            await loadVaults()
            try? await Task.sleep(nanoseconds: 100_000_000)
            withAnimation {
                cardsAppeared = true
            }
        }
        .onChange(of: userVaults.count) { oldValue, newValue in
            if newValue > 0 {
                cardsAppeared = false
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    withAnimation {
                        cardsAppeared = true
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToVault)) { notification in
            if let vaultID = notification.userInfo?["vaultID"] as? UUID {
                navigateToVault(vaultID: vaultID)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareInvitationReceived)) { _ in
            Task { await loadVaults() }
        }
        .onChange(of: navigateToVaultID) { oldValue, newValue in
            if let vaultID = newValue {
                selectedVaultID = vaultID
                navigateToVaultID = nil
            }
        }
    }
    
    private func snapToNearestCard(proxy: ScrollViewProxy, containerTop: CGFloat) {
        // The system ScrollView doesn’t expose programmatic offset directly;
        // for a simple snap feel, we rely on natural spring + overlap values.
        // If you want precise snapping, consider ScrollViewReader with anchor IDs
        // and compute the nearest index to scroll to. Keeping it lightweight now.
    }
    
    private func navigateToVault(vaultID: UUID) {
        Task {
            await loadVaults()
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                if userVaults.contains(where: { $0.id == vaultID }) {
                    selectedVaultID = vaultID
                } else {
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run {
                            if userVaults.contains(where: { $0.id == vaultID }) {
                                selectedVaultID = vaultID
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func loadVaults() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await vaultService.loadVaults()
        } catch {
            print("Error loading vaults: \(error)")
        }
    }
    
    // MARK: - Face ID Authentication Flow
    
    private func authenticateAndOpenVault(vaultID: UUID) async {
        // Check if vault already has active session
        if vaultService.hasActiveSession(for: vaultID) {
            // Already unlocked, navigate directly
            await MainActor.run {
                selectedVaultID = vaultID
                pendingVaultID = nil
            }
            return
        }
        
        // Require Face ID authentication
        await MainActor.run {
            isAuthenticating = true
            showFaceIDPrompt = true
        }
        
        let reason = "Authenticate to access this vault"
        let success = await LocalAuthService.shared.authenticate(reason: reason)
        
        await MainActor.run {
            isAuthenticating = false
            showFaceIDPrompt = false
            
            if success {
                // Unlock the vault
                Task {
                    do {
                        // Find the vault from vaultService
                        let vaults = vaultService.vaults
                        if let vault = vaults.first(where: { $0.id == vaultID }) {
                            try await vaultService.openVault(vault)
                            await MainActor.run {
                                // Navigate to vault detail after successful unlock
                                selectedVaultID = vaultID
                                pendingVaultID = nil
                            }
                        } else {
                            print("⚠️ Vault not found: \(vaultID)")
                            await MainActor.run {
                                pendingVaultID = nil
                            }
                        }
                    } catch {
                        print("❌ Error unlocking vault: \(error)")
                        await MainActor.run {
                            pendingVaultID = nil
                        }
                    }
                }
            } else {
                // Authentication failed, don't navigate
                pendingVaultID = nil
            }
        }
    }
}

// MARK: - Circular Rolodex View
struct CircularRolodexView: View {
    let vaults: [Vault]
    let vaultService: VaultService
    let cardHeight: CGFloat
    let cardSpacing: CGFloat
    let cardNamespace: Namespace.ID
    @Binding var selectedVaultID: UUID? // This is actually pendingVaultID from parent
    let cardsAppeared: Bool
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    
    private let visibleCards = 5 // Show 5 cards in the stack
    
    var body: some View {
        GeometryReader { geo in
            let centerY = geo.size.height * 0.4 // Position cards in upper portion
            let centerX = geo.size.width / 2
            
            ZStack {
                // Render cards from back to front (so front card appears on top)
                ForEach((0..<min(visibleCards, vaults.count)).reversed(), id: \.self) { offset in
                    let index = (currentIndex + offset) % vaults.count
                    let vault = vaults[index]
                    
                    // Position: 0 = front card, higher = behind
                    let position = CGFloat(offset)
                    let relativePosition = position + (dragOffset / cardHeight)
                    let clamped = max(0, min(CGFloat(visibleCards - 1), relativePosition))
                    
                    // 3D rotation: cards tilt as they move behind
                    let rotation = Double(-clamped * 20)
                    
                    // Scale: cards behind are smaller
                    let scale = CGFloat(1.0 - clamped * 0.1)
                    
                    // Vertical offset: stack cards with overlap
                    let offsetY = clamped * (cardHeight + cardSpacing)
                    
                    // Opacity: fade cards behind
                    let opacity = Double(max(0.3, 1.0 - clamped * 0.25))
                    
                    // zIndex: front card (offset 0) has highest z, behind cards have lower z
                    let z = Double(visibleCards - Int(clamped))
                    
                    WalletCard(
                        vault: vault,
                        index: index,
                        totalCount: vaults.count,
                        hasActiveSession: vaultService.hasActiveSession(for: vault.id),
                        onTap: {
                            selectedVaultID = vault.id
                        },
                        onLongPress: nil,
                        rotation: rotation,
                        scale: scale,
                        yOffset: offsetY,
                        z: z,
                        opacity: opacity,
                        namespace: cardNamespace,
                        isFrontCard: offset == 0 // Only front card (offset 0) is source for matched geometry
                    )
                    .frame(height: cardHeight)
                    .frame(width: geo.size.width - (UnifiedTheme.Spacing.lg * 2))
                    .position(x: centerX, y: centerY + offsetY)
                    .opacity(cardsAppeared ? opacity : 0)
                    .scaleEffect(cardsAppeared ? scale : 0.8)
                    .zIndex(z)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.85),
                        value: currentIndex
                    )
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.9),
                        value: dragOffset
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { dragValue in
                        dragOffset = dragValue.translation.height
                    }
                    .onEnded { dragValue in
                        let threshold: CGFloat = cardHeight * 0.25
                        let translation = dragValue.translation.height
                        let velocity = dragValue.predictedEndTranslation.height - translation
                        
                        // Determine if we should move to next/previous card
                        let shouldMove = abs(translation) > threshold || abs(velocity) > 400
                        
                        if shouldMove {
                            if translation > 0 {
                                // Swipe down: move to next card (current goes behind)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    currentIndex = (currentIndex + 1) % vaults.count
                                }
                            } else {
                                // Swipe up: move to previous card (bring previous forward)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    currentIndex = (currentIndex - 1 + vaults.count) % vaults.count
                                }
                            }
                        }
                        
                        // Reset drag offset
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            dragOffset = 0
                        }
                    }
            )
        }
    }
}

// MARK: - Face ID Prompt Overlay
private struct FaceIDPromptOverlay: View {
    let isAuthenticating: Bool
    let onCancel: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                Image(systemName: LocalAuthService.shared.biometricType() == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 48, weight: .regular, design: .rounded))
                    .foregroundColor(colors.primary)
                
                Text("Unlock Vault")
                    .font(theme.typography.title2)
                    .foregroundColor(colors.textPrimary)
                
                Text("Authenticate to view vault")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textSecondary)
                
                if isAuthenticating {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                }
            }
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(), value: isAuthenticating)
    }
}

// Preference key for scroll offset tracking
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
