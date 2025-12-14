//
//  CloudKitSharingController.swift
//  Khandoba Secure Docs
//
//  SwiftUI wrapper for UICloudSharingController
//  Enables native iOS sharing for CloudKit shares
//

import SwiftUI
import UIKit
import CloudKit
import SwiftData

struct CloudKitSharingView: UIViewControllerRepresentable {
    let vault: Vault
    let share: CKShare?
    let container: CKContainer
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    init(vault: Vault, share: CKShare? = nil, container: CKContainer, isPresented: Binding<Bool>) {
        self.vault = vault
        self.share = share
        self.container = container
        self._isPresented = isPresented
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        // If we have a share, use it directly
        if let share = share {
            let controller = UICloudSharingController(share: share, container: container)
            controller.delegate = context.coordinator
            controller.availablePermissions = [.allowReadWrite, .allowPrivate]
            
            // Configure for iPad popover if needed
            if let popover = controller.popoverPresentationController {
                popover.permittedArrowDirections = .any
            }
            
            return controller
        }
        
        // Otherwise, use preparation handler to create share
        let controller = UICloudSharingController { controller, completionHandler in
            Task {
                do {
                    // Get CloudKit record using the sharing service
                    let sharingService = CloudKitSharingService()
                    sharingService.configure(modelContext: modelContext)
                    
                    // Try to get or create share
                    if let share = try await sharingService.getOrCreateShare(for: vault) {
                        print("   ✅ Using existing or newly created share")
                        completionHandler(share, container, nil)
                    } else {
                        // Use SwiftData's PersistentIdentifier to get the CloudKit record
                        // UICloudSharingController can work with SwiftData models directly
                        // by using the model's persistent identifier
                        print("   ℹ️ Letting UICloudSharingController handle share creation automatically")
                        // Provide nil - UICloudSharingController will handle finding the record
                        // using SwiftData's CloudKit integration
                        completionHandler(nil, container, nil)
                    }
                } catch {
                    print("   ❌ Error in preparation handler: \(error.localizedDescription)")
                    completionHandler(nil, container, error)
                }
            }
        }
        
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        
        // Configure for iPad popover if needed
        if let popover = controller.popoverPresentationController {
            popover.permittedArrowDirections = .any
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, vault: vault)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        @Binding var isPresented: Bool
        let vault: Vault
        
        init(isPresented: Binding<Bool>, vault: Vault) {
            _isPresented = isPresented
            self.vault = vault
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("❌ Failed to save CloudKit share: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isPresented = false
            }
        }
        
        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // Return thumbnail data for the vault if available
            // Could use vault icon or preview image
            return nil
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return vault.name
        }
        
        func itemType(for csc: UICloudSharingController) -> String? {
            return "Vault"
        }
    }
}

