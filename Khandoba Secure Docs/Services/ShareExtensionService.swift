//
//  ShareExtensionService.swift
//  Khandoba Secure Docs
//
//  Service to handle Share Extension uploads and sync vault info
//

import Foundation
import SwiftData
import Combine

@MainActor
final class ShareExtensionService: ObservableObject {
    private let appGroupIdentifier = "group.com.khandoba.securedocs"
    private var modelContext: ModelContext?
    private var currentUserID: UUID?
    
    init() {
        // Listen for share extension notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShareExtensionNotification),
            name: NSNotification.Name("ShareExtensionDidSaveItems"),
            object: nil
        )
    }
    
    func configure(modelContext: ModelContext, userID: UUID?) {
        self.modelContext = modelContext
        self.currentUserID = userID
    }
    
    /// Sync vault information to shared UserDefaults for the extension
    func syncVaultsToExtension(vaults: [Vault]) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print(" ShareExtensionService: App Group not available")
            return
        }
        
        let vaultInfos = vaults.map { vault in
            VaultInfo(id: vault.id, name: vault.name)
        }
        
        if let vaultData = try? JSONEncoder().encode(vaultInfos) {
            sharedDefaults.set(vaultData, forKey: "available_vaults")
            sharedDefaults.synchronize()
            print(" ShareExtensionService: Synced \(vaultInfos.count) vault(s) to extension")
        }
    }
    
    /// Process pending uploads from share extension
    @objc private func handleShareExtensionNotification() {
        Task {
            await processPendingUploads()
        }
    }
    
    /// Process pending uploads from share extension
    func processPendingUploads() async {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let uploadsData = sharedDefaults.data(forKey: "pending_share_uploads"),
              let uploads = try? JSONSerialization.jsonObject(with: uploadsData) as? [[String: Any]] else {
            return
        }
        
        guard let modelContext = modelContext,
              let userID = currentUserID else {
            print(" ShareExtensionService: ModelContext or UserID not available")
            return
        }
        
        let documentService = DocumentService()
        documentService.configure(modelContext: modelContext, userID: userID)
        
        let vaultService = VaultService()
        vaultService.configure(modelContext: modelContext, userID: userID)
        
        // Track which vaults we've opened to avoid duplicate sessions
        var openedVaults: Set<UUID> = []
        
        for uploadInfo in uploads {
            guard let vaultIDString = uploadInfo["vaultID"] as? String,
                  let vaultID = UUID(uuidString: vaultIDString),
                  let dataString = uploadInfo["data"] as? String,
                  let data = Data(base64Encoded: dataString),
                  let name = uploadInfo["name"] as? String,
                  let mimeType = uploadInfo["mimeType"] as? String else {
                continue
            }
            
            // Find vault
            let vaultDescriptor = FetchDescriptor<Vault>(
                predicate: #Predicate { $0.id == vaultID }
            )
            
            guard let vault = try? modelContext.fetch(vaultDescriptor).first else {
                print(" ShareExtensionService: Vault not found: \(vaultIDString)")
                continue
            }
            
            // Open vault session if not already open
            // For dual-key vaults, this will trigger full ML approval process
            var vaultAccessGranted = false
            
            if !openedVaults.contains(vaultID) {
                do {
                    // Check if vault is already open
                    if vaultService.hasActiveSession(for: vaultID) {
                        print(" ShareExtensionService: Vault \(vault.name) already has active session")
                        vaultAccessGranted = true
                    } else {
                        print(" ShareExtensionService: Opening vault session for \(vault.name)")
                        
                        // For dual-key vaults, this will:
                        // 1. Create DualKeyRequest
                        // 2. Process with ML + Formal Logic
                        // 3. Auto-approve or auto-deny based on security analysis
                        // 4. Throw VaultError.accessDenied if denied
                        try await vaultService.openVault(vault)
                        
                        print(" ShareExtensionService: Vault session opened successfully")
                        vaultAccessGranted = true
                    }
                    openedVaults.insert(vaultID)
                } catch VaultError.accessDenied {
                    print(" ShareExtensionService: ⚠️ ACCESS DENIED for vault \(vault.name)")
                    print("   ML security analysis denied access - document will NOT be saved")
                    print("   This is expected behavior for dual-key vaults with suspicious activity")
                    // Do NOT save document - access was denied
                    continue
                } catch VaultError.awaitingApproval {
                    print(" ShareExtensionService: ⚠️ AWAITING APPROVAL for vault \(vault.name)")
                    print("   Dual-key request pending - document will NOT be saved until approved")
                    // Do NOT save document - approval is pending
                    continue
                } catch {
                    print(" ShareExtensionService: ❌ Failed to open vault \(vault.name): \(error.localizedDescription)")
                    // Unknown error - do not save document for security
                    continue
                }
            } else {
                // Vault already opened in this batch
                vaultAccessGranted = true
            }
            
            // Only upload document if vault access was granted
            guard vaultAccessGranted else {
                print(" ShareExtensionService: Skipping upload - vault access not granted")
                continue
            }
            
            // Upload document
            do {
                _ = try await documentService.uploadDocument(
                    data: data,
                    name: name,
                    mimeType: mimeType,
                    to: vault,
                    uploadMethod: .shareExtension
                )
                print(" ShareExtensionService: ✅ Uploaded \(name) to vault \(vault.name)")
            } catch {
                print(" ShareExtensionService: ❌ Failed to upload \(name): \(error.localizedDescription)")
            }
        }
        
        // Clear pending uploads
        sharedDefaults.removeObject(forKey: "pending_share_uploads")
        sharedDefaults.synchronize()
        
        print(" ShareExtensionService: Processed \(uploads.count) upload(s) from share extension")
    }
}

// MARK: - VaultInfo (for encoding/decoding)

struct VaultInfo: Codable {
    let id: UUID
    let name: String
}

