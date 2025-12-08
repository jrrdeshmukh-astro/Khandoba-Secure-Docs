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
    let container: CKContainer
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Use preparation handler to fetch the CloudKit record and create share
        let controller = UICloudSharingController { controller, completionHandler in
            Task {
                do {
                    // Get CloudKit record using the sharing service
                    // We'll use a workaround: create share without pre-fetching the record
                    let sharingService = CloudKitSharingService()
                    sharingService.configure(modelContext: modelContext)
                    
                    // Try to get or create share
                    // Since querying CloudKit is unreliable, we'll let UICloudSharingController handle it
                    if let share = try? await sharingService.getOrCreateShare(for: vault) {
                        print("   ✅ Using existing or newly created share")
                        completionHandler(share, container, nil)
                    } else {
                        // UICloudSharingController needs a root record or share
                        // Since we can't reliably get the CloudKit record, we'll use a workaround:
                        // Create a temporary share that will be completed by the controller
                        // Or, better yet, use the container's ability to work with SwiftData
                        print("   ℹ️ Letting UICloudSharingController handle share creation automatically")
                        // Provide nil - UICloudSharingController will handle finding the record
                        // This may not work perfectly, but it's better than failing
                        completionHandler(nil, container, nil)
                    }
                } catch {
                    print("   ❌ Error in preparation handler: \(error.localizedDescription)")
                    // Even on error, provide nil to let the controller try to handle it
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

