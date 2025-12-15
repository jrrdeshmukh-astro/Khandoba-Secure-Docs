//
//  MessagesViewController.swift
//  Khandoba Secure Docs
//
//  Unified iMessage App (Apple Cash style) for vault invitations and file sharing
//

import UIKit
@preconcurrency import Messages
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation
import os.log

// MARK: - App Group Helper for iMessage Extension
extension MessagesViewController {
    /// Read pending nomination vault ID from App Group UserDefaults
    func readPendingNominationVaultID() -> UUID? {
        let appGroupIdentifier = MessageAppConfig.appGroupIdentifier
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return nil
        }
        
        guard let vaultIDString = sharedDefaults.string(forKey: "pendingNominationVaultID"),
              let vaultID = UUID(uuidString: vaultIDString) else {
            return nil
        }
        
        return vaultID
    }
    
    /// Clear pending nomination vault ID
    func clearPendingNominationVaultID() {
        let appGroupIdentifier = MessageAppConfig.appGroupIdentifier
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        sharedDefaults.removeObject(forKey: "pendingNominationVaultID")
        sharedDefaults.synchronize()
        
        print("📱 MessagesViewController: Cleared pending nomination vault ID")
    }
}

class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: - Helper Methods (defined early for forward reference)
    
    private func removeAllChildViewControllers() {
        for child in self.children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        // Also remove any remaining subviews
        self.view.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func presentErrorView(message: String, onRetry: @escaping () -> Void, onCancel: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let colors = UnifiedTheme().colors(for: .dark)
            let theme = UnifiedTheme()
            
            let errorView = VStack(spacing: 24) {
                // Error Icon
                ZStack {
                    Circle()
                        .fill(colors.warning.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(colors.warning)
                }
                .padding(.top, 40)
                
                // Error Message
                VStack(spacing: 8) {
                    Text("Error")
                        .font(theme.typography.title)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(message)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: onRetry) {
                        Text("Try Again")
                            .font(theme.typography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.primary)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.surface)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colors.background)
            
            let hostingController = UIHostingController(
                rootView: errorView.environment(\.unifiedTheme, UnifiedTheme())
            )
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
        }
    }
    
    // Helper for debug logging
    private func debugLog(_ message: String, hypothesisId: String, location: String, data: [String: Any] = [:]) {
        let logData: [String: Any] = [
            "sessionId": "debug-session",
            "runId": "run1",
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: logData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let logPath = "/Users/jaideshmukh/Desktop/Khandoba Secure Docs/.cursor/debug.log"
            let logLine = jsonString + "\n"
            
            // Create directory if it doesn't exist
            let logDir = (logPath as NSString).deletingLastPathComponent
            try? FileManager.default.createDirectory(atPath: logDir, withIntermediateDirectories: true, attributes: nil)
            
            // Append to file
            if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                fileHandle.seekToEndOfFile()
                if let logData = logLine.data(using: .utf8) {
                    fileHandle.write(logData)
                }
                fileHandle.closeFile()
            } else {
                // File doesn't exist, create it
                try? logLine.write(toFile: logPath, atomically: false, encoding: .utf8)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Clear any storyboard subviews immediately
        view.subviews.forEach { $0.removeFromSuperview() }
        
        // Set up view for SwiftUI
        view.backgroundColor = .systemBackground
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // #region agent log
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let extensionInfo: [String: Any] = [
            "bundleIdentifier": bundleID,
            "extensionPoint": "com.apple.message-payload-provider",
            "appGroup": MessageAppConfig.appGroupIdentifier,
            "localParticipant": conversation.localParticipantIdentifier.uuidString,
            "remoteParticipants": conversation.remoteParticipantIdentifiers.count
        ]
        DebugLogger.shared.log(
            location: "MessagesViewController.swift:193",
            message: "Extension willBecomeActive - Extension installation check",
            data: extensionInfo,
            hypothesisId: "A"
        )
        // #endregion
        
        print("📱 willBecomeActive called")
        print("   Bundle ID: \(bundleID)")
        print("   Conversation local participant: \(conversation.localParticipantIdentifier)")
        print("   Conversation remote participants: \(conversation.remoteParticipantIdentifiers.count)")
        
        // Request expanded presentation style to show full interface
        // This must be called before presenting views
        requestPresentationStyle(.expanded)
        
        // Check for pending nomination from main app
        if let pendingVaultID = readPendingNominationVaultID() {
            print("📱 MessagesViewController: Found pending nomination for vault: \(pendingVaultID)")
        }
        
        // Show main interface when extension becomes active
        // Use async to ensure presentation style is set first
        DispatchQueue.main.async { [weak self] in
            self?.presentMainInterface(for: conversation)
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Clean up when extension becomes inactive
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Handle received interactive messages
        handleReceivedMessage(message, in: conversation)
    }
    
    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        // Called when user taps an interactive message (Apple Cash style)
        handleMessageSelection(message, in: conversation)
    }
    
    // MARK: - Main Interface
    
    private func presentMainInterface(for conversation: MSConversation) {
        // Remove all child view controllers and subviews
        removeAllChildViewControllers()
        view.subviews.forEach { $0.removeFromSuperview() }
        
        // Show simple menu first
        presentSimpleMenu(conversation: conversation)
    }
    
    private func presentSimpleMenu(conversation: MSConversation) {
        logInfo("Presenting main menu")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                logError("self is nil in presentSimpleMenu")
                return
            }
            
            do {
                self.removeAllChildViewControllers()
                self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let menuView = SimpleMenuMessageView(
                onSelectVault: { [weak self] in
                    guard let self = self else { return }
                    logInfo("Invite Nominee selected")
                    // Ensure extension stays expanded
                    self.requestPresentationStyle(.expanded)
                    // Small delay to ensure presentation style is set
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.presentSimpleVaultSelection(for: conversation)
                    }
                },
                onTransfer: { [weak self] in
                    guard let self = self else { return }
                    logInfo("Transfer Ownership selected")
                    // Ensure extension stays expanded
                    self.requestPresentationStyle(.expanded)
                    // Show vault selection for transfer
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.presentTransferVaultSelection(for: conversation)
                    }
                },
                onEmergency: { [weak self] in
                    guard let self = self else { return }
                    logWarning("Emergency Protocol selected")
                    // Ensure extension stays expanded
                    self.requestPresentationStyle(.expanded)
                    // Show vault selection for emergency
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.presentEmergencyVaultSelection(for: conversation)
                    }
                },
                onCancel: {
                    logInfo("Menu cancelled")
                    self.requestPresentationStyle(.compact)
                }
            )
            
            let hostingController = UIHostingController(
                rootView: menuView.environment(\.unifiedTheme, UnifiedTheme())
            )
            
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
            
            logSuccess("Main menu presented successfully")
            } catch {
                logError("Failed to present main menu", error: error)
                self.presentErrorView(
                    message: "Failed to load menu. Please try again.",
                    onRetry: {
                        self.presentSimpleMenu(conversation: conversation)
                    },
                    onCancel: {
                        self.requestPresentationStyle(.compact)
                    }
                )
            }
        }
    }
    
    private func presentSimpleVaultSelection(for conversation: MSConversation) {
        print("🚀 presentSimpleVaultSelection - Starting Apple Cash-style flow")
        logInfo("Presenting Apple Cash-style nominee invitation flow")
        
        // Ensure extension stays expanded
        requestPresentationStyle(.expanded)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("❌ self is nil in presentSimpleVaultSelection")
                logError("self is nil in presentSimpleVaultSelection")
                return
            }
            
            print("🧹 Removing old views...")
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            print("🎨 Creating NomineeInvitationFlowView...")
            let invitationFlowView = NomineeInvitationFlowView(
                conversation: conversation,
                onCancel: { [weak self] in
                    guard let self = self else { return }
                    self.presentSimpleMenu(conversation: conversation)
                },
                onSend: { [weak self] vault, recipientName in
                    guard let self = self else { return }
                    // Create and send invitation immediately (Apple Cash style)
                    Task {
                        await self.createAndSendNominationImmediate(
                            vault,
                            recipientName: recipientName,
                            conversation: conversation
                        )
                    }
                }
            )
            
            print("📦 Creating UIHostingController...")
            let hostingController = UIHostingController(
                rootView: invitationFlowView.environment(\.unifiedTheme, UnifiedTheme())
            )
            
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            print("➕ Adding hosting controller to view hierarchy...")
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
            
            print("✅ Apple Cash-style invitation flow presented successfully!")
            logSuccess("Apple Cash-style invitation flow presented")
        }
    }
    
    // Apple Cash style: Send immediately without confirmation
    private func createAndSendNominationImmediate(
        _ vault: Vault,
        recipientName: String,
        conversation: MSConversation
    ) async {
        logInfo("Creating and sending nomination immediately (Apple Cash style)")
        
        do {
            // Create nomination and send message immediately
            try await sendNominationForVault(
                vault,
                recipientName: recipientName,
                recipientPhone: nil,
                recipientEmail: nil,
                in: conversation
            )
            
            // Apple Cash style: Collapse extension immediately after sending
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // Brief haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Collapse extension (message is already sent)
                self.requestPresentationStyle(.compact)
            }
        } catch {
            logError("Failed to create nomination", error: error)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.presentErrorView(
                    message: "Failed to send invitation: \(error.localizedDescription)",
                    onRetry: {
                        Task {
                            await self.createAndSendNominationImmediate(
                                vault,
                                recipientName: recipientName,
                                conversation: conversation
                            )
                        }
                    },
                    onCancel: {
                        self.requestPresentationStyle(.compact)
                    }
                )
            }
        }
    }
    
    private func presentRecipientInputView(for vault: Vault, conversation: MSConversation) {
        print("📱 presentRecipientInputView called for vault: \(vault.name)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let recipientInputView = RecipientInputView(
                vaultName: vault.name,
                onSend: { [weak self] name, phone, email in
                    guard let self = self else { return }
                    print("📱 Sending invitation to: \(name)")
                    // Show loading, then send nomination
                    self.presentLoadingView(message: "Sending invitation...")
                    
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        do {
                            try await self.sendNominationForVault(
                                vault,
                                recipientName: name,
                                recipientPhone: phone,
                                recipientEmail: email,
                                in: conversation
                            )
                            // Show success before collapsing
                            self.presentSuccessView(
                                message: "Invitation sent to \(name)!",
                                vaultName: vault.name,
                                onDismiss: {
                                    self.requestPresentationStyle(.compact)
                                }
                            )
                        } catch {
                            // Show error
                            self.presentErrorView(
                                message: "Failed to send invitation: \(error.localizedDescription)",
                                onRetry: {
                                    self.presentRecipientInputView(for: vault, conversation: conversation)
                                },
                                onCancel: {
                                    self.presentSimpleVaultSelection(for: conversation)
                                }
                            )
                        }
                    }
                },
                onCancel: { [weak self] in
                    guard let self = self else { return }
                    print("📱 Recipient input cancelled")
                    self.presentSimpleVaultSelection(for: conversation)
                }
            )
            
            let hostingController = UIHostingController(
                rootView: recipientInputView.environment(\.unifiedTheme, UnifiedTheme())
            )
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
            
            print("✅ RecipientInputView presented successfully")
        }
    }
    
    private func presentVaultSelectionView(for conversation: MSConversation) {
        print("📱 presentVaultSelectionView called")
        
        // Ensure this runs on main thread and doesn't block
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let vaultSelectionView = VaultSelectionMessageView(
                conversation: conversation,
                onTransfer: { [weak self] vault in
                    print("📱 Transfer selected for vault: \(vault.name)")
                    DispatchQueue.main.async {
                        self?.presentTransferOwnershipView(for: conversation, vault: vault)
                    }
                },
                onNominate: { [weak self] vault in
                    print("📱 Nominate selected for vault: \(vault.name)")
                    guard let self = self else { return }
                    self.presentLoadingView(message: "Sending invitation...")
                    
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        do {
                            try await self.sendNominationForVault(
                                vault,
                                recipientName: "Recipient",
                                in: conversation
                            )
                            self.presentSuccessView(
                                message: "Invitation sent successfully!",
                                vaultName: vault.name,
                                onDismiss: {
                                    self.requestPresentationStyle(.compact)
                                }
                            )
                        } catch {
                            self.presentErrorView(
                                message: "Failed to send invitation: \(error.localizedDescription)",
                                onRetry: {
                                    self.presentVaultSelectionView(for: conversation)
                                },
                                onCancel: {
                                    self.requestPresentationStyle(.compact)
                                }
                            )
                        }
                    }
                },
                onCancel: { [weak self] in
                    print("📱 Vault selection cancelled")
                    DispatchQueue.main.async {
                        self?.requestPresentationStyle(.compact)
                    }
                }
            )
            
            let hostingController = UIHostingController(
                rootView: vaultSelectionView.environment(\.unifiedTheme, UnifiedTheme())
            )
            
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
            
            print("📱 VaultSelectionMessageView presented successfully")
        }
    }
    
    /// Send nomination for a specific vault (Apple Pay style - immediate message)
    private func sendNominationForVault(
        _ vault: Vault,
        recipientName: String,
        recipientPhone: String? = nil,
        recipientEmail: String? = nil,
        in conversation: MSConversation
    ) async throws {
        print("📱 sendNominationForVault called for vault: \(vault.name), recipient: \(recipientName)")
        
        // #region agent log
        debugLog("sendNominationForVault entry", hypothesisId: "A", location: "MessagesViewController.swift:438", data: [
            "vaultId": vault.id.uuidString,
            "vaultName": vault.name,
            "recipientName": recipientName
        ])
        // #endregion
        
        // Always use shared container/context; re-fetch vault in that context
        try await withTimeout(seconds: 8) {
            let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
            let context = container.mainContext
            
            // #region agent log
            self.debugLog("SharedModelContainer created", hypothesisId: "A", location: "MessagesViewController.swift:443", data: ["containerCreated": true])
            // #endregion
            
            // Re-fetch vault by id in this context
            let allVaults = try context.fetch(FetchDescriptor<Vault>())
            
            // #region agent log
            self.debugLog("Vaults fetched from context", hypothesisId: "A", location: "MessagesViewController.swift:446", data: [
                "totalVaults": allVaults.count,
                "searchingForId": vault.id.uuidString,
                "foundVaults": allVaults.map { ["id": $0.id.uuidString, "name": $0.name] }
            ])
            // #endregion
            
            guard let fetchedVault = allVaults.first(where: { $0.id == vault.id }) else {
                // #region agent log
                self.debugLog("Vault not found - HYPOTHESIS A CONFIRMED", hypothesisId: "A", location: "MessagesViewController.swift:448", data: [
                    "searchedId": vault.id.uuidString,
                    "availableIds": allVaults.map { $0.id.uuidString }
                ])
                // #endregion
                throw NSError(domain: "MessageApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Vault not found. It may still be syncing."])
            }
            
            // #region agent log
            self.debugLog("Vault found successfully", hypothesisId: "A", location: "MessagesViewController.swift:450", data: [
                "fetchedVaultId": fetchedVault.id.uuidString,
                "fetchedVaultName": fetchedVault.name
            ])
            // #endregion
            
            try await self.createAndSendNomination(
                for: fetchedVault,
                context: context,
                recipientName: recipientName,
                recipientPhone: recipientPhone,
                recipientEmail: recipientEmail,
                in: conversation
            )
        }
    }
    
    private func createModelContainerAndSendNomination(
        for vault: Vault,
        recipientName: String,
        recipientPhone: String? = nil,
        recipientEmail: String? = nil,
        in conversation: MSConversation
    ) async throws {
        // Replaced by sendNominationForVault using SharedModelContainer; keep for backward compatibility if called elsewhere
        let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
        let context = container.mainContext
        let allVaults = try context.fetch(FetchDescriptor<Vault>())
        guard let fetchedVault = allVaults.first(where: { $0.id == vault.id }) else {
            throw NSError(domain: "MessageApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Vault not found. It may still be syncing."])
        }
        try await createAndSendNomination(
            for: fetchedVault,
            context: context,
            recipientName: recipientName,
            recipientPhone: recipientPhone,
            recipientEmail: recipientEmail,
            in: conversation
        )
    }
    
    // Helper function for timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Timeout Error
    private struct TimeoutError: Error {
        var localizedDescription: String {
            "Operation timed out"
        }
    }
    
    private func createAndSendNomination(
        for vault: Vault,
        context: ModelContext,
        recipientName: String,
        recipientPhone: String? = nil,
        recipientEmail: String? = nil,
        in conversation: MSConversation
    ) async throws {
        // Validate recipient information
        do {
            try ValidationHelpers.validateRecipient(
                name: recipientName,
                phone: recipientPhone,
                email: recipientEmail
            )
            logInfo("Recipient validation passed | Name: \(recipientName)")
        } catch {
            logError("Recipient validation failed", error: error)
            throw error
        }
        
        // Get current user
        let userDescriptor = FetchDescriptor<User>()
        let users: [User]
        do {
            users = try context.fetch(userDescriptor)
        } catch {
            logError("Failed to fetch users from context", error: error)
            throw NSError(domain: "MessageApp", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "Failed to load user data. Please try again."
            ])
        }
        
        let currentUser = users.first
        guard let currentUserID = currentUser?.id else {
            logError("User not found in context | Users found: \(users.count)")
            throw NSError(domain: "MessageApp", code: 1002, userInfo: [
                NSLocalizedDescriptionKey: "User not found. Please sign in to the main app first."
            ])
        }
        let senderName = currentUser?.fullName ?? "You"
        logInfo("User authenticated | ID: \(currentUserID.uuidString) | Name: \(senderName)")
        
        // Use NomineeService to create nominee (handles CloudKit sharing)
        let nomineeService = NomineeService()
        nomineeService.configure(modelContext: context, currentUserID: currentUserID)
        
        logInfo("Creating nominee invitation | Vault: \(vault.name) | Recipient: \(recipientName)")
        
        let nominee: Nominee
        do {
            nominee = try await nomineeService.inviteNominee(
                name: recipientName,
                phoneNumber: recipientPhone,
                email: recipientEmail,
                to: vault,
                invitedByUserID: currentUserID
            )
            logSuccess("Nominee created | ID: \(nominee.id.uuidString) | Token: \(nominee.inviteToken)")
            ProductionLogger.shared.logNomineeInvitation(
                vaultName: vault.name,
                recipientName: recipientName,
                token: nominee.inviteToken
            )
        } catch {
            logError("Failed to create nominee invitation", error: error)
            throw error
        }
        
        // Mark for sync and wait for CloudKit sync
        await MainActor.run {
            iMessageSyncService.shared.markNomineeCreated(nominee.id)
        }
        
        // Wait for CloudKit sync to ensure data is available in main app
        let syncStartTime = Date()
        do {
            try await iMessageSyncService.shared.waitForCloudKitSync(
                entityID: nominee.id,
                entityType: "Nominee",
                context: context,
                maxWait: 30.0,
                onProgress: { status in
                    logDebug("CloudKit sync progress | Status: \(status.displayName)")
                }
            )
            let syncDuration = Date().timeIntervalSince(syncStartTime)
            logSuccess("Nominee synced to CloudKit | Duration: \(String(format: "%.2f", syncDuration))s")
            ProductionLogger.shared.logCloudKitSync(
                entityType: "Nominee",
                entityID: nominee.id,
                status: "synced",
                duration: syncDuration
            )
        } catch {
            let syncDuration = Date().timeIntervalSince(syncStartTime)
            logWarning("CloudKit sync timeout or failed | Duration: \(String(format: "%.2f", syncDuration))s | Continuing with message send")
            ProductionLogger.shared.logCloudKitSync(
                entityType: "Nominee",
                entityID: nominee.id,
                status: "timeout",
                duration: syncDuration
            )
            // Don't throw - allow message to be sent even if sync verification times out
            // CloudKit will sync in background
        }
        
        // Apple Cash style: Send message immediately (no success screen)
        await MainActor.run {
            print("📤 Sending invitation message immediately (Apple Cash style)...")
            print("   Conversation active: \(conversation.localParticipantIdentifier)")
            
            // Send interactive message immediately
            self.sendNomineeInvitationMessage(
                inviteToken: nominee.inviteToken,
                vaultName: vault.name,
                senderName: senderName,
                in: conversation
            )
            
            // Brief haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Collapse extension after brief delay (message is sent)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    // MARK: - Nominee Invitation (legacy immediate send kept)
    
    private func sendInvitationImmediately(in conversation: MSConversation) {
        print("📱 sendInvitationImmediately called")
        
        Task {
            do {
                let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
                let context = container.mainContext
                
                // Get first available vault
                let descriptor = FetchDescriptor<Vault>(
                    sortBy: [SortDescriptor(\Vault.createdAt, order: .reverse)]
                )
                let vaults = try context.fetch(descriptor).filter { !$0.isSystemVault }
                
                guard let vault = vaults.first else {
                    await MainActor.run {
                        // Show error - no vaults available
                        let alert = UIAlertController(
                            title: "No Vaults",
                            message: "Please create a vault in the main app first.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                    return
                }
                
                // Get current user name or use default
                let userDescriptor = FetchDescriptor<User>()
                let users = try context.fetch(userDescriptor)
                let currentUser = users.first
                let senderName = currentUser?.fullName ?? "You"
                
                // Create nominee with default name (will be updated when recipient accepts)
                let inviteToken = UUID().uuidString
                let nominee = Nominee(
                    name: "Recipient", // Default name, can be updated later
                    phoneNumber: nil,
                    email: nil
                )
                nominee.vault = vault
                nominee.invitedByUserID = currentUser?.id
                nominee.inviteToken = inviteToken
                
                if vault.nomineeList == nil {
                    vault.nomineeList = []
                }
                vault.nomineeList?.append(nominee)
                
                context.insert(nominee)
                try context.save()
                
                print("✅ Nominee created with token: \(inviteToken)")
                
                // Send interactive message immediately
                await MainActor.run {
                    self.sendNomineeInvitationMessage(
                        inviteToken: inviteToken,
                        vaultName: vault.name,
                        senderName: senderName,
                        in: conversation
                    )
                }
                
            } catch {
                print("❌ Failed to send invitation immediately: \(error.localizedDescription)")
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to send invitation: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func presentNomineeInvitationView(for conversation: MSConversation) {
        print("📱 presentNomineeInvitationView called")
        
        // Ensure this runs on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("❌ self is nil in presentNomineeInvitationView")
                return
            }
            
            print("📱 Removing old view controllers...")
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            // Small delay to ensure cleanup is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                print("📱 Creating NomineeInvitationMessageView...")
                
                let invitationView = NomineeInvitationMessageView(
                    conversation: conversation,
                    onSendInvitation: { [weak self] inviteToken, vaultName, recipientName in
                        print("📱 onSendInvitation called with token: \(inviteToken)")
                        self?.sendNomineeInvitation(
                            inviteToken: inviteToken,
                            vaultName: vaultName,
                            recipientName: recipientName,
                            in: conversation
                        )
                    },
                    onCancel: { [weak self] in
                        print("📱 onCancel called, returning to main menu")
                        self?.presentMainInterface(for: conversation)
                    }
                )
                
                let hostingController = UIHostingController(
                    rootView: invitationView.environment(\.unifiedTheme, UnifiedTheme())
                )
                
                hostingController.view.backgroundColor = .systemBackground
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                
                self.addChild(hostingController)
                self.view.addSubview(hostingController.view)
                
                // Use constraints for better layout
                NSLayoutConstraint.activate([
                    hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                    hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                ])
                
                hostingController.didMove(toParent: self)
                
                print("📱 NomineeInvitationMessageView presented successfully")
            }
        }
    }
    
    /// Send the interactive message (Apple Pay style banner)
    private func sendNomineeInvitationMessage(
        inviteToken: String,
        vaultName: String,
        senderName: String,
        in conversation: MSConversation
    ) {
        logInfo("Sending nominee invitation message | Token: \(inviteToken) | Vault: \(vaultName) | Sender: \(senderName)")
        
        // Check if conversation has recipients - REQUIRED for message to send
        if conversation.remoteParticipantIdentifiers.isEmpty {
            logError("Cannot send invitation - no remote participants in conversation")
            DispatchQueue.main.async { [weak self] in
                self?.presentErrorView(
                    message: "Please select a contact in Messages before sending an invitation.",
                    onRetry: {},
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
            return
        }
        
        // Create invitation URL
        var components = URLComponents(string: "khandoba://nominee/invite")
        components?.queryItems = [
            URLQueryItem(name: "token", value: inviteToken),
            URLQueryItem(name: "vault", value: vaultName),
            URLQueryItem(name: "status", value: "pending"),
            URLQueryItem(name: "sender", value: senderName)
        ]
        
        guard let url = components?.url else {
            logError("Failed to create invitation URL")
            DispatchQueue.main.async { [weak self] in
                self?.presentErrorView(
                    message: "Failed to create invitation. Please try again.",
                    onRetry: {
                        self?.sendNomineeInvitationMessage(
                            inviteToken: inviteToken,
                            vaultName: vaultName,
                            senderName: senderName,
                            in: conversation
                        )
                    },
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
            return
        }
        
        logDebug("Invitation URL created | URL: \(url.absoluteString)")
        
        // Create interactive message layout (Apple Cash style - card-like appearance)
        let layout = MSMessageTemplateLayout()
        
        // Apple Cash style: Large prominent display (like "$1" in Apple Cash)
        // The caption is the main display - show vault name prominently
        layout.caption = vaultName  // Main display (like "$1" amount in Apple Cash)
        layout.subcaption = "Vault Invitation"  // Secondary text (like "Send to Aai")
        layout.trailingCaption = "Tap to Accept"  // Action hint (like "Double Click to Pay")
        layout.imageTitle = "Khandoba Secure Docs"  // App name/branding
        
        // Optional: Add media image if available (vault icon)
        // layout.image = vaultIconImage
        
        // Create message with enhanced summary
        let message = MSMessage()
        message.layout = layout
        message.url = url
        message.summaryText = "\(senderName) invited you to access vault: \(vaultName)"
        
        logDebug("Message created | Summary: \(message.summaryText ?? "nil")")
        
        // Insert message immediately (Apple Pay style - sends banner right away)
        // Must be called on main thread and conversation must be active
        conversation.insert(message) { [weak self] error in
            if let error = error {
                logError("Failed to send invitation message", error: error)
                
                // Show error to user with retry option
                DispatchQueue.main.async {
                    self?.presentErrorView(
                        message: "Failed to send invitation: \(error.localizedDescription)",
                        onRetry: {
                            // Retry sending the message
                            self?.sendNomineeInvitationMessage(
                                inviteToken: inviteToken,
                                vaultName: vaultName,
                                senderName: senderName,
                                in: conversation
                            )
                        },
                        onCancel: {
                            self?.requestPresentationStyle(.compact)
                        }
                    )
                }
            } else {
                logSuccess("Nominee invitation message sent successfully")
                
                // Show brief success feedback
                DispatchQueue.main.async { [weak self] in
                    // Brief haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }
    
    private func sendNomineeInvitation(
        inviteToken: String,
        vaultName: String,
        recipientName: String,
        in conversation: MSConversation
    ) {
        // Legacy method - now just calls the message sending method
        sendNomineeInvitationMessage(
            inviteToken: inviteToken,
            vaultName: vaultName,
            senderName: recipientName,
            in: conversation
        )
    }
    
    // MARK: - File Sharing
    
    private func presentFileSharingView(items: [NSExtensionItem], conversation: MSConversation) {
        removeAllChildViewControllers()
        
        let fileSharingView = FileSharingMessageView(
            items: items,
            conversation: conversation,
            onShareComplete: { [weak self] in
                self?.requestPresentationStyle(.compact)
            },
            onCancel: { [weak self] in
                self?.presentMainInterface(for: conversation)
            }
        )
        
        let hostingController = UIHostingController(
            rootView: fileSharingView.environment(\.unifiedTheme, UnifiedTheme())
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - Interactive Message Handling (Apple Cash Style)
    
    private func handleMessageSelection(_ message: MSMessage, in conversation: MSConversation) {
        guard let url = message.url,
              url.scheme == "khandoba" else {
            return
        }
        
        // Parse message data
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        
        let token = queryItems.first(where: { $0.name == "token" })?.value
        let vaultName = queryItems.first(where: { $0.name == "vault" })?.value ?? "Unknown Vault"
        let status = queryItems.first(where: { $0.name == "status" })?.value ?? "pending"
        let sender = queryItems.first(where: { $0.name == "sender" })?.value ?? "Vault Owner"
        
        // Determine message type based on URL path
        if url.host == "transfer" || url.path.contains("transfer") {
            // Show transfer ownership response UI
            presentTransferResponseView(
                message: message,
                conversation: conversation,
                token: token,
                vaultName: vaultName,
                sender: sender,
                status: status
            )
        } else {
            // Show nominee invitation response UI (default)
            presentInvitationResponseView(
                message: message,
                conversation: conversation,
                token: token,
                vaultName: vaultName,
                sender: sender,
                status: status
            )
        }
    }
    
    private func presentInvitationResponseView(
        message: MSMessage,
        conversation: MSConversation,
        token: String?,
        vaultName: String,
        sender: String,
        status: String
    ) {
        removeAllChildViewControllers()
        
        let responseView = InvitationResponseMessageView(
            message: message,
            conversation: conversation,
            token: token,
            vaultName: vaultName,
            sender: sender,
            status: status,
            onAccept: { [weak self] in
                self?.handleInvitationAcceptance(
                    message: message,
                    conversation: conversation,
                    token: token,
                    vaultName: vaultName
                )
            },
            onDecline: { [weak self] in
                self?.handleInvitationDecline(
                    message: message,
                    conversation: conversation
                )
            }
        )
        
        let hostingController = UIHostingController(
            rootView: responseView.environment(\.unifiedTheme, UnifiedTheme())
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    private func handleInvitationAcceptance(
        message: MSMessage,
        conversation: MSConversation,
        token: String?,
        vaultName: String
    ) {
        print("📥 handleInvitationAcceptance called")
        print("   Token: \(token ?? "nil")")
        print("   Vault: \(vaultName)")
        
        // Show loading state
        presentLoadingView(message: "Accepting invitation...")
        
        // Process acceptance in background
        Task { [weak self] in
            guard let self = self else { return }
            await processInvitationAcceptance(token: token, vaultName: vaultName)
            
            // Update message to accepted state on main thread
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                    let updatedLayout = MSMessageTemplateLayout()
                    updatedLayout.caption = "✅ Vault Access Accepted"
                    updatedLayout.subcaption = vaultName
                    updatedLayout.trailingCaption = "Accepted"
                    
                    var components = URLComponents(string: "khandoba://nominee/invite")
                    components?.queryItems = [
                        URLQueryItem(name: "token", value: token ?? ""),
                        URLQueryItem(name: "vault", value: vaultName),
                        URLQueryItem(name: "status", value: "accepted")
                    ]
                    
                    guard let updatedURL = components?.url else { 
                        self.presentErrorView(
                            message: "Failed to create update URL",
                            onRetry: {
                                self.handleInvitationAcceptance(message: message, conversation: conversation, token: token, vaultName: vaultName)
                            },
                            onCancel: {
                                self.requestPresentationStyle(.compact)
                            }
                        )
                        return
                    }
                    
                    let updatedMessage = MSMessage()
                    updatedMessage.layout = updatedLayout
                    updatedMessage.url = updatedURL
                    updatedMessage.summaryText = "✅ Accepted: \(vaultName)"
                    
                    conversation.insert(updatedMessage) { [weak self] error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("❌ Failed to update message: \(error.localizedDescription)")
                                
                                // #region agent log
                                self?.debugLog("Failed to update acceptance message", hypothesisId: "E", location: "MessagesViewController.swift:1189", data: [
                                    "error": error.localizedDescription
                                ])
                                // #endregion
                                
                                self?.presentErrorView(
                                    message: "Failed to update message: \(error.localizedDescription)",
                                    onRetry: { [weak self] in
                                        guard let self = self else { return }
                                        self.handleInvitationAcceptance(message: message, conversation: conversation, token: token, vaultName: vaultName)
                                    },
                                    onCancel: {
                                        self?.requestPresentationStyle(.compact)
                                    }
                                )
                            } else {
                                print("✅ Invitation accepted - message updated")
                                
                                // #region agent log
                                self?.debugLog("Acceptance message updated successfully", hypothesisId: "E", location: "MessagesViewController.swift:1202", data: [:])
                                // #endregion
                                
                                // Apple Cash style: Open main app immediately after acceptance
                                // Open main app with deep link to complete the flow
                                if let url = URL(string: "khandoba://nominee/invite?token=\(token ?? "")&vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)&status=accepted") {
                                    self?.extensionContext?.open(url) { success in
                                        if success {
                                            print("✅ Opened main app to process invitation")
                                            // Collapse extension after opening app
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                self?.requestPresentationStyle(.compact)
                                            }
                                        } else {
                                            print("⚠️ Failed to open main app, storing token for later")
                                            // Store token for later processing
                                            UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)?.set(token, forKey: "pending_invite_token")
                                            // Show success view as fallback
                                            self?.presentSuccessView(
                                                message: "Invitation accepted! Open the app to access '\(vaultName)'.",
                                                vaultName: vaultName,
                                                onDismiss: {
                                                    self?.requestPresentationStyle(.compact)
                                                }
                                            )
                                        }
                                    }
                                } else {
                                    // Fallback if URL creation fails
                                    self?.requestPresentationStyle(.compact)
                                }
                            }
                        }
                    }
                }
            }
    }
    
    // MARK: - Process Invitation Acceptance
    
    private func processInvitationAcceptance(token: String?, vaultName: String) async {
        guard let token = token, !token.isEmpty else {
            logError("No token provided for invitation acceptance")
            await MainActor.run { [weak self] in
                self?.presentErrorView(
                    message: "Invalid invitation token. Please check the invitation and try again.",
                    onRetry: {},
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
            return
        }
        
        // Validate token format (should be UUID)
        guard UUID(uuidString: token) != nil else {
            logError("Invalid token format | Token: \(token)")
            await MainActor.run { [weak self] in
                self?.presentErrorView(
                    message: "Invalid invitation format. Please use a valid invitation link.",
                    onRetry: {},
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
            return
        }
        
        logInfo("Processing invitation acceptance | Token: \(token) | Vault: \(vaultName)")
        ProductionLogger.shared.logNomineeAcceptance(token: token, vaultName: vaultName)
        
        // Show loading state
        await MainActor.run { [weak self] in
            self?.presentLoadingView(message: "Accepting invitation...")
        }
        
        // #region agent log
        debugLog("processInvitationAcceptance entry", hypothesisId: "D", location: "MessagesViewController.swift:1143", data: ["token": token])
        // #endregion
        
        // Load SwiftData context with App Group
        do {
            let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
            let context = container.mainContext
            logInfo("Model container loaded for invitation acceptance")
            
            // Use NomineeService to accept invitation (handles CloudKit sync)
            let nomineeService = NomineeService()
            nomineeService.configure(modelContext: context)
            
            logInfo("Loading invitation with token")
            
            let nominee: Nominee
            do {
                guard let loadedNominee = try await nomineeService.loadInvite(token: token) else {
                    logWarning("No nominee found with token | Token: \(token)")
                    await MainActor.run { [weak self] in
                        self?.presentErrorView(
                            message: "Invitation not found. It may still be syncing, or the invitation may have been cancelled. Please wait a moment and try again.",
                            onRetry: {
                                Task {
                                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                                    await self?.processInvitationAcceptance(token: token, vaultName: vaultName)
                                }
                            },
                            onCancel: {
                                self?.requestPresentationStyle(.compact)
                            }
                        )
                    }
                    return
                }
                nominee = loadedNominee
                logInfo("Nominee found | ID: \(nominee.id.uuidString) | Name: \(nominee.name) | Status: \(nominee.status.displayName)")
            } catch {
                logError("Failed to load invitation", error: error)
                throw error
            }
            
            // Check if already accepted
            if nominee.status == .accepted || nominee.status == .active {
                logInfo("Invitation already accepted | Status: \(nominee.status.displayName)")
                await MainActor.run { [weak self] in
                    self?.presentSuccessView(
                        message: "You already have access to this vault.",
                        vaultName: nominee.vault?.name ?? vaultName,
                        onDismiss: {
                            self?.requestPresentationStyle(.compact)
                        }
                    )
                }
                return
            }
            
            // Accept invitation using service
            let acceptedNominee: Nominee
            do {
                guard let accepted = try await nomineeService.acceptInvite(token: token) else {
                    logError("Failed to accept invitation - service returned nil")
                    await MainActor.run { [weak self] in
                        self?.presentErrorView(
                            message: "Failed to accept invitation. Please try again.",
                            onRetry: {
                                Task {
                                    await self?.processInvitationAcceptance(token: token, vaultName: vaultName)
                                }
                            },
                            onCancel: {
                                self?.requestPresentationStyle(.compact)
                            }
                        )
                    }
                    return
                }
                acceptedNominee = accepted
                logSuccess("Nominee invitation accepted | ID: \(acceptedNominee.id.uuidString) | Vault: \(acceptedNominee.vault?.name ?? "Unknown")")
            } catch {
                logError("Failed to accept invitation", error: error)
                throw error
            }
            
            // Mark for sync and wait for CloudKit sync
            await MainActor.run {
                iMessageSyncService.shared.markNomineeAccepted(acceptedNominee.id)
            }
            
            // Wait for CloudKit sync to ensure data is available in main app
            let syncStartTime = Date()
            do {
                try await iMessageSyncService.shared.waitForCloudKitSync(
                    entityID: acceptedNominee.id,
                    entityType: "Nominee",
                    context: context,
                    maxWait: 30.0
                )
                let syncDuration = Date().timeIntervalSince(syncStartTime)
                logSuccess("Accepted nominee synced to CloudKit | Duration: \(String(format: "%.2f", syncDuration))s")
                ProductionLogger.shared.logCloudKitSync(
                    entityType: "Nominee",
                    entityID: acceptedNominee.id,
                    status: "synced",
                    duration: syncDuration
                )
            } catch {
                let syncDuration = Date().timeIntervalSince(syncStartTime)
                logWarning("CloudKit sync timeout for accepted nominee | Duration: \(String(format: "%.2f", syncDuration))s")
                ProductionLogger.shared.logCloudKitSync(
                    entityType: "Nominee",
                    entityID: acceptedNominee.id,
                    status: "timeout",
                    duration: syncDuration
                )
                // Continue - sync will complete in background
            }
                    
                    // #region agent log
                    debugLog("Invitation accepted successfully", hypothesisId: "D", location: "MessagesViewController.swift:1160", data: [
                        "acceptedNomineeId": acceptedNominee.id.uuidString,
                        "vaultName": acceptedNominee.vault?.name ?? "Unknown"
                    ])
                    // #endregion
        } catch {
            logError("Failed to process invitation acceptance", error: error)
            
            await MainActor.run { [weak self] in
                self?.presentErrorView(
                    message: "Failed to accept invitation: \(error.localizedDescription)",
                    onRetry: {
                        Task {
                            await self?.processInvitationAcceptance(token: token, vaultName: vaultName)
                        }
                    },
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
        }
    }
    
    private func handleInvitationDecline(
        message: MSMessage,
        conversation: MSConversation
    ) {
        var vaultName = "Vault"
        if let url = message.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let vault = queryItems.first(where: { $0.name == "vault" })?.value {
            vaultName = vault
        }
        
        let updatedLayout = MSMessageTemplateLayout()
        updatedLayout.caption = "❌ Vault Invitation Declined"
        updatedLayout.subcaption = vaultName
        updatedLayout.trailingCaption = "Declined"
        
        var components = URLComponents(string: "khandoba://nominee/invite")
        if let originalURL = message.url,
           let originalComponents = URLComponents(url: originalURL, resolvingAgainstBaseURL: false),
           let originalQueryItems = originalComponents.queryItems {
            components?.queryItems = originalQueryItems.map { item in
                if item.name == "status" {
                    return URLQueryItem(name: "status", value: "declined")
                }
                return item
            }
            if !(components?.queryItems?.contains { $0.name == "status" } ?? false) {
                components?.queryItems?.append(URLQueryItem(name: "status", value: "declined"))
            }
        }
        
        let updatedMessage = MSMessage()
        updatedMessage.layout = updatedLayout
        if let updatedURL = components?.url {
            updatedMessage.url = updatedURL
        }
        updatedMessage.summaryText = "❌ Declined: \(vaultName)"
        
        // Note: MSMessage.session is read-only. Messages framework manages sessions automatically.
        // Inserting a new message with similar content will update the existing message bubble.
        
        conversation.insert(updatedMessage) { error in
            if let error = error {
                print("❌ Failed to update message: \(error.localizedDescription)")
            } else {
                print("✅ Invitation declined - message updated")
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    private func handleReceivedMessage(_ message: MSMessage, in conversation: MSConversation) {
        guard let url = message.url,
              url.scheme == "khandoba" else {
            return
        }
        
        // Handle nominee invitations
        if url.host == "nominee" || url.host == "invite" {
            print("📬 Received nominee invitation message: \(url.absoluteString)")
            // Parse and show invitation response view if needed
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let status = queryItems.first(where: { $0.name == "status" })?.value,
               status == "pending" {
                // Show invitation response view
                let token = queryItems.first(where: { $0.name == "token" })?.value
                let vaultName = queryItems.first(where: { $0.name == "vault" })?.value ?? "Unknown Vault"
                let sender = queryItems.first(where: { $0.name == "sender" })?.value ?? "Vault Owner"
                
                presentInvitationResponseView(
                    message: message,
                    conversation: conversation,
                    token: token,
                    vaultName: vaultName,
                    sender: sender,
                    status: status
                )
            }
        }
        
        // Handle transfer ownership requests
        if url.host == "transfer" || url.path.contains("transfer") {
            print("📬 Received transfer ownership message: \(url.absoluteString)")
            // Parse and show transfer response view if needed
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let status = queryItems.first(where: { $0.name == "status" })?.value,
               status == "pending" {
                // Show transfer response view
                let token = queryItems.first(where: { $0.name == "token" })?.value
                let vaultName = queryItems.first(where: { $0.name == "vault" })?.value ?? "Unknown Vault"
                let sender = queryItems.first(where: { $0.name == "sender" })?.value ?? "Vault Owner"
                
                presentTransferResponseView(
                    message: message,
                    conversation: conversation,
                    token: token,
                    vaultName: vaultName,
                    sender: sender,
                    status: status
                )
            }
        }
    }
    
    // MARK: - Transfer Ownership
    
    private func presentTransferVaultSelection(for conversation: MSConversation) {
        print("📱 presentTransferVaultSelection called")
        
        // Ensure extension stays expanded
        requestPresentationStyle(.expanded)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let vaultSelectionView = SimpleVaultSelectionView(
                onVaultSelected: { [weak self] vault in
                    guard let self = self else { return }
                    print("📱 Vault selected for transfer: \(vault.name)")
                    // Ensure extension stays expanded
                    self.requestPresentationStyle(.expanded)
                    // Show transfer recipient input
                    self.presentTransferRecipientInputView(for: vault, conversation: conversation)
                },
                onCancel: { [weak self] in
                    guard let self = self else { return }
                    print("📱 Transfer vault selection cancelled")
                    self.presentSimpleMenu(conversation: conversation)
                }
            )
            
            let hostingController = UIHostingController(
                rootView: vaultSelectionView.environment(\.unifiedTheme, UnifiedTheme())
            )
            
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
            
            print("✅ TransferVaultSelectionView presented successfully")
        }
    }
    
    private func presentTransferRecipientInputView(for vault: Vault, conversation: MSConversation) {
        print("📱 presentTransferRecipientInputView called for vault: \(vault.name)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let recipientInputView = TransferRecipientInputView(
                vaultName: vault.name,
                onSend: { [weak self] (name: String, phone: String?, email: String?, reason: String?) in
                    guard let self = self else { return }
                    print("📱 Sending transfer request to: \(name)")
                    // Show loading, then send transfer
                    self.presentLoadingView(message: "Sending transfer request...")
                    
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        do {
                            try await self.sendTransferOwnershipRequest(
                                vault: vault,
                                recipientName: name,
                                recipientPhone: phone,
                                recipientEmail: email,
                                reason: reason,
                                in: conversation
                            )
                            // Show success before collapsing
                            self.presentSuccessView(
                                message: "Transfer request sent to \(name)!",
                                vaultName: vault.name,
                                onDismiss: {
                                    self.requestPresentationStyle(.compact)
                                }
                            )
                        } catch {
                            // Show error
                            self.presentErrorView(
                                message: "Failed to send transfer request: \(error.localizedDescription)",
                                onRetry: {
                                    self.presentTransferRecipientInputView(for: vault, conversation: conversation)
                                },
                                onCancel: {
                                    self.presentTransferVaultSelection(for: conversation)
                                }
                            )
                        }
                    }
                },
                onCancel: { [weak self] in
                    guard let self = self else { return }
                    print("📱 Transfer recipient input cancelled")
                    self.presentTransferVaultSelection(for: conversation)
                }
            )
            
            let hostingController = UIHostingController(
                rootView: recipientInputView.environment(\.unifiedTheme, UnifiedTheme())
            )
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
            
            print("✅ TransferRecipientInputView presented successfully")
        }
    }
    
    private func presentTransferOwnershipView(for conversation: MSConversation, vault: Vault? = nil) {
        removeAllChildViewControllers()

        let transferView = TransferOwnershipMessageView(
            conversation: conversation,
            preselectedVault: vault,
            onSendTransfer: { [weak self] transferToken, vaultName, recipientName in
                self?.sendTransferOwnershipRequest(
                    transferToken: transferToken,
                    vaultName: vaultName,
                    recipientName: recipientName,
                    in: conversation
                )
            },
            onCancel: { [weak self] in
                self?.presentMainInterface(for: conversation)
            }
        )
        
        let hostingController = UIHostingController(
            rootView: transferView.environment(\.unifiedTheme, UnifiedTheme())
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    // NEW OVERLOAD: wrapper for token-based send from the transfer compose view
    private func sendTransferOwnershipRequest(
        transferToken: String,
        vaultName: String,
        recipientName: String,
        in conversation: MSConversation
    ) {
        print("📤 sendTransferOwnershipRequest (token-based) called")
        print("   Token: \(transferToken)")
        print("   Vault: \(vaultName)")
        print("   Recipient: \(recipientName)")
        
        Task {
            var senderName = "You"
            var persistedTransferID: UUID?
            
            do {
                // Shared container
                let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
                let context = container.mainContext
                
                // Load current user for senderName
                let userDescriptor = FetchDescriptor<User>()
                let currentUser = try context.fetch(userDescriptor).first
                if let name = currentUser?.fullName, !name.isEmpty {
                    senderName = name
                }
                
                // Try to find the vault by name (exact match)
                let vaultDescriptor = FetchDescriptor<Vault>(
                    predicate: #Predicate<Vault> { $0.name == vaultName }
                )
                let matchedVault = try context.fetch(vaultDescriptor).first
                
                // Create and persist a transfer request with provided token
                let transferRequest = VaultTransferRequest(
                    reason: nil,
                    newOwnerID: nil,
                    newOwnerName: recipientName,
                    newOwnerPhone: nil,
                    newOwnerEmail: nil,
                    transferToken: transferToken
                )
                transferRequest.vault = matchedVault
                transferRequest.requestedByUserID = currentUser?.id
                context.insert(transferRequest)
                try context.save()
                
                persistedTransferID = transferRequest.id
                print("✅ Persisted transfer request with token: \(transferToken)")
                if let v = matchedVault {
                    print("   Linked to vault: \(v.name) (\(v.id))")
                } else {
                    print("   ⚠️ Vault named '\(vaultName)' not found in local store; request saved without vault link. It can be reconciled later.")
                }
                
                // Mark for sync so main app can reconcile if needed
                if let id = persistedTransferID {
                    iMessageSyncService.shared.markTransferCreated(id)
                }
            } catch {
                print("⚠️ Could not persist transfer request in extension: \(error.localizedDescription)")
                // Continue to send iMessage even if persistence failed
            }
            
            // Send the interactive message using existing helper on main actor
            await MainActor.run {
                self.sendTransferOwnershipMessage(
                    transferToken: transferToken,
                    vaultName: vaultName,
                    senderName: senderName,
                    in: conversation
                )
            }
        }
    }
    
    private func sendTransferOwnershipRequest(
        vault: Vault,
        recipientName: String,
        recipientPhone: String? = nil,
        recipientEmail: String? = nil,
        reason: String? = nil,
        in conversation: MSConversation
    ) async throws {
        print("📤 sendTransferOwnershipRequest called")
        print("   Vault: \(vault.name)")
        print("   Recipient: \(recipientName)")
        
        // Always use shared container/context; re-fetch vault in that context
        let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
        let context = container.mainContext
        
        // Re-fetch vault in new context
        let allVaults = try context.fetch(FetchDescriptor<Vault>())
        guard let fetchedVault = allVaults.first(where: { $0.id == vault.id }) else {
            throw NSError(domain: "MessageApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Vault not found. It may still be syncing."])
        }
        
        try await createAndSendTransferRequest(
            for: fetchedVault,
            context: context,
            recipientName: recipientName,
            recipientPhone: recipientPhone,
            recipientEmail: recipientEmail,
            reason: reason,
            in: conversation
        )
    }
    
    private func createAndSendTransferRequest(
        for vault: Vault,
        context: ModelContext,
        recipientName: String,
        recipientPhone: String? = nil,
        recipientEmail: String? = nil,
        reason: String? = nil,
        in conversation: MSConversation
    ) async throws {
        // Validate recipient information
        do {
            try ValidationHelpers.validateRecipient(
                name: recipientName,
                phone: recipientPhone,
                email: recipientEmail
            )
        } catch {
            print("❌ Validation error: \(error.localizedDescription)")
            throw error
        }
        
        // Verify current user is the vault owner
        let userDescriptor = FetchDescriptor<User>()
        let users = try context.fetch(userDescriptor)
        let currentUser = users.first
        guard let currentUserID = currentUser?.id else {
            throw NSError(domain: "MessageApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found. Please sign in to the main app first."])
        }
        
        // Verify ownership
        guard let vaultOwner = vault.owner, vaultOwner.id == currentUserID else {
            throw NSError(domain: "MessageApp", code: 2, userInfo: [NSLocalizedDescriptionKey: "You can only transfer vaults you own."])
        }
        
        let senderName = currentUser?.fullName ?? "You"
        
        // Create transfer request
        let transferToken = UUID().uuidString
        let transferRequest = VaultTransferRequest(
            reason: reason,
            newOwnerID: nil,
            newOwnerName: recipientName,
            newOwnerPhone: recipientPhone,
            newOwnerEmail: recipientEmail,
            transferToken: transferToken
        )
        transferRequest.vault = vault
        transferRequest.requestedByUserID = currentUserID
        
        context.insert(transferRequest)
        try context.save()
        
        print("✅ Transfer request created with token: \(transferToken)")
        print("   Vault: \(vault.name)")
        print("   New owner: \(recipientName)")
        
        // Mark for sync and wait for CloudKit sync
        await MainActor.run {
            iMessageSyncService.shared.markTransferCreated(transferRequest.id)
        }
        
        // Wait for CloudKit sync to ensure data is available in main app
        let syncStartTime = Date()
        do {
            try await iMessageSyncService.shared.waitForCloudKitSync(
                entityID: transferRequest.id,
                entityType: "VaultTransferRequest",
                context: context,
                maxWait: 30.0,
                onProgress: { status in
                    logDebug("Transfer sync progress | Status: \(status.displayName)")
                }
            )
            let syncDuration = Date().timeIntervalSince(syncStartTime)
            logSuccess("Transfer request synced to CloudKit | Duration: \(String(format: "%.2f", syncDuration))s")
            ProductionLogger.shared.logCloudKitSync(
                entityType: "VaultTransferRequest",
                entityID: transferRequest.id,
                status: "synced",
                duration: syncDuration
            )
        } catch {
            let syncDuration = Date().timeIntervalSince(syncStartTime)
            logWarning("CloudKit sync timeout for transfer request | Duration: \(String(format: "%.2f", syncDuration))s")
            ProductionLogger.shared.logCloudKitSync(
                entityType: "VaultTransferRequest",
                entityID: transferRequest.id,
                status: "timeout",
                duration: syncDuration
            )
        }
        
        // Show success confirmation before sending message
        await MainActor.run {
            self.presentSuccessView(
                message: "Transfer request created successfully!",
                vaultName: vault.name,
                onDismiss: {
                    // Send interactive message after user dismisses success view
                    self.sendTransferOwnershipMessage(
                        transferToken: transferToken,
                        vaultName: vault.name,
                        senderName: senderName,
                        in: conversation
                    )
                    
                    // Collapse extension after sending
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.requestPresentationStyle(.compact)
                    }
                }
            )
        }
    }
    
    private func sendTransferOwnershipMessage(
        transferToken: String,
        vaultName: String,
        senderName: String,
        in conversation: MSConversation
    ) {
        logInfo("Sending transfer ownership message | Token: \(transferToken) | Vault: \(vaultName) | Sender: \(senderName)")
        ProductionLogger.shared.logTransferRequest(vaultName: vaultName, recipientName: senderName, token: transferToken)
        
        // Check if conversation has recipients
        if conversation.remoteParticipantIdentifiers.isEmpty {
            logError("Cannot send transfer request - no remote participants in conversation")
            DispatchQueue.main.async { [weak self] in
                self?.presentErrorView(
                    message: "Please select a contact in Messages before sending a transfer request.",
                    onRetry: {},
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
            return
        }
        
        // Create transfer URL
        var components = URLComponents(string: "khandoba://transfer/ownership")
        components?.queryItems = [
            URLQueryItem(name: "token", value: transferToken),
            URLQueryItem(name: "vault", value: vaultName),
            URLQueryItem(name: "status", value: "pending"),
            URLQueryItem(name: "sender", value: senderName)
        ]
        
        guard let url = components?.url else {
            print("❌ Failed to create transfer URL")
            DispatchQueue.main.async { [weak self] in
                self?.presentErrorView(
                    message: "Failed to create transfer URL. Please try again.",
                    onRetry: {
                        self?.sendTransferOwnershipMessage(
                            transferToken: transferToken,
                            vaultName: vaultName,
                            senderName: senderName,
                            in: conversation
                        )
                    },
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
            return
        }
        
        logDebug("Transfer URL created | URL: \(url.absoluteString)")
        
        // Create interactive message layout
        let layout = MSMessageTemplateLayout()
        layout.caption = "🔄 Transfer Ownership"
        layout.subcaption = vaultName
        layout.trailingCaption = "Tap to Accept"
        layout.imageTitle = "Khandoba Secure Docs"
        
        // Create message
        let message = MSMessage()
        message.layout = layout
        message.url = url
        message.summaryText = "Transfer Ownership: \(vaultName) - Tap to accept"
        
        conversation.insert(message) { [weak self] error in
            if let error = error {
                logError("Failed to send transfer request message", error: error)
                DispatchQueue.main.async {
                    self?.presentErrorView(
                        message: "Failed to send transfer request: \(error.localizedDescription)",
                        onRetry: {
                            self?.sendTransferOwnershipMessage(
                                transferToken: transferToken,
                                vaultName: vaultName,
                                senderName: senderName,
                                in: conversation
                            )
                        },
                        onCancel: {
                            self?.requestPresentationStyle(.compact)
                        }
                    )
                }
            } else {
                logSuccess("Transfer ownership message sent successfully")
                
                // Haptic feedback for success
                DispatchQueue.main.async {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }
    
    private func presentTransferResponseView(
        message: MSMessage,
        conversation: MSConversation,
        token: String?,
        vaultName: String,
        sender: String,
        status: String
    ) {
        removeAllChildViewControllers()
        
        let responseView = TransferResponseMessageView(
            message: message,
            conversation: conversation,
            token: token,
            vaultName: vaultName,
            sender: sender,
            status: status,
            onAccept: { [weak self] in
                self?.handleTransferAcceptance(
                    message: message,
                    conversation: conversation,
                    token: token,
                    vaultName: vaultName
                )
            },
            onDecline: { [weak self] in
                guard let self = self else { return }
                self.handleTransferDecline(
                    message: message,
                    conversation: conversation
                )
            }
        )
        
        let hostingController = UIHostingController(
            rootView: AnyView(responseView.environment(\.unifiedTheme, UnifiedTheme()))
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    private func handleTransferAcceptance(
        message: MSMessage,
        conversation: MSConversation,
        token: String?,
        vaultName: String
    ) {
        print("📥 handleTransferAcceptance called")
        print("   Token: \(token ?? "nil")")
        print("   Vault: \(vaultName)")
        
        // Show loading state
        presentLoadingView(message: "Processing transfer...")
        
        // Process acceptance in background
        Task { [weak self] in
            guard let self = self else { return }
            await processTransferAcceptance(token: token, vaultName: vaultName)
            
            // Update message to accepted state on main thread
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                let updatedLayout = MSMessageTemplateLayout()
                updatedLayout.caption = "✅ Ownership Transfer Accepted"
                updatedLayout.subcaption = vaultName
                updatedLayout.trailingCaption = "Accepted"
                
                var components = URLComponents(string: "khandoba://transfer/ownership")
                components?.queryItems = [
                    URLQueryItem(name: "token", value: token ?? ""),
                    URLQueryItem(name: "vault", value: vaultName),
                    URLQueryItem(name: "status", value: "accepted")
                ]
                
                guard let updatedURL = components?.url else {
                    self.presentErrorView(
                        message: "Failed to create update URL",
                        onRetry: {
                            self.handleTransferAcceptance(message: message, conversation: conversation, token: token, vaultName: vaultName)
                        },
                        onCancel: {
                            self.requestPresentationStyle(.compact)
                        }
                    )
                    return
                }
                
                let updatedMessage = MSMessage()
                updatedMessage.layout = updatedLayout
                updatedMessage.url = updatedURL
                updatedMessage.summaryText = "✅ Accepted: \(vaultName)"
                
                conversation.insert(updatedMessage) { [weak self] error in
                        DispatchQueue.main.async {
                            if let error = error {
                                print("❌ Failed to update message: \(error.localizedDescription)")
                                self?.presentErrorView(
                                    message: "Failed to update message: \(error.localizedDescription)",
                                    onRetry: { [weak self] in
                                        guard let self = self else { return }
                                        self.handleTransferAcceptance(message: message, conversation: conversation, token: token, vaultName: vaultName)
                                    },
                                    onCancel: {
                                        self?.requestPresentationStyle(.compact)
                                    }
                                )
                            } else {
                                print("✅ Transfer accepted - message updated")
                                
                                // Haptic feedback for success
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                
                                // Show success
                                self?.presentSuccessView(
                                    message: "Ownership transfer accepted! The vault is now yours.",
                                    vaultName: vaultName,
                                    onDismiss: {
                                        // Open main app with deep link
                                        if let url = URL(string: "khandoba://transfer/accept?token=\(token ?? "")&vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)") {
                                            self?.extensionContext?.open(url) { success in
                                                if success {
                                                    print("✅ Opened main app to process transfer")
                                                } else {
                                                    UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)?.set(token, forKey: "pending_transfer_token")
                                                    print("📝 Stored transfer token for later processing")
                                                }
                                            }
                                        }
                                        self?.requestPresentationStyle(.compact)
                                    }
                                )
                            }
                        }
                    }
                }
            }
    }
    
    private func handleTransferDecline(
        message: MSMessage,
        conversation: MSConversation
    ) {
        var vaultName = "Vault"
        if let url = message.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let vault = queryItems.first(where: { $0.name == "vault" })?.value {
            vaultName = vault
        }
        
        let updatedLayout = MSMessageTemplateLayout()
        updatedLayout.caption = "❌ Ownership Transfer Declined"
        updatedLayout.subcaption = vaultName
        updatedLayout.trailingCaption = "Declined"
        
        var components = URLComponents(string: "khandoba://transfer/ownership")
        if let originalURL = message.url,
           let originalComponents = URLComponents(url: originalURL, resolvingAgainstBaseURL: false),
           let originalQueryItems = originalComponents.queryItems {
            components?.queryItems = originalQueryItems.map { item in
                if item.name == "status" {
                    return URLQueryItem(name: "status", value: "declined")
                }
                return item
            }
            if !(components?.queryItems?.contains { $0.name == "status" } ?? false) {
                components?.queryItems?.append(URLQueryItem(name: "status", value: "declined"))
            }
        }
        
        let updatedMessage = MSMessage()
        updatedMessage.layout = updatedLayout
        if let updatedURL = components?.url {
            updatedMessage.url = updatedURL
        }
        updatedMessage.summaryText = "❌ Declined: \(vaultName)"
        
        conversation.insert(updatedMessage) { [weak self] error in
            if let error = error {
                print("❌ Failed to update message: \(error.localizedDescription)")
            } else {
                print("✅ Transfer declined - message updated")
                self?.requestPresentationStyle(.compact)
            }
        }
    }
    
    private func processTransferAcceptance(token: String?, vaultName: String) async {
        guard let token = token, !token.isEmpty else {
            print("⚠️ No token provided for transfer acceptance")
            await MainActor.run { [weak self] in
                self?.presentErrorView(
                    message: "Invalid transfer token. Please check the transfer request and try again.",
                    onRetry: {},
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
            return
        }
        
        // Validate token format
        guard UUID(uuidString: token) != nil else {
            print("⚠️ Invalid token format: \(token)")
            await MainActor.run { [weak self] in
                self?.presentErrorView(
                    message: "Invalid transfer format. Please use a valid transfer link.",
                    onRetry: {},
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
            return
        }
        
        print("📥 Processing transfer acceptance for token: \(token)")
        
        // Load SwiftData context with App Group
        do {
            let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
            
            // Access context on MainActor and do all operations
            let transferID: UUID? = try await MainActor.run {
                let context = container.mainContext
                
                // Get current user (the one accepting the transfer)
                let userDescriptor = FetchDescriptor<User>()
                let users = try context.fetch(userDescriptor)
                guard let currentUser = users.first else {
                    throw NSError(domain: "MessageApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found. Please sign in to the main app first."])
                }
                
                let transferDescriptor = FetchDescriptor<VaultTransferRequest>(
                    predicate: #Predicate<VaultTransferRequest> { $0.transferToken == token }
                )
                let transfers = try context.fetch(transferDescriptor)
                
                if let transfer = transfers.first, let vault = transfer.vault {
                    print("✅ Found transfer request: \(transfer.id)")
                    print("   Vault: \(vault.name)")
                    print("   New owner: \(transfer.newOwnerName ?? "Unknown")")
                    print("   Current user: \(currentUser.fullName)")
                    
                    // Check if transfer is already completed
                    if transfer.status == "completed" || transfer.status == "accepted" {
                        print("ℹ️ Transfer already completed")
                        // Verify current user is the owner
                        if let owner = vault.owner, owner.id == currentUser.id {
                            print("   ✅ Current user is already the owner")
                            return transfer.id
                        }
                    }
                    
                    // Verify current user matches the intended recipient
                    // Match by name, email, or phone if provided
                    let matchesRecipient = transfer.newOwnerName?.lowercased() == currentUser.fullName.lowercased() ||
                        (transfer.newOwnerEmail != nil && transfer.newOwnerEmail == currentUser.email) ||
                        (transfer.newOwnerPhone != nil && transfer.newOwnerPhone == currentUser.email) // Phone matching would need additional logic
                    
                    if !matchesRecipient && transfer.newOwnerID != currentUser.id {
                        print("⚠️ Current user may not be the intended recipient")
                        // Still proceed - the transfer request was sent to this conversation
                    }
                    
                    // Update transfer status
                    transfer.status = "accepted"
                    transfer.approvedAt = Date()
                    transfer.approverID = currentUser.id
                    
                    // Transfer vault ownership to current user
                    vault.owner = currentUser
                    print("   ✅ Vault owner updated to: \(currentUser.fullName)")
                    
                    // Mark transfer as completed
                    transfer.status = "completed"
                    
                    try context.save()
                    print("✅ Transfer ownership accepted and saved")
                    print("   CloudKit sync: Changes will sync to all devices")
                    
                    // Mark for sync
                    iMessageSyncService.shared.markTransferAccepted(transfer.id)
                    
                    return transfer.id
                } else {
                    print("⚠️ No transfer request found with token: \(token)")
                    print("   This may mean:")
                    print("   - Transfer request hasn't synced to CloudKit yet (wait a few seconds)")
                    print("   - Token is invalid or request was cancelled")
                    return nil
                }
            }
            
            // Wait for CloudKit sync outside MainActor.run if transfer was found
            if let transferID = transferID {
                print("🔄 Waiting for CloudKit sync of transfer acceptance...")
                do {
                    try await iMessageSyncService.shared.waitForCloudKitSync(
                        entityID: transferID,
                        entityType: "VaultTransferRequest",
                        context: container.mainContext,
                        maxWait: 30.0
                    )
                    print("✅ Transfer acceptance synced successfully")
                } catch {
                    print("⚠️ Sync warning: \(error.localizedDescription)")
                    // Continue - sync will complete in background
                }
            } else {
                // Transfer not found - show error
                await MainActor.run { [weak self] in
                    self?.presentErrorView(
                        message: "Transfer request not found. It may still be syncing, or the request may have been cancelled. Please wait a moment and try again.",
                        onRetry: {
                            Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                await self?.processTransferAcceptance(token: token, vaultName: vaultName)
                            }
                        },
                        onCancel: {
                            self?.requestPresentationStyle(.compact)
                        }
                    )
                }
            }
        } catch {
            print("❌ Failed to process transfer acceptance: \(error.localizedDescription)")
            print("   Error details: \(error)")
            
            await MainActor.run { [weak self] in
                self?.presentErrorView(
                    message: "Failed to accept transfer: \(error.localizedDescription)",
                    onRetry: {
                        Task {
                            await self?.processTransferAcceptance(token: token, vaultName: vaultName)
                        }
                    },
                    onCancel: {
                        self?.requestPresentationStyle(.compact)
                    }
                )
            }
        }
    }
    
    // MARK: - Loading and Success Views
    
    private func presentLoadingView(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let loadingView = VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(message)
                    .font(UnifiedTheme().typography.body)
                    .foregroundColor(UnifiedTheme().colors(for: .dark).textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(UnifiedTheme().colors(for: .dark).background)
            
            let hostingController = UIHostingController(rootView: loadingView)
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
        }
    }
    
    private func presentSuccessView(message: String, vaultName: String?, onDismiss: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let successView = SuccessMessageView(
                message: message,
                vaultName: vaultName,
                onDismiss: onDismiss
            )
            
            let hostingController = UIHostingController(
                rootView: successView.environment(\.unifiedTheme, UnifiedTheme())
            )
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
        }
    }
    
    // MARK: - Emergency Protocol
    
    private func presentEmergencyVaultSelection(for conversation: MSConversation) {
        print("📱 presentEmergencyVaultSelection called")
        
        // Ensure extension stays expanded
        self.requestPresentationStyle(.expanded)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let vaultSelectionView = SimpleVaultSelectionView(
                onVaultSelected: { [weak self] vault in
                    guard let self = self else { return }
                    print("📱 Vault selected for emergency: \(vault.name)")
                    // Ensure extension stays expanded
                    self.requestPresentationStyle(.expanded)
                    // Show emergency request form
                    self.presentEmergencyRequestView(for: vault, conversation: conversation)
                },
                onCancel: { [weak self] in
                    guard let self = self else { return }
                    print("📱 Emergency vault selection cancelled")
                    self.presentSimpleMenu(conversation: conversation)
                }
            )
            
            let hostingController = UIHostingController(
                rootView: vaultSelectionView.environment(\.unifiedTheme, UnifiedTheme())
            )
            
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
            
            print("✅ EmergencyVaultSelectionView presented successfully")
        }
    }
    
    private func presentEmergencyRequestView(for vault: Vault, conversation: MSConversation) {
        print("📱 presentEmergencyRequestView called for vault: \(vault.name)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.removeAllChildViewControllers()
            self.view.subviews.forEach { $0.removeFromSuperview() }
            
            let emergencyView = EmergencyRequestMessageView(
                vaultName: vault.name,
                onSend: { [weak self] reason, urgency in
                    guard let self = self else { return }
                    print("📱 Sending emergency request")
                    // Show loading, then send emergency request
                    self.presentLoadingView(message: "Sending emergency request...")
                    
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        do {
                            try await self.sendEmergencyRequest(
                                vault: vault,
                                reason: reason,
                                urgency: urgency,
                                in: conversation
                            )
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            // Show success before collapsing
                            self.presentSuccessView(
                                message: "Emergency request sent! Waiting for approval.",
                                vaultName: vault.name,
                                onDismiss: {
                                    self.requestPresentationStyle(.compact)
                                }
                            )
                        } catch {
                            // Show error
                            self.presentErrorView(
                                message: "Failed to send emergency request: \(error.localizedDescription)",
                                onRetry: {
                                    self.presentEmergencyRequestView(for: vault, conversation: conversation)
                                },
                                onCancel: {
                                    self.presentEmergencyVaultSelection(for: conversation)
                                }
                            )
                        }
                    }
                },
                onCancel: { [weak self] in
                    guard let self = self else { return }
                    print("📱 Emergency request cancelled")
                    self.presentEmergencyVaultSelection(for: conversation)
                }
            )
            
            let hostingController = UIHostingController(
                rootView: emergencyView.environment(\.unifiedTheme, UnifiedTheme())
            )
            hostingController.view.backgroundColor = .systemBackground
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
            
            print("✅ EmergencyRequestMessageView presented successfully")
        }
    }
    
    private func sendEmergencyRequest(
        vault: Vault,
        reason: String,
        urgency: String,
        in conversation: MSConversation
    ) async throws {
        logWarning("Sending emergency request | Vault: \(vault.name) | Urgency: \(urgency)")
        ProductionLogger.shared.logEmergencyRequest(
            vaultName: vault.name,
            urgency: urgency,
            reason: reason
        )
        
        // Validate reason (must not be empty)
        let trimmedReason = reason.trimmingCharacters(in: .whitespaces)
        guard !trimmedReason.isEmpty else {
            logError("Emergency request validation failed - empty reason")
            throw NSError(domain: "MessageApp", code: 3001, userInfo: [
                NSLocalizedDescriptionKey: "Please provide a reason for emergency access."
            ])
        }
        
        // Validate urgency level
        let validUrgencies = ["low", "medium", "high", "critical"]
        guard validUrgencies.contains(urgency.lowercased()) else {
            logError("Emergency request validation failed - invalid urgency | Urgency: \(urgency)")
            throw NSError(domain: "MessageApp", code: 3002, userInfo: [
                NSLocalizedDescriptionKey: "Invalid urgency level. Please select a valid urgency."
            ])
        }
        
        // Always use shared container/context; re-fetch vault
        let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
        
        // Re-fetch vault and create emergency request on MainActor
        var emergencyID: UUID?
        var emergencyContext: ModelContext?
        
        do {
            try await MainActor.run {
                let context = container.mainContext
                let allVaults = try context.fetch(FetchDescriptor<Vault>())
                guard let fetchedVault = allVaults.first(where: { $0.id == vault.id }) else {
                    throw NSError(domain: "MessageApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Vault not found. It may still be syncing."])
                }
                
                // Get current user
                let userDescriptor = FetchDescriptor<User>()
                let users = try context.fetch(userDescriptor)
                let currentUser = users.first
                guard let currentUserID = currentUser?.id else {
                    throw NSError(domain: "MessageApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found. Please sign in to the main app first."])
                }
                
                // Create emergency access request
                let emergencyRequest = EmergencyAccessRequest(
                    reason: trimmedReason,
                    urgency: urgency.lowercased(),
                    status: "pending"
                )
                emergencyRequest.vault = fetchedVault
                emergencyRequest.requesterID = currentUserID
                
                context.insert(emergencyRequest)
                try context.save()
                
                logSuccess("Emergency request created | ID: \(emergencyRequest.id.uuidString) | Vault: \(fetchedVault.name) | Urgency: \(urgency)")
                
                // Mark for sync
                iMessageSyncService.shared.markEmergencyCreated(emergencyRequest.id)
                
                // Store IDs for sync wait outside MainActor.run
                emergencyID = emergencyRequest.id
                let vaultID = fetchedVault.id
                emergencyContext = context
                
                // Send notification to main app (via UserDefaults)
                let appGroupIdentifier = MessageAppConfig.appGroupIdentifier
                if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
                    sharedDefaults.set(emergencyID!.uuidString, forKey: "pending_emergency_request_id")
                    sharedDefaults.set(vaultID.uuidString, forKey: "pending_emergency_vault_id")
                }
                
                logInfo("Emergency request saved and marked for sync | Main app will be notified")
            }
        } catch {
            logError("Failed to create emergency request", error: error)
            throw error
        }
        
        // Wait for CloudKit sync outside MainActor.run
        if let emergencyID = emergencyID, let emergencyContext = emergencyContext {
            let syncStartTime = Date()
            do {
                try await iMessageSyncService.shared.waitForCloudKitSync(
                    entityID: emergencyID,
                    entityType: "EmergencyAccessRequest",
                    context: emergencyContext,
                    maxWait: 30.0
                )
                let syncDuration = Date().timeIntervalSince(syncStartTime)
                logSuccess("Emergency request synced to CloudKit | Duration: \(String(format: "%.2f", syncDuration))s")
                ProductionLogger.shared.logCloudKitSync(
                    entityType: "EmergencyAccessRequest",
                    entityID: emergencyID,
                    status: "synced",
                    duration: syncDuration
                )
            } catch {
                let syncDuration = Date().timeIntervalSince(syncStartTime)
                logWarning("CloudKit sync timeout for emergency request | Duration: \(String(format: "%.2f", syncDuration))s")
                ProductionLogger.shared.logCloudKitSync(
                    entityType: "EmergencyAccessRequest",
                    entityID: emergencyID,
                    status: "timeout",
                    duration: syncDuration
                )
                // Continue - sync will complete in background
            }
        }
    }
}

