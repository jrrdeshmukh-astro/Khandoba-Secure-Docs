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
                            namespace: cardNamespace
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
                    GeometryReader { geo in
                        ScrollView {
                            VStack(spacing: cardSpacing) {
                                ForEach(Array(userVaults.enumerated()), id: \.element.id) { index, vault in
                                    GeometryReader { cardGeo in
                                        let cardTop = cardGeo.frame(in: .global).minY
                                        let viewTop = geo.safeAreaInsets.top + 100 // header area
                                        let relative = (cardTop - viewTop) / cardHeight
                                        
                                        // 3D rotation: tilt away when above, toward when below
                                        let clamped = max(-1.0, min(1.0, relative))
                                        let rotation = Double(-clamped * 15) // degrees
                                        
                                        // Scale slightly for depth
                                        let scale = CGFloat(1.0 - abs(clamped) * 0.05)
                                        
                                        // Lift top-most card a touch
                                        let offsetY: CGFloat = clamped < 0 ? clamped * 10 : clamped * 6
                                        
                                        // zIndex so the most centered card is on top
                                        let z = Double(1000 - Int(abs(clamped) * 1000)) + Double(index) * 0.001
                                        
                                        WalletCard(
                                            vault: vault,
                                            index: index,
                                            totalCount: userVaults.count,
                                            hasActiveSession: vaultService.hasActiveSession(for: vault.id),
                                            onTap: {
                                                selectedVaultID = vault.id
                                            },
                                            onLongPress: nil,
                                            rotation: rotation,
                                            scale: scale,
                                            yOffset: offsetY,
                                            z: z,
                                            namespace: cardNamespace
                                        )
                                        .frame(height: cardHeight)
                                        .opacity(cardsAppeared ? 1 : 0)
                                        .scaleEffect(cardsAppeared ? 1 : 0.96)
                                        .animation(
                                            .spring(response: 0.6, dampingFraction: 0.85)
                                                .delay(Double(index) * 0.06),
                                            value: cardsAppeared
                                        )
                                    }
                                    .frame(height: cardHeight)
                                    .padding(.horizontal, UnifiedTheme.Spacing.lg)
                                    .padding(.top, index == 0 ? UnifiedTheme.Spacing.lg : 0)
                                    .background(
                                        NavigationLink(
                                            destination: VaultDetailView(vault: vault),
                                            tag: vault.id,
                                            selection: $selectedVaultID
                                        ) { EmptyView() }
                                        .opacity(0)
                                    )
                                }
                            }
                            .padding(.bottom, UnifiedTheme.Spacing.xxl)
                            .background(
                                GeometryReader { scrollGeo in
                                    Color.clear
                                        .preference(key: ScrollOffsetKey.self, value: scrollGeo.frame(in: .global).minY)
                                }
                            )
                        }
                        .onPreferenceChange(ScrollOffsetKey.self) { value in
                            // Track to detect drag end for snapping
                            scrollOffset = value
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { _ in isDragging = true }
                                .onEnded { _ in
                                    isDragging = false
                                    snapToNearestCard(containerTop: geo.safeAreaInsets.top + 100)
                                }
                        )
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
    
    private func snapToNearestCard(containerTop: CGFloat) {
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
}

// Preference key for scroll offset tracking
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
