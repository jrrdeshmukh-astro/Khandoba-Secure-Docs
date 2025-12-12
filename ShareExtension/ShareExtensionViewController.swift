//
//  ShareExtensionViewController.swift
//  ShareExtension
//
//  Main view controller for the Share Extension
//

import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Combine

class ShareExtensionViewController: UIViewController {
    
    private var hostingController: UIHostingController<ShareExtensionView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        view.backgroundColor = .systemBackground
        
        // Create SwiftUI view
        let shareView = ShareExtensionView(extensionContext: extensionContext)
        let hostingController = UIHostingController(rootView: shareView)
        self.hostingController = hostingController
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure the view is properly sized
        preferredContentSize = CGSize(width: 320, height: 400)
    }
}

// MARK: - SwiftUI View

struct ShareExtensionView: View {
    @StateObject private var viewModel = ShareExtensionViewModel()
    let extensionContext: NSExtensionContext?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading vaults...")
                } else if viewModel.vaults.isEmpty {
                    Text("No vaults available")
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select a vault to save to:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        List(viewModel.vaults) { vault in
                            Button(action: {
                                viewModel.selectVault(vault, extensionContext: extensionContext)
                            }) {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(.blue)
                                    Text(vault.name)
                                    Spacer()
                                    if viewModel.selectedVaultID == vault.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Save to Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        extensionContext?.cancelRequest(withError: NSError(domain: "com.khandoba.securedocs", code: 0))
                    }
                }
            }
            .onAppear {
                viewModel.loadVaults()
                viewModel.loadSharedItems(extensionContext: extensionContext)
            }
        }
    }
}

// MARK: - View Model

@MainActor
class ShareExtensionViewModel: ObservableObject {
    @Published var vaults: [VaultInfo] = []
    @Published var isLoading = true
    @Published var selectedVaultID: UUID?
    @Published var errorMessage: String?
    @Published var sharedItems: [NSItemProvider] = []
    
    private let appGroupIdentifier = "group.com.khandoba.securedocs"
    
    func loadVaults() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            errorMessage = "App Group not available"
            isLoading = false
            return
        }
        
        if let vaultData = sharedDefaults.data(forKey: "available_vaults"),
           let vaultInfos = try? JSONDecoder().decode([VaultInfo].self, from: vaultData) {
            vaults = vaultInfos
        } else {
            errorMessage = "No vaults available. Please open the app first."
        }
        
        isLoading = false
    }
    
    func loadSharedItems(extensionContext: NSExtensionContext?) {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return
        }
        
        sharedItems = inputItems.flatMap { item in
            item.attachments ?? []
        }
    }
    
    func selectVault(_ vault: VaultInfo, extensionContext: NSExtensionContext?) {
        selectedVaultID = vault.id
        
        // Save items to the selected vault
        // This would typically save to App Group shared storage
        // and notify the main app to process the upload
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            errorMessage = "Failed to save"
            return
        }
        
        // Store the selected vault and items for the main app to process
        sharedDefaults.set(vault.id.uuidString, forKey: "pending_upload_vault_id")
        
        // Store item identifiers (simplified - in production, you'd store more metadata)
        let itemIdentifiers = sharedItems.map { $0.registeredTypeIdentifiers.first ?? "" }
        sharedDefaults.set(itemIdentifiers, forKey: "pending_upload_items")
        
        // Post notification for main app
        let notification = Notification(name: Notification.Name("ShareExtensionDidSaveItems"))
        NotificationCenter.default.post(notification)
        
        // Complete the extension request
        extensionContext?.completeRequest(returningItems: nil) { _ in
            // Extension will close
        }
    }
}

// MARK: - Data Models
// Note: VaultInfo is defined in ShareExtensionService.swift
// Making it Identifiable for SwiftUI List
extension VaultInfo: Identifiable {}
