//
//  VaultListView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import Combine
import Contacts

struct VaultListView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @State private var showCreateVault = false
    @State private var isLoading = false
    @State private var selectedVaultID: UUID?
    @State private var error: Error?
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
    
    // Nominee list state (Wallet-style)
    @StateObject private var nomineeService = NomineeService()
    @State private var selectedVault: Vault?
    @State private var showNomineeList = false
    @State private var frontVaultIndex: Int = 0
    @State private var showContactPicker = false
    @State private var vaultForInvite: Vault?
    @State private var selectedContacts: [CNContact] = []
    @State private var showInvitationConfirmation = false
    
    // Filter out system vaults (but include broadcast vaults)
    private var activeVaults: [Vault] {
        vaultService.vaults.filter { vault in
            vault.name != "Intel Reports" && 
            (!vault.isSystemVault || vault.isBroadcast)
        }
    }
    
    // For backward compatibility
    private var userVaults: [Vault] {
        activeVaults
    }
    
    @ViewBuilder
    private var emptyVaultsView: some View {
        let emptyVault = Vault(
            name: "Create Your First Vault",
            vaultDescription: "Tap to get started",
            status: "locked",
            keyType: "single"
        )
        let themeColors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.xl) {
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
            
            emptyVaultsText(colors: themeColors)
        }
    }
    
    @ViewBuilder
    private func emptyVaultsText(colors: UnifiedTheme.Colors) -> some View {
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
    
    var body: some View {
        let themeColors = theme.colors(for: colorScheme)
        let colors = themeColors
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if vaultService.isLoading || isLoading {
                    LoadingView("Loading vaults...")
                } else if userVaults.isEmpty {
                    emptyVaultsView
                } else {
                    mainContent(colors: colors)
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
            .sheet(isPresented: $showContactPicker) {
                if let vault = vaultForInvite {
                    ContactPickerView(
                        vault: vault,
                        onContactsSelected: { contacts in
                            selectedContacts = contacts
                            showContactPicker = false
                            showInvitationConfirmation = true
                        },
                        onDismiss: {
                            showContactPicker = false
                            vaultForInvite = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $showInvitationConfirmation) {
                if let vault = vaultForInvite, !selectedContacts.isEmpty {
                    SimplifiedContactSelectionView(
                        vault: vault,
                        preselectedContacts: selectedContacts
                    )
                }
            }
            .navigationDestination(isPresented: navigationBinding) {
                navigationDestinationView
            }
            .onChange(of: pendingVaultID) { oldValue, newValue in
                handlePendingVaultIDChange(oldValue: oldValue, newValue: newValue)
            }
            .refreshable {
                await loadVaults()
            }
            .errorAlert(error: $error)
            .overlay {
                if showFaceIDPrompt {
                    FaceIDPromptOverlay(
                        isAuthenticating: isAuthenticating,
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                pendingVaultID = nil
                                showFaceIDPrompt = false
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1000)
                }
            }
            .task {
                await loadVaults()
                try? await Task.sleep(nanoseconds: 100_000_000)
                withAnimation(AnimationStyles.spring) {
                    cardsAppeared = true
                }
            }
            .task {
                // Create or get "Open Street" broadcast vault on first load
                do {
                    try await vaultService.createOrGetOpenStreetVault()
                    // Reload vaults to include the broadcast vault
                    try? await vaultService.loadVaults()
                } catch {
                    print("⚠️ Failed to create/get Open Street vault: \(error.localizedDescription)")
                }
            }
            .onChange(of: userVaults.count) { oldValue, newValue in
                if newValue > 0 {
                    cardsAppeared = false
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        withAnimation(AnimationStyles.spring) {
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
            .onChange(of: selectedVaultID) { oldValue, newValue in
                if let vaultID = newValue, let vault = userVaults.first(where: { $0.id == vaultID }) {
                    selectedVault = vault
                } else if newValue == nil {
                    selectedVault = nil
                }
            }
        }
    }
    
    @ViewBuilder
    private func mainContent(colors: UnifiedTheme.Colors) -> some View {
        ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.xl) {
                if !activeVaults.isEmpty {
                    activeVaultsSection(colors: colors)
                    nomineeListSection(colors: colors)
                }
            }
            .padding(.vertical, UnifiedTheme.Spacing.lg)
            .padding(.top, UnifiedTheme.Spacing.md)
        }
    }
    
    @ViewBuilder
    private func activeVaultsSection(colors: UnifiedTheme.Colors) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Active Vaults")
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
                .padding(.horizontal)
                .padding(.bottom, UnifiedTheme.Spacing.lg)
            
            CircularRolodexView(
                vaults: activeVaults,
                vaultService: vaultService,
                cardHeight: cardHeight,
                cardSpacing: cardSpacing,
                cardNamespace: cardNamespace,
                selectedVaultID: $pendingVaultID,
                cardsAppeared: cardsAppeared,
                onFrontCardTap: { vault in
                    pendingVaultID = vault.id
                },
                onLongPress: { vault in
                    vaultForInvite = vault
                    showContactPicker = true
                },
                frontVaultIndex: $frontVaultIndex
            )
            .frame(height: cardHeight)
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func nomineeListSection(colors: UnifiedTheme.Colors) -> some View {
        if !activeVaults.isEmpty {
            let frontVault = activeVaults[frontVaultIndex % activeVaults.count]
            NomineeListSection(
                vault: frontVault,
                nomineeService: nomineeService,
                colors: colors,
                theme: theme
            )
            .padding(.top, UnifiedTheme.Spacing.xl)
            .transition(TransitionStyles.slideFromBottom)
            .id("nominees-\(frontVault.id)")
            .onAppear {
                loadNomineesForVault(frontVault)
            }
            .onChange(of: frontVaultIndex) { oldValue, newValue in
                let newVault = activeVaults[newValue % activeVaults.count]
                loadNomineesForVault(newVault)
            }
        }
    }
    
    private var navigationBinding: Binding<Bool> {
        Binding(
            get: { selectedVaultID != nil },
            set: { if !$0 { selectedVaultID = nil } }
        )
    }
    
    @ViewBuilder
    private var navigationDestinationView: some View {
        if let vaultID = selectedVaultID,
           let vault = activeVaults.first(where: { $0.id == vaultID }) {
            VaultDetailView(vault: vault)
        }
    }
    
    private func handlePendingVaultIDChange(oldValue: UUID?, newValue: UUID?) {
        if let vaultID = newValue {
            Task {
                await authenticateAndOpenVault(vaultID: vaultID)
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
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        do {
            try await vaultService.loadVaults()
        } catch let loadError {
            await MainActor.run {
                error = loadError
            }
            print("❌ Error loading vaults: \(loadError.localizedDescription)")
        }
    }
    
    // MARK: - Face ID Authentication Flow
    
    private func authenticateAndOpenVault(vaultID: UUID) async {
        // Check if vault already has active session
        if vaultService.hasActiveSession(for: vaultID) {
            // Already unlocked, show nominee list and navigate directly
            await MainActor.run {
                if let vault = userVaults.first(where: { $0.id == vaultID }) {
                    selectedVault = vault
                    loadNomineesForVault(vault)
                }
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
                                // Update selected vault
                                selectedVault = vault
                                
                                // Navigate to vault detail with smooth transition
                                withAnimation(AnimationStyles.spring) {
                                    selectedVaultID = vaultID
                                }
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
    
    // MARK: - Nominee Loading
    
    private func loadNomineesForVault(_ vault: Vault) {
        Task {
            // Configure nominee service if not already configured
            if nomineeService.nominees.isEmpty || nomineeService.nominees.first?.vault?.id != vault.id {
                if AppConfig.useSupabase {
                    if let userID = authService.currentUser?.id {
                        nomineeService.configure(supabaseService: supabaseService, currentUserID: userID)
                    } else {
                        nomineeService.configure(supabaseService: supabaseService)
                    }
                } else {
                if let userID = authService.currentUser?.id {
                    nomineeService.configure(modelContext: modelContext, currentUserID: userID)
                } else {
                    nomineeService.configure(modelContext: modelContext)
                    }
                }
            }
            
            do {
                try await nomineeService.loadNominees(for: vault)
            } catch {
                print("⚠️ Failed to load nominees: \(error.localizedDescription)")
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
    let onFrontCardTap: ((Vault) -> Void)? // Callback for front card tap
    let onLongPress: ((Vault) -> Void)? // Callback for long press
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @Binding var frontVaultIndex: Int // Expose front vault index to parent
    
    private let visibleCards = 5 // Show 5 cards in the stack
    
    var body: some View {
        GeometryReader { geo in
            let centerY = geo.size.height * 0.4 // Position cards in upper portion
            let centerX = geo.size.width / 2
            
            ZStack {
                // Render cards from back to front (so front card appears on top)
                ForEach((0..<min(visibleCards, vaults.count)).reversed(), id: \.self) { offset in
                    cardView(for: offset, centerX: centerX, centerY: centerY)
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                dragGesture,
                including: .all
            )
            .onChange(of: currentIndex) { oldValue, newValue in
                frontVaultIndex = newValue
            }
            .onAppear {
                frontVaultIndex = currentIndex
            }
        }
    }
    
    @ViewBuilder
    private func cardView(for offset: Int, centerX: CGFloat, centerY: CGFloat) -> some View {
        GeometryReader { geo in
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
                    // Double-tap navigates to vault detail for all cards
                    if offset == 0 {
                        // Front card: navigate to vault detail
                        onFrontCardTap?(vault)
                    } else {
                        // Other cards: navigate to vault detail
                        selectedVaultID = vault.id
                    }
                },
                onLongPress: {
                    // Long press on front card opens vault detail
                    if offset == 0 {
                        onLongPress?(vault)
                    }
                },
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
                AnimationStyles.spring,
                value: currentIndex
            )
            .animation(
                AnimationStyles.snap,
                value: dragOffset
            )
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 1.1).combined(with: .opacity)
                )
            )
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { dragValue in
                // Only respond to primarily vertical drags (rolodex rotation)
                // Allow horizontal drags to pass through to WalletCard for flipping
                let verticalMovement = abs(dragValue.translation.height)
                let horizontalMovement = abs(dragValue.translation.width)
                
                // Only update if vertical movement is dominant
                if verticalMovement > horizontalMovement {
                    dragOffset = dragValue.translation.height
                }
            }
            .onEnded { dragValue in
                let verticalMovement = abs(dragValue.translation.height)
                let horizontalMovement = abs(dragValue.translation.width)
                
                // Only process if vertical movement was dominant
                guard verticalMovement > horizontalMovement else {
                    // Horizontal drag - let WalletCard handle it, reset our offset
                    withAnimation(AnimationStyles.snap) {
                        dragOffset = 0
                    }
                    return
                }
                
                let threshold: CGFloat = cardHeight * 0.25
                let translation = dragValue.translation.height
                let velocity = dragValue.predictedEndTranslation.height - translation
                
                // Determine if we should move to next/previous card
                let shouldMove = abs(translation) > threshold || abs(velocity) > 400
                
                if shouldMove {
                    if translation > 0 {
                        // Swipe down: move to next card (current goes behind)
                        withAnimation(AnimationStyles.spring) {
                            currentIndex = (currentIndex + 1) % vaults.count
                            frontVaultIndex = currentIndex
                        }
                    } else {
                        // Swipe up: move to previous card (bring previous forward)
                        withAnimation(AnimationStyles.spring) {
                            currentIndex = (currentIndex - 1 + vaults.count) % vaults.count
                            frontVaultIndex = currentIndex
                        }
                    }
                }
                
                // Reset drag offset
                withAnimation(AnimationStyles.snap) {
                    dragOffset = 0
                }
            }
    }
}

// MARK: - Face ID Prompt Overlay
private struct FaceIDPromptOverlay: View {
    let isAuthenticating: Bool
    let onCancel: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            // Blurred background
            colors.background
                .ignoresSafeArea()
                .opacity(0.95)
            
            // Content
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                // Animated Face ID icon
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                    
                    Image(systemName: LocalAuthService.shared.biometricType() == .faceID ? "faceid" : "touchid")
                        .font(.system(size: 48, weight: .regular, design: .rounded))
                        .foregroundColor(colors.primary)
                }
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: pulseScale
                )
                
                Text("Unlock Vault")
                    .font(theme.typography.title2)
                    .foregroundColor(colors.textPrimary)
                
                Text("Double-tap to authenticate")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textSecondary)
                
                if isAuthenticating {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                }
                
                Button("Cancel") {
                    onCancel()
                }
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
                .padding(.top, UnifiedTheme.Spacing.md)
            }
            .padding(UnifiedTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colors.surface)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(UnifiedTheme.Spacing.lg)
        }
        .onAppear {
            pulseScale = 1.1
        }
    }
}

// Preference key for scroll offset tracking
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Nominee List Section (Wallet-style "Latest Transactions")
struct NomineeListSection: View {
    let vault: Vault
    @ObservedObject var nomineeService: NomineeService
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var revokingNomineeID: UUID?
    @State private var showInviteSheet = false
    @State private var selectedContactsForInvite: [CNContact] = []
    @State private var showInvitationConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header (Wallet-style)
            HStack {
                Text("Nominees")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                HStack(spacing: UnifiedTheme.Spacing.md) {
                    if !nomineeService.nominees.isEmpty {
                        Text("\(nomineeService.nominees.count)")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colors.surface)
                            .cornerRadius(8)
                    }
                    
                    // Invite Button
                    Button {
                        showInviteSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colors.primary)
                            .padding(8)
                            .background(colors.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, UnifiedTheme.Spacing.lg)
            .padding(.top, UnifiedTheme.Spacing.md)
            .padding(.bottom, UnifiedTheme.Spacing.sm)
            
            // Nominee List (Vertical, Wallet-style)
            if nomineeService.nominees.isEmpty {
                // Empty state with invite button
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(colors.textTertiary)
                    
                    VStack(spacing: UnifiedTheme.Spacing.xs) {
                        Text("No Nominees")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                        
                        Text("Invite people to access this vault")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textTertiary)
                    }
                    
                    Button {
                        showInviteSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Invite Nominee")
                        }
                        .font(theme.typography.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, UnifiedTheme.Spacing.lg)
                        .padding(.vertical, UnifiedTheme.Spacing.sm)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [colors.primary, colors.primary.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                    .padding(.top, UnifiedTheme.Spacing.md)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, UnifiedTheme.Spacing.xxl)
                .padding(.horizontal, UnifiedTheme.Spacing.lg)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(nomineeService.nominees.enumerated()), id: \.element.id) { index, nominee in
                        NomineeListItem(
                            nominee: nominee,
                            colors: colors,
                            theme: theme,
                            onRevoke: {
                                revokeNominee(nominee)
                            },
                            isRevoking: revokingNomineeID == nominee.id
                        )
                        .staggeredAppearance(index: index, total: nomineeService.nominees.count)
                        
                        if index < nomineeService.nominees.count - 1 {
                            Divider()
                                .padding(.leading, UnifiedTheme.Spacing.lg + 56 + UnifiedTheme.Spacing.md)
                        }
                    }
                }
                .background(colors.surface)
                .cornerRadius(UnifiedTheme.CornerRadius.lg)
            }
        }
        .padding(.horizontal, UnifiedTheme.Spacing.lg)
        .padding(.top, UnifiedTheme.Spacing.md)
        .sheet(isPresented: $showInviteSheet, onDismiss: {
            // Reload nominees when invitation sheet dismisses
            Task {
                if let userID = authService.currentUser?.id {
                    nomineeService.configure(modelContext: modelContext, currentUserID: userID)
                } else {
                    nomineeService.configure(modelContext: modelContext)
                }
                
                do {
                    try await nomineeService.loadNominees(for: vault)
                } catch {
                    print("⚠️ Failed to reload nominees: \(error.localizedDescription)")
                }
            }
        }) {
            // Directly open contact picker - no intermediate view with vault card
            ContactPickerView(
                vault: vault,
                onContactsSelected: { contacts in
                    selectedContactsForInvite = contacts
                    showInviteSheet = false
                    // Show confirmation view with selected contacts
                    showInvitationConfirmation = true
                },
                onDismiss: {
                    showInviteSheet = false
                }
            )
        }
        .sheet(isPresented: $showInvitationConfirmation) {
            if !selectedContactsForInvite.isEmpty {
                SimplifiedContactSelectionView(
                    vault: vault,
                    preselectedContacts: selectedContactsForInvite
                )
            }
        }
    }
    
    private func revokeNominee(_ nominee: Nominee) {
        guard revokingNomineeID == nil else { return }
        
        revokingNomineeID = nominee.id
        
        Task {
            do {
                if let userID = authService.currentUser?.id {
                    nomineeService.configure(modelContext: modelContext, currentUserID: userID)
                } else {
                    nomineeService.configure(modelContext: modelContext)
                }
                
                try await nomineeService.removeNominee(nominee, permanently: false)
                
                // Reload nominees after revoking
                try await nomineeService.loadNominees(for: vault)
                
                await MainActor.run {
                    revokingNomineeID = nil
                }
            } catch {
                print("⚠️ Failed to revoke nominee: \(error.localizedDescription)")
                await MainActor.run {
                    revokingNomineeID = nil
                }
            }
        }
    }
}

// MARK: - Nominee List Item (Wallet-style Transaction Row)
struct NomineeListItem: View {
    let nominee: Nominee
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    let onRevoke: () -> Void
    let isRevoking: Bool
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            // Avatar (Wallet-style circular icon)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                statusColor,
                                statusColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            // Name and Status
            VStack(alignment: .leading, spacing: 4) {
                Text(nominee.name)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // Status badge
                    Text(nominee.status.displayName)
                        .font(theme.typography.caption2)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(4)
                    
                    // Active indicator
                    if nominee.isCurrentlyActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(colors.success)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Revoke Button
            Button {
                onRevoke()
            } label: {
                if isRevoking {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(colors.error)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(colors.error.opacity(0.7))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isRevoking)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(AnimationStyles.spring, value: isPressed)
            .onLongPressGesture(minimumDuration: 0) {
                // Handle press state
            } onPressingChanged: { pressing in
                isPressed = pressing
            }
        }
        .padding(.horizontal, UnifiedTheme.Spacing.lg)
        .padding(.vertical, UnifiedTheme.Spacing.md)
        .contentShape(Rectangle())
    }
    
    private var statusColor: Color {
        switch nominee.status {
        case .pending: return colors.warning
        case .accepted, .active: return colors.success
        case .inactive, .revoked: return colors.textTertiary
        }
    }
}
