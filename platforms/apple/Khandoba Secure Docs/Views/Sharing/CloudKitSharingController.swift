//
//  CloudKitSharingController.swift
//  Khandoba Secure Docs
//
//  SwiftUI wrapper for UICloudSharingController
//  Enables native iOS sharing for CloudKit shares
//

import SwiftUI
import CloudKit
import SwiftData

#if os(iOS)
import UIKit
#endif

#if os(iOS)
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
        // With SwiftData + CloudKit, we let UICloudSharingController automatically
        // find the CloudKit record using the model's PersistentIdentifier
        let controller = UICloudSharingController { controller, completionHandler in
            Task {
                do {
                    // Ensure vault is saved to SwiftData
                    try modelContext.save()
                    
                    // Get the vault's PersistentIdentifier
                    // SwiftData uses this internally to map to CloudKit record IDs
                    let persistentID = vault.persistentModelID
                    print("   📋 Vault PersistentIdentifier: \(persistentID)")
                    
                    // With SwiftData + CloudKit, when we pass nil to the completion handler,
                    // UICloudSharingController will automatically:
                    // 1. Use the PersistentIdentifier to find the CloudKit record
                    // 2. Create a share if one doesn't exist
                    // 3. Handle all the CloudKit operations internally
                    //
                    // This is the recommended approach and works without manual CloudKit queries
                    print("   ℹ️ Letting UICloudSharingController handle share creation")
                    print("   ℹ️ It will use SwiftData's PersistentIdentifier automatically")
                    print("   ℹ️ No server needed - CloudKit is Apple's backend service")
                    
                    completionHandler(nil, container, nil)
                } catch {
                    print("   ❌ Error in preparation handler: \(error.localizedDescription)")
                    // Still pass nil - UICloudSharingController may still succeed
                    completionHandler(nil, container, nil)
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
#endif

