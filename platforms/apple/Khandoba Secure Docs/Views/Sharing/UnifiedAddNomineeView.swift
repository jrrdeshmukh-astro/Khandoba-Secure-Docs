//
//  UnifiedAddNomineeView.swift
//  Khandoba Secure Docs
//
//  Unified view for adding nominees with CloudKit sharing support
//

import SwiftUI
import SwiftData
import CloudKit

struct UnifiedAddNomineeView: View {
    let vault: Vault
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var nomineeService = NomineeService()
    @StateObject private var cloudKitSharing = CloudKitSharingService()
    @StateObject private var bluetoothService = BluetoothSessionNominationService()
    
    // Form fields
    @State private var nomineeName = ""
    @State private var accessLevel: NomineeAccessLevel = .view
    @State private var isSubsetAccess = false // Subset nomination toggle
    @State private var selectedDocumentIDs: Set<UUID> = [] // Selected documents for subset access
    @State private var sessionDuration: TimeInterval = 30 * 60 // Default 30 minutes
    @State private var showDocumentSelection = false
    @State private var useBluetooth = false // Bluetooth session nomination toggle
    
    // State
    @State private var isCreating = false
    @State private var createdNominee: Nominee?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCloudKitSharing = false
    @State private var cloudKitShare: CKShare?
    @State private var showSuccess = false
    @State private var showBluetoothNomination = false
    @StateObject private var documentService = DocumentService()
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        if showSuccess, let nominee = createdNominee {
                            // Success state - show sharing options
                            inviteSuccessView(nominee: nominee, colors: colors)
                        } else {
                            // Form state - enter nominee details
                            nomineeFormView(colors: colors)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Invite Nominee")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
                #endif
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showDocumentSelection) {
                DocumentSelectionView(
                    vault: vault,
                    selectedDocumentIDs: $selectedDocumentIDs,
                    documentService: documentService
                )
            }
            .sheet(isPresented: $showCloudKitSharing) {
                if let share = cloudKitShare {
                    CloudKitSharingView(
                        vault: vault,
                        share: share,
                        container: CKContainer(identifier: AppConfig.cloudKitContainer),
                        isPresented: $showCloudKitSharing
                    )
                }
            }
            .sheet(isPresented: $showBluetoothNomination) {
                BluetoothSessionNominationView(
                    vault: vault,
                    bluetoothService: bluetoothService,
                    selectedDocumentIDs: isSubsetAccess ? Array(selectedDocumentIDs) : nil,
                    sessionDuration: sessionDuration
                )
            }
            .onAppear {
                // Configure nominee service
                if AppConfig.useSupabase {
                    if let userID = authService.currentUser?.id {
                        nomineeService.configure(supabaseService: supabaseService, currentUserID: userID)
                    } else {
                        nomineeService.configure(supabaseService: supabaseService)
                    }
                } else {
                    nomineeService.configure(modelContext: modelContext)
                    cloudKitSharing.configure(modelContext: modelContext)
                }
                
                // Configure document service for document selection
                if let userID = authService.currentUser?.id {
                    if AppConfig.useSupabase {
                        documentService.configure(supabaseService: supabaseService, userID: userID)
                    } else {
                        documentService.configure(modelContext: modelContext, userID: userID)
                    }
                }
                
                // Load documents for selection
                Task {
                    try? await documentService.loadDocuments(for: vault)
                }
            }
        }
    }
    
    // MARK: - Nominee Form
    
    private func nomineeFormView(colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Header
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(colors.primary)
                
                Text("Add Nominee")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Text("Enter the nominee's details to generate an invitation")
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            // Vault Info
            StandardCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(colors.primary)
                        Text("Vault")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Text(vault.name)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Name Field
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    Text("Full Name *")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.semibold)
                    
                    TextField("Enter nominee's name", text: $nomineeName)
                        .font(theme.typography.body)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                        .padding(UnifiedTheme.Spacing.md)
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                }
            }
            
            // Access Level Selection
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                    Text("Access Level")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    ForEach(NomineeAccessLevel.allCases, id: \.self) { level in
                        AccessLevelRow(
                            level: level,
                            isSelected: accessLevel == level,
                            action: {
                                accessLevel = level
                            }
                        )
                    }
                }
            }
            
            // Bluetooth Session Nomination
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                    Toggle(isOn: $useBluetooth) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(colors.primary)
                                Text("Bluetooth Session Nomination")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                    .fontWeight(.semibold)
                            }
                            
                            Text("Share vault session with nearby devices via Bluetooth. Perfect for in-person collaboration.")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .tint(colors.primary)
                    
                    if useBluetooth {
                        Divider()
                        
                        Button {
                            showBluetoothNomination = true
                        } label: {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(colors.primary)
                                Text("Start Bluetooth Sharing")
                                    .foregroundColor(colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(colors.textTertiary)
                                    .font(.caption)
                            }
                            .padding(.vertical, UnifiedTheme.Spacing.sm)
                        }
                    }
                }
            }
            
            // Subset Access (Session-Based Nomination)
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                    Toggle(isOn: $isSubsetAccess) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Subset Access (Session-Based)")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                            
                            Text("Limit access to selected documents only. Access expires automatically when session ends.")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .tint(colors.primary)
                    
                    if isSubsetAccess {
                        Divider()
                        
                        // Document Selection
                        Button {
                            showDocumentSelection = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundColor(colors.primary)
                                
                                Text(selectedDocumentIDs.isEmpty ? "Select Documents" : "\(selectedDocumentIDs.count) document(s) selected")
                                    .foregroundColor(colors.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(colors.textTertiary)
                                    .font(.caption)
                            }
                            .padding(.vertical, UnifiedTheme.Spacing.sm)
                        }
                        
                        // Session Duration
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Session Duration")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                            
                            Picker("Duration", selection: $sessionDuration) {
                                Text("15 minutes").tag(15.0 * 60)
                                Text("30 minutes").tag(30.0 * 60)
                                Text("1 hour").tag(60.0 * 60)
                                Text("2 hours").tag(120.0 * 60)
                                Text("4 hours").tag(240.0 * 60)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
            }
            
            // Info Card
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(colors.info)
                        Text("How it works")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Nominees get real-time concurrent access when you unlock the vault. When you open the vault, they can access it too. No documents are copied - they see the same vault synchronized in real-time.")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            // Create Button
            Button {
                createNominee()
            } label: {
                HStack {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus.fill")
                        Text("Create Nominee & Share")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCreate ? colors.primary : colors.surface)
                .foregroundColor(canCreate ? .white : colors.textTertiary)
                .cornerRadius(UnifiedTheme.CornerRadius.lg)
            }
            .disabled(!canCreate || isCreating)
        }
    }
    
    // MARK: - Invite Success View
    
    private func inviteSuccessView(nominee: Nominee, colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Success Header
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(colors.success)
                
                Text("Nominee Created!")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Text("Share the invitation using CloudKit")
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
            }
            .padding(.top)
            
            // Nominee Info
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(colors.primary)
                        Text("Nominee Details")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    Text(nominee.name)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Action Buttons
            VStack(spacing: UnifiedTheme.Spacing.md) {
                // CloudKit Share Button (Primary - Recommended)
                Button {
                    Task {
                        await presentCloudKitSharing()
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share Invitation")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
                
                // Copy Link Button (Fallback)
                Button {
                    copyInviteLink(nominee: nominee)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy Link")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.secondary)
                    .foregroundColor(.white)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
            }
            
            // Done Button
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.surface)
                    .foregroundColor(colors.textPrimary)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canCreate: Bool {
        !nomineeName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Actions
    
    private func createNominee() {
        guard canCreate else { return }
        guard let currentUser = authService.currentUser else {
            errorMessage = "You must be logged in to create nominees"
            showError = true
            return
        }
        
        isCreating = true
        
        Task {
            do {
                // Prepare subset access parameters
                let selectedIDs = isSubsetAccess && !selectedDocumentIDs.isEmpty ? Array(selectedDocumentIDs) : nil
                let expiresAt = isSubsetAccess ? Date().addingTimeInterval(sessionDuration) : nil
                
                let nominee = try await nomineeService.inviteNominee(
                    name: nomineeName.trimmingCharacters(in: .whitespaces),
                    phoneNumber: nil,
                    email: nil,
                    to: vault,
                    invitedByUserID: currentUser.id,
                    selectedDocumentIDs: selectedIDs,
                    sessionExpiresAt: expiresAt,
                    isSubsetAccess: isSubsetAccess
                )
                
                await MainActor.run {
                    createdNominee = nominee
                    isCreating = false
                    showSuccess = true
                    
                    // Automatically present CloudKit sharing if available
                    Task {
                        await presentCloudKitSharing()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                }
            }
        }
    }
    
    private func copyInviteLink(nominee: Nominee) {
        let deepLink = "khandoba://invite?token=\(nominee.inviteToken)"
        let message = generateInvitationMessage(nominee: nominee, deepLink: deepLink)
        #if os(iOS)
        UIPasteboard.general.string = message
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message, forType: .string)
        #else
        // Other platforms: no-op
        #endif
        // You can show a toast/alert on iOS/macOS if desired
    }
    
    private func generateInvitationMessage(nominee: Nominee, deepLink: String) -> String {
        let vaultName = vault.name
        let message = """
        You've been invited to access a vault in Khandoba Secure Docs!
        
        Vault: \(vaultName)
        Invited by: \(authService.currentUser?.fullName ?? "Vault Owner")
        
        Tap to accept: \(deepLink)
        
        Or download Khandoba Secure Docs from the App Store and use this token:
        \(nominee.inviteToken)
        """
        return message
    }
    
    // MARK: - CloudKit Sharing
    
    private func presentCloudKitSharing() async {
        print("📤 Presenting CloudKit sharing for vault: \(vault.name)")
        
        do {
            if let share = try await cloudKitSharing.getOrCreateShare(for: vault) {
                await MainActor.run {
                    cloudKitShare = share
                    showCloudKitSharing = true
                }
                print("   ✅ CloudKit sharing controller will be presented")
            } else {
                print("   ℹ️ CloudKit share not available - user can use fallback option")
                // Don't show error - just let user use the copy link button
            }
        } catch {
            print("   ℹ️ CloudKit sharing not available: \(error.localizedDescription)")
            // Don't show error - just let user use the copy link button
        }
    }
}

// MARK: - Document Selection View

struct DocumentSelectionView: View {
    let vault: Vault
    @Binding var selectedDocumentIDs: Set<UUID>
    @ObservedObject var documentService: DocumentService
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                List {
                    ForEach(documentService.documents.filter { $0.vault?.id == vault.id && $0.status == "active" }) { document in
                        DocumentSelectionRow(
                            document: document,
                            isSelected: selectedDocumentIDs.contains(document.id)
                        ) {
                            if selectedDocumentIDs.contains(document.id) {
                                selectedDocumentIDs.remove(document.id)
                            } else {
                                selectedDocumentIDs.insert(document.id)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Select Documents")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
                #endif
            }
        }
    }
}

struct DocumentSelectionRow: View {
    let document: Document
    let isSelected: Bool
    let onToggle: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? colors.primary : colors.textTertiary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textPrimary)
                    
                    if let fileSize = document.fileSize as Int64? {
                        Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

