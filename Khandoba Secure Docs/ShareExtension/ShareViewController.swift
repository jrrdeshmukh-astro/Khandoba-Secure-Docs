//
//  ShareViewController.swift
//  Khandoba Secure Docs Share Extension
//
//  Share Extension for importing media from other apps
//

import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Social

class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<ShareExtensionView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get shared items from extension context
        guard let extensionContext = extensionContext else {
            dismissExtension()
            return
        }
        
        // Create SwiftUI view
        let shareView = ShareExtensionView(extensionContext: extensionContext) {
            self.dismissExtension()
        }
        
        let hostingController = UIHostingController(rootView: shareView)
        self.hostingController = hostingController
        
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
    
    private func dismissExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

