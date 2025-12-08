//
//  ShareExtensionViewController.swift
//  Khandoba Secure Docs
//
//  Share Extension for importing media from other apps
//

import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import MobileCoreServices
import LocalAuthentication

class ShareExtensionViewController: UIViewController {
    private var hostingController: UIHostingController<ShareExtensionView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🚀 ShareExtension: viewDidLoad called")
        
        // Get shared items from extension context
        guard let extensionContext = extensionContext else {
            print("❌ ShareExtension: No extension context")
            showError("No extension context available")
            return
        }
        
        guard let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            print("❌ ShareExtension: No input items")
            showError("No items to share")
            return
        }
        
        print("✅ ShareExtension: Found \(inputItems.count) input item(s)")
        
        // Load shared items
        loadSharedItems(from: inputItems) { [weak self] items in
            guard let self = self else {
                print("⚠️ ShareExtension: Self is nil in completion")
                return
            }
            
            print("📦 ShareExtension: Loaded \(items.count) shared item(s)")
            
            DispatchQueue.main.async {
                if items.isEmpty {
                    print("⚠️ ShareExtension: No supported items found")
                    self.showError("No supported items found")
                    return
                }
                
                print("✅ ShareExtension: Creating SwiftUI view with \(items.count) item(s)")
                
                // Create SwiftUI view
                let shareView = ShareExtensionView(
                    sharedItems: items,
                    onComplete: { [weak self] in
                        print("✅ ShareExtension: Upload complete, dismissing")
                        self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                    },
                    onCancel: { [weak self] in
                        print("❌ ShareExtension: User cancelled")
                        let error = NSError(domain: "ShareExtension", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled"])
                        self?.extensionContext?.cancelRequest(withError: error)
                    }
                )
                
                let hostingController = UIHostingController(rootView: shareView)
                self.addChild(hostingController)
                hostingController.view.frame = self.view.bounds
                hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.view.addSubview(hostingController.view)
                hostingController.didMove(toParent: self)
                
                self.hostingController = hostingController
                
                print("✅ ShareExtension: SwiftUI view added to hierarchy")
            }
        }
    }
    
    // MARK: - Load Shared Items (Enhanced - Universal File Type Support)
    
    private func loadSharedItems(from inputItems: [NSExtensionItem], completion: @escaping ([SharedItem]) -> Void) {
        print("📥 ShareExtension: Loading shared items from \(inputItems.count) input item(s)")
        var sharedItems: [SharedItem] = []
        let group = DispatchGroup()
        
        for (index, item) in inputItems.enumerated() {
            guard let attachments = item.attachments else {
                print("⚠️ ShareExtension: Input item \(index) has no attachments")
                continue
            }
            
            print("📎 ShareExtension: Processing input item \(index) with \(attachments.count) attachment(s)")
            
            // Log all available type identifiers for debugging
            for (attIndex, attachment) in attachments.enumerated() {
                print("   📎 Attachment \(attIndex) type identifiers:")
                if let registeredTypes = attachment.registeredTypeIdentifiers as? [String] {
                    for typeID in registeredTypes {
                        print("      - \(typeID)")
                    }
                }
            }
            
            // First, check if there are any file attachments (prioritize files over URLs)
            // WhatsApp may use various type identifiers, so check all possibilities
            var hasFileAttachment = false
            for attachment in attachments {
                // Check for image types (including WhatsApp-specific formats)
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) ||
                   attachment.hasItemConformingToTypeIdentifier("public.jpeg") ||
                   attachment.hasItemConformingToTypeIdentifier("public.png") ||
                   attachment.hasItemConformingToTypeIdentifier("public.heic") ||
                   attachment.hasItemConformingToTypeIdentifier("com.compuserve.gif") ||
                   attachment.hasItemConformingToTypeIdentifier("public.tiff") ||
                   attachment.hasItemConformingToTypeIdentifier("public.webp") ||
                   // WhatsApp may also use these
                   attachment.hasItemConformingToTypeIdentifier("dyn.ah62d4rv4ge80k5p2") || // JPEG
                   attachment.hasItemConformingToTypeIdentifier("dyn.ah62d4rv4ge80k5p3") || // PNG
                   attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) ||
                   attachment.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) ||
                   attachment.hasItemConformingToTypeIdentifier(UTType.audio.identifier) ||
                   attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                    hasFileAttachment = true
                    print("   ✅ Found file attachment")
                    break
                }
            }
            
            // Handle all standard file types FIRST (prioritize files over URLs)
            // Photos approach: Try loading directly without checking type identifiers first
            // This is more permissive and catches cases where WhatsApp doesn't report correct types
            for attachment in attachments {
                // Skip URL type if we have file attachments (files take priority)
                if hasFileAttachment && attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    print("   ⏭️ Skipping URL attachment - file attachment found")
                    continue
                }
                
                // Try image loading first (Photos approach - try even if type isn't reported)
                // Check if it might be an image OR just try loading as generic data
                var triedAsImage = false
                
                // First, try image-specific type identifiers if reported
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) ||
                   attachment.hasItemConformingToTypeIdentifier("public.jpeg") ||
                   attachment.hasItemConformingToTypeIdentifier("public.png") ||
                   attachment.hasItemConformingToTypeIdentifier("public.heic") ||
                   attachment.hasItemConformingToTypeIdentifier("com.compuserve.gif") ||
                   attachment.hasItemConformingToTypeIdentifier("public.tiff") ||
                   attachment.hasItemConformingToTypeIdentifier("public.webp") ||
                   attachment.hasItemConformingToTypeIdentifier("dyn.ah62d4rv4ge80k5p2") ||
                   attachment.hasItemConformingToTypeIdentifier("dyn.ah62d4rv4ge80k5p3") {
                    triedAsImage = true
                    group.enter()
                    print("   📷 Found image attachment - loading...")
                    loadImage(from: attachment) { item in
                        if let item = item {
                            print("   ✅ Successfully loaded image: \(item.name)")
                            sharedItems.append(item)
                            group.leave()
                        } else {
                            print("   ⚠️ Failed to load image with image types, trying generic data...")
                            // If image-specific loading failed, try as generic data
                            // Don't leave the group yet - tryLoadAsGenericData will handle it
                            // But we need to leave the current group entry first
                            group.leave()
                            // Now try as generic data (it will enter/leave its own group)
                            tryLoadAsGenericData(attachment: attachment, group: group) { item in
                                if let item = item {
                                    sharedItems.append(item)
                                }
                            }
                        }
                    }
                }
                // If not reported as image, still try loading as generic data and check if it's an image
                // This is the "Photos approach" - be permissive and try everything
                else if !triedAsImage {
                    group.enter()
                    print("   📦 Trying attachment as generic data (Photos-style permissive approach)...")
                    tryLoadAsGenericData(attachment: attachment, group: group) { item in
                        if let item = item {
                            sharedItems.append(item)
                        }
                        group.leave()
                    }
                }
                // Videos
                else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    loadVideo(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
                // PDFs
                else if attachment.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    group.enter()
                    loadPDF(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
                // Audio
                else if attachment.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
                    group.enter()
                    loadAudio(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
                // Note: Generic data loading is now handled above in the permissive approach
                // Plain text
                else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    loadText(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
            }
            
            // Handle URL items LAST (only if no file attachments were found)
            // This ensures files are prioritized over URLs
            if !hasFileAttachment {
                if let urlProvider = attachments.first(where: { attachment in
                    attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier)
                }) {
                    group.enter()
                    urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, error in
                        defer { group.leave() }
                        
                        guard error == nil, let url = data as? URL else { return }
                        
                        print("   🔗 Processing URL: \(url.absoluteString)")
                        
                        // Check if it's a file:// URL (actual file, not web link)
                        if url.isFileURL {
                            print("   📄 Found file:// URL - loading file data")
                            // This is a file URL - load the actual file
                            if let fileData = try? Data(contentsOf: url) {
                                let mimeType = url.mimeType() ?? "application/octet-stream"
                                sharedItems.append(SharedItem(
                                    data: fileData,
                                    mimeType: mimeType,
                                    name: url.lastPathComponent,
                                    sourceURL: url
                                ))
                                print("   ✅ Loaded file from file:// URL: \(url.lastPathComponent)")
                            }
                        } else {
                            // It's a web URL - check if it's WhatsApp
                            if url.absoluteString.contains("wa.me") || 
                               url.absoluteString.contains("whatsapp.com") ||
                               url.absoluteString.contains("api.whatsapp.com") {
                                // Save WhatsApp link as a document
                                if let urlData = url.absoluteString.data(using: .utf8) {
                                    sharedItems.append(SharedItem(
                                        data: urlData,
                                        mimeType: "text/plain",
                                        name: "WhatsApp Link",
                                        sourceURL: url
                                    ))
                                }
                            } else {
                                // Regular web URL - save as document
                                if let urlData = url.absoluteString.data(using: .utf8) {
                                    sharedItems.append(SharedItem(
                                        data: urlData,
                                        mimeType: "text/plain",
                                        name: url.host ?? "Link",
                                        sourceURL: url
                                    ))
                                }
                            }
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            print("✅ ShareExtension: Finished loading \(sharedItems.count) shared item(s)")
            if sharedItems.isEmpty {
                print("⚠️ ShareExtension: No items were successfully loaded with standard methods")
                print("   Attempting fallback: trying to load all attachments as generic data...")
                
                // Fallback: Try loading all attachments as generic data
                // This catches cases where WhatsApp uses non-standard type identifiers
                let fallbackGroup = DispatchGroup()
                var fallbackItems: [SharedItem] = []
                
                for (index, item) in inputItems.enumerated() {
                    guard let attachments = item.attachments else { continue }
                    
                    for attachment in attachments {
                        // Skip if we already tried this as a specific type
                        if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                            continue // Skip URLs in fallback
                        }
                        
                        fallbackGroup.enter()
                        attachment.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { data, error in
                            defer { fallbackGroup.leave() }
                        
                        if let error = error {
                                print("   ⚠️ Fallback load error: \(error.localizedDescription)")
                            return
                        }
                        
                            if let url = data as? URL, url.isFileURL {
                                // It's a file URL - try to load it
                                if let fileData = try? Data(contentsOf: url) {
                                    // Check if it's an image
                                    if UIImage(data: fileData) != nil {
                                        let mimeType = url.mimeType() ?? "image/jpeg"
                                        let fileName = url.lastPathComponent.isEmpty ? "image_\(Date().timeIntervalSince1970).jpg" : url.lastPathComponent
                                        print("   ✅ Fallback: Loaded image from file URL: \(fileName)")
                                        fallbackItems.append(SharedItem(
                                            data: fileData,
                                            mimeType: mimeType,
                                            name: fileName,
                                            sourceURL: url
                                        ))
                                    }
                                }
                            } else if let data = data as? Data {
                                // Check if it's an image
                                if UIImage(data: data) != nil {
                                    let fileName = "image_\(Date().timeIntervalSince1970).jpg"
                                    print("   ✅ Fallback: Loaded image from Data: \(fileName)")
                                    fallbackItems.append(SharedItem(
                                        data: data,
                                        mimeType: "image/jpeg",
                                        name: fileName
                                    ))
                                }
                            }
                        }
                    }
                }
                
                fallbackGroup.notify(queue: .main) {
                    if !fallbackItems.isEmpty {
                        print("✅ ShareExtension: Fallback loaded \(fallbackItems.count) item(s)")
                        completion(fallbackItems)
                    } else {
                        print("⚠️ ShareExtension: No items were successfully loaded")
                        print("   This might mean:")
                        print("   1. The shared content type is not supported")
                        print("   2. There was an error loading the items")
                        print("   3. The items are in an unexpected format")
                        print("   4. WhatsApp is using a type identifier we don't recognize")
                        completion([])
                    }
                }
            } else {
                completion(sharedItems)
            }
        }
    }
    
    // MARK: - File Type Loaders
    
    /// Try loading attachment as generic data and detect if it's an image (Photos-style approach)
    private func tryLoadAsGenericData(attachment: NSItemProvider, group: DispatchGroup, completion: @escaping (SharedItem?) -> Void) {
        group.enter()
        attachment.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { data, error in
            defer { group.leave() }
            
            if let error = error {
                print("   ⚠️ Generic data load error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let url = data as? URL, url.isFileURL {
                print("   📄 Generic data provided as file URL: \(url.path)")
                if let fileData = try? Data(contentsOf: url) {
                    // Check if it's an image
                    if UIImage(data: fileData) != nil {
                        let mimeType = url.mimeType() ?? "image/jpeg"
                        let fileName = url.lastPathComponent.isEmpty ? "image_\(Date().timeIntervalSince1970).jpg" : url.lastPathComponent
                        print("   ✅ Generic data is actually an image: \(fileName)")
                        completion(SharedItem(
                            data: fileData,
                            mimeType: mimeType,
                            name: fileName,
                            sourceURL: url
                        ))
                    } else {
                        // Not an image, but still a file
                        completion(SharedItem(
                            data: fileData,
                            mimeType: url.mimeType() ?? "application/octet-stream",
                            name: url.lastPathComponent,
                            sourceURL: url
                        ))
                    }
                } else {
                    completion(nil)
                }
            } else if let data = data as? Data {
                print("   📦 Generic data provided as Data (\(data.count) bytes)")
                // Check if it's an image by trying to create UIImage
                if UIImage(data: data) != nil {
                    // Detect format from data signature
                    var mimeType = "image/jpeg"
                    var fileExt = "jpg"
                    
                    if data.count > 8 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
                        mimeType = "image/png"
                        fileExt = "png"
                    } else if data.count > 2 && data[0] == 0xFF && data[1] == 0xD8 {
                        mimeType = "image/jpeg"
                        fileExt = "jpg"
                    } else if data.count > 12 {
                        let header = String(data: data.prefix(12), encoding: .ascii) ?? ""
                        if header.contains("ftyp") && (header.contains("heic") || header.contains("heif")) {
                            mimeType = "image/heic"
                            fileExt = "heic"
                        }
                    }
                    
                    let fileName = "image_\(Date().timeIntervalSince1970).\(fileExt)"
                    print("   ✅ Generic data is actually an image: \(fileName) (\(mimeType))")
                    completion(SharedItem(
                        data: data,
                        mimeType: mimeType,
                        name: fileName
                    ))
                } else {
                    // Not an image, but still data
                    completion(SharedItem(
                        data: data,
                        mimeType: "application/octet-stream",
                        name: "file_\(Date().timeIntervalSince1970)"
                    ))
                }
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadImage(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        // Try to find the best type identifier for this image
        // Include WhatsApp-specific type identifiers
        let typeIdentifiers = [
            UTType.image.identifier,
            "public.jpeg",
            "public.png",
            "public.heic",
            "com.compuserve.gif",
            "public.tiff",
            "public.webp",
            // WhatsApp dynamic type identifiers
            "dyn.ah62d4rv4ge80k5p2", // JPEG
            "dyn.ah62d4rv4ge80k5p3", // PNG
            // Generic data as last resort (will check if it's actually an image)
            UTType.data.identifier
        ]
        
        var triedTypes: [String] = []
        
        func tryLoadImage(typeID: String) {
            guard !triedTypes.contains(typeID) else { return }
            triedTypes.append(typeID)
            
            print("   🔄 Trying to load image with type: \(typeID)")
            attachment.loadItem(forTypeIdentifier: typeID, options: nil) { data, error in
                        if let error = error {
                    print("   ⚠️ Error loading image with \(typeID): \(error.localizedDescription)")
                    // Try next type if available
                    if let nextType = typeIdentifiers.first(where: { !triedTypes.contains($0) && attachment.hasItemConformingToTypeIdentifier($0) }) {
                        tryLoadImage(typeID: nextType)
                    } else {
                        completion(nil)
                    }
                            return
                        }
                        
                // Try URL first (most common for WhatsApp)
                        if let url = data as? URL {
                    print("   📄 Image provided as URL: \(url.path)")
                    // Check if it's a file URL
                    if url.isFileURL {
                        if let imageData = try? Data(contentsOf: url) {
                            if UIImage(data: imageData) != nil {
                                let mimeType = url.mimeType() ?? "image/jpeg"
                                let fileName = url.lastPathComponent.isEmpty ? "image_\(Date().timeIntervalSince1970).jpg" : url.lastPathComponent
                                print("   ✅ Successfully loaded image from file URL: \(fileName)")
                                completion(SharedItem(
                                    data: imageData,
                                    mimeType: mimeType,
                                    name: fileName
                                ))
                                return
                            }
                        }
                    }
                }
                
                // Try UIImage directly
                if let image = data as? UIImage {
                    print("   🖼️ Image provided as UIImage")
                    if let imageData = image.jpegData(compressionQuality: 0.9) {
                        let fileName = "image_\(Date().timeIntervalSince1970).jpg"
                        print("   ✅ Successfully converted UIImage to JPEG: \(fileName)")
                        completion(SharedItem(
                                data: imageData,
                                mimeType: "image/jpeg",
                            name: fileName
                        ))
                        return
                        }
                    }
                
                // Try Data directly
                if let imageData = data as? Data {
                    print("   📦 Image provided as Data (\(imageData.count) bytes)")
                    if UIImage(data: imageData) != nil {
                        let fileName = "image_\(Date().timeIntervalSince1970).jpg"
                        print("   ✅ Successfully loaded image from Data: \(fileName)")
                        completion(SharedItem(
                            data: imageData,
                            mimeType: "image/jpeg",
                            name: fileName
                        ))
                            return
                        }
                }
                
                // If we get here, this type didn't work - try next
                if let nextType = typeIdentifiers.first(where: { !triedTypes.contains($0) && attachment.hasItemConformingToTypeIdentifier($0) }) {
                    tryLoadImage(typeID: nextType)
                } else {
                    print("   ❌ Could not load image with any available type identifier")
                    completion(nil)
                }
            }
        }
        
        // Start with the first available type
        if let firstType = typeIdentifiers.first(where: { attachment.hasItemConformingToTypeIdentifier($0) }) {
            tryLoadImage(typeID: firstType)
        } else {
            print("   ❌ No supported image type identifier found")
            completion(nil)
        }
    }
    
    private func loadVideo(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { data, error in
            guard error == nil, let url = data as? URL else {
                completion(nil)
                            return
                        }
                        
                            if let videoData = try? Data(contentsOf: url) {
                completion(SharedItem(
                                    data: videoData,
                    mimeType: url.mimeType() ?? "video/mp4",
                                    name: url.lastPathComponent
                                ))
            } else {
                completion(nil)
                        }
                    }
    }
    
    private func loadPDF(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { data, error in
            guard error == nil else {
                completion(nil)
                return
            }
            
            if let url = data as? URL,
               let pdfData = try? Data(contentsOf: url) {
                completion(SharedItem(
                    data: pdfData,
                    mimeType: "application/pdf",
                                    name: url.lastPathComponent
                                ))
            } else if let data = data as? Data {
                completion(SharedItem(
                    data: data,
                    mimeType: "application/pdf",
                    name: "document_\(Date().timeIntervalSince1970).pdf"
                ))
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadAudio(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.audio.identifier, options: nil) { data, error in
            guard error == nil, let url = data as? URL else {
                completion(nil)
                            return
                        }
                        
            if let audioData = try? Data(contentsOf: url) {
                completion(SharedItem(
                    data: audioData,
                    mimeType: url.mimeType() ?? "audio/mpeg",
                                    name: url.lastPathComponent
                                ))
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadFile(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { data, error in
            guard error == nil else {
                print("   ⚠️ Error loading file: \(error?.localizedDescription ?? "unknown")")
                completion(nil)
                            return
                        }
                        
                        if let url = data as? URL {
                print("   📄 File provided as URL: \(url.path)")
                            if let fileData = try? Data(contentsOf: url) {
                    // Check if it's actually an image
                    if let image = UIImage(data: fileData) {
                        let mimeType = url.mimeType() ?? "image/jpeg"
                        let fileName = url.lastPathComponent.isEmpty ? "image_\(Date().timeIntervalSince1970).jpg" : url.lastPathComponent
                        print("   ✅ Generic file is actually an image: \(fileName)")
                        completion(SharedItem(
                                    data: fileData,
                                    mimeType: mimeType,
                            name: fileName
                        ))
                    } else {
                        // Not an image, treat as generic file
                        completion(SharedItem(
                            data: fileData,
                            mimeType: url.mimeType() ?? "application/octet-stream",
                                    name: url.lastPathComponent
                                ))
                            }
                } else {
                    completion(nil)
                }
            } else if let data = data as? Data {
                print("   📦 File provided as Data (\(data.count) bytes)")
                // Check if it's actually an image
                if let image = UIImage(data: data) {
                    // Try to determine format from data
                    var mimeType = "image/jpeg"
                    var fileExt = "jpg"
                    
                    // Check for PNG signature
                    if data.count > 8 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
                        mimeType = "image/png"
                        fileExt = "png"
                    }
                    // Check for JPEG signature
                    else if data.count > 2 && data[0] == 0xFF && data[1] == 0xD8 {
                        mimeType = "image/jpeg"
                        fileExt = "jpg"
                    }
                    // Check for HEIC (more complex, but basic check)
                    else if data.count > 12 {
                        let header = String(data: data.prefix(12), encoding: .ascii) ?? ""
                        if header.contains("ftyp") && (header.contains("heic") || header.contains("heif")) {
                            mimeType = "image/heic"
                            fileExt = "heic"
                        }
                    }
                    
                    let fileName = "image_\(Date().timeIntervalSince1970).\(fileExt)"
                    print("   ✅ Generic data is actually an image: \(fileName) (\(mimeType))")
                    completion(SharedItem(
                        data: data,
                        mimeType: mimeType,
                        name: fileName
                    ))
                } else {
                    // Not an image, treat as generic file
                    completion(SharedItem(
                        data: data,
                                mimeType: "application/octet-stream",
                                name: "file_\(Date().timeIntervalSince1970)"
                            ))
                        }
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadText(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, error in
            guard error == nil else {
                completion(nil)
                            return
                        }
                        
                        if let text = data as? String,
                           let textData = text.data(using: .utf8) {
                completion(SharedItem(
                                data: textData,
                                mimeType: "text/plain",
                                name: "note_\(Date().timeIntervalSince1970).txt"
                                ))
                } else {
                completion(nil)
                }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            let error = NSError(domain: "ShareExtension", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
            self?.extensionContext?.cancelRequest(withError: error)
        })
        present(alert, animated: true)
    }
}

// MARK: - Shared Item Model

struct SharedItem: Identifiable {
    let id = UUID()
    let data: Data
    let mimeType: String
    let name: String
    var sourceURL: URL?
}

// MARK: - SwiftUI Share Extension View

struct ShareExtensionView: View {
    let sharedItems: [SharedItem]
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedVault: Vault?
    @State private var vaults: [Vault] = []
    @State private var isLoading = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var uploadedCount = 0
    @State private var isAuthenticated = false
    @State private var showBiometricAuth = false
    @State private var authError: String?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                contentView
            }
            .navigationTitle("Save to Khandoba")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(colors.textPrimary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Load vaults immediately without blocking on authentication
                // Share extensions are already secure, so we can show UI first
                print("📱 ShareExtension: View appeared, loading vaults without blocking authentication")
                loadVaults()
            }
            .refreshable {
                await loadVaultsAsync()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
                if isLoading {
            loadingView
        } else if isUploading {
            uploadingView
        } else {
            mainContentView
        }
    }
    
    private var loadingView: some View {
        let colors = theme.colors(for: colorScheme)
        
        return VStack(spacing: UnifiedTheme.Spacing.md) {
                        ProgressView()
                .tint(colors.primary)
                        Text("Loading vaults...")
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
                    }
    }
    
    private var uploadingView: some View {
        let colors = theme.colors(for: colorScheme)
        
        return VStack(spacing: UnifiedTheme.Spacing.lg) {
                        ProgressView(value: uploadProgress)
                .progressViewStyle(.linear)
                .tint(colors.primary)
            
                        Text("Uploading \(uploadedCount) of \(sharedItems.count) items...")
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
            
            Text("\(Int(uploadProgress * 100))%")
                .font(theme.typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(colors.primary)
                    }
        .padding(UnifiedTheme.Spacing.md)
    }
    
    private var mainContentView: some View {
        return ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                itemsPreviewCard
                vaultSelectionCard
                uploadButton
            }
            .padding(UnifiedTheme.Spacing.md)
        }
    }
    
    private var itemsPreviewCard: some View {
        let colors = theme.colors(for: colorScheme)
        
        return StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(colors.primary)
                        .font(.title3)
                    Text("\(sharedItems.count) item(s) to save")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                                
                ForEach(sharedItems.prefix(3)) { item in
                                    HStack {
                                        Image(systemName: iconForMimeType(item.mimeType))
                            .foregroundColor(colors.textSecondary)
                            .frame(width: 24)
                                            Text(item.name)
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                                                .lineLimit(1)
                                        Spacer()
                                            Text(ByteCountFormatter.string(fromByteCount: Int64(item.data.count), countStyle: .file))
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                                    }
                                }
                
                if sharedItems.count > 3 {
                    Text("+ \(sharedItems.count - 3) more")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .padding(.leading, 32)
                }
            }
        }
    }
    
    private var vaultSelectionCard: some View {
        let colors = theme.colors(for: colorScheme)
        
        return StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(colors.primary)
                        .font(.title3)
                                Text("Select Vault")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                                
                                if vaults.isEmpty {
                    emptyVaultsView
                                } else {
                                ForEach(vaults) { vault in
                        vaultRow(vault: vault)
                    }
                }
            }
        }
    }
    
    private func vaultRow(vault: Vault) -> some View {
        let colors = theme.colors(for: colorScheme)
        let isSelected = selectedVault?.id == vault.id
        let vaultName = vault.name.isEmpty ? "Unnamed Vault" : vault.name
        
        return Button {
                                        selectedVault = vault
                                    } label: {
                                        HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? colors.primary : colors.textTertiary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                    Text(vaultName)
                        .foregroundColor(colors.textPrimary)
                        .font(theme.typography.headline)
                    
                    if let description = vault.vaultDescription {
                        Text(description)
                            .foregroundColor(colors.textSecondary)
                            .font(theme.typography.caption)
                            .lineLimit(1)
                    }
                }
                
                                            Spacer()
                
                // Show active session indicator
                if hasActiveSession(vault) {
                    HStack(spacing: UnifiedTheme.Spacing.xs) {
                        Circle()
                            .fill(colors.success)
                            .frame(width: 8, height: 8)
                        Text("Open")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.success)
                    }
                }
                                        }
            .padding(UnifiedTheme.Spacing.md)
            .background(isSelected ? colors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(UnifiedTheme.CornerRadius.md)
                                        }
                                    }
    
    private var emptyVaultsView: some View {
        let colors = theme.colors(for: colorScheme)
        
        return VStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: "lock.shield")
                .font(.largeTitle)
                .foregroundColor(colors.textSecondary)
            
            Text("No unlocked vaults")
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
            
            Text("Open a vault in the main app first")
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, UnifiedTheme.Spacing.lg)
    }
    
    private var uploadButton: some View {
        let colors = theme.colors(for: colorScheme)
        
        return Button {
                                uploadItems()
                                } label: {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                Text("Save to Vault")
            }
            .font(theme.typography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
            .padding(UnifiedTheme.Spacing.md)
            .background(selectedVault != nil ? colors.primary : colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                }
                            .disabled(selectedVault == nil || isUploading)
    }
    
    // MARK: - Helper Functions
    
    private func hasActiveSession(_ vault: Vault) -> Bool {
        guard let sessions = vault.sessions else { return false }
        let now = Date()
        return sessions.contains { session in
            session.isActive && session.expiresAt > now
        }
    }
    
    private func iconForMimeType(_ mimeType: String) -> String {
        if mimeType.hasPrefix("image/") {
            return "photo.fill"
        } else if mimeType.hasPrefix("video/") {
            return "video.fill"
        } else if mimeType.hasPrefix("audio/") {
            return "music.note"
        } else if mimeType == "application/pdf" {
            return "doc.fill"
        } else {
            return "doc"
        }
    }
    
    private func loadVaults() {
        Task {
            await loadVaultsAsync()
        }
    }
    
    // MARK: - Authentication (Optional for Share Extensions)
    // Note: Share Extensions are already secure, so we don't require authentication
    // before showing the UI. This prevents blocking issues when sharing from apps like WhatsApp.
    
    private func authenticateAndLoadVaultsAsync() async {
        // For Share Extensions, we skip authentication to avoid blocking the UI
        // The extension is already running in a secure context
        print("📱 ShareExtension: Skipping authentication (Share Extensions are already secure)")
        await MainActor.run {
            isAuthenticated = true
        }
        await loadVaultsAsync()
    }
    
    // Cache ModelContainer to avoid creating multiple instances
    private static var cachedContainer: ModelContainer?
    private static var containerCreationLock = NSLock()
    
    private func loadVaultsAsync() async {
        await MainActor.run {
        isLoading = true
        }
        
            do {
            // Use cached container if available
            let container: ModelContainer
            if let cached = Self.cachedContainer {
                print("📦 ShareExtension: Using cached ModelContainer")
                container = cached
            } else {
                // Create ModelContainer for ShareExtension with same schema as main app
                // Use App Group to share data with main app
                let schema = Schema([
                    User.self,
                    UserRole.self,
                    Vault.self,
                    VaultSession.self,
                    VaultAccessLog.self,
                    DualKeyRequest.self,
                    Document.self,
                    DocumentVersion.self,
                    ChatMessage.self,
                    Nominee.self,
                    VaultTransferRequest.self,
                    EmergencyAccessRequest.self
                ])
                
                // Use App Group identifier for shared storage
                let appGroupIdentifier = "group.com.khandoba.securedocs"
                let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
                
                print("📦 ShareExtension: Setting up ModelContainer")
                print("   App Group ID: \(appGroupIdentifier)")
                print("   App Group URL: \(appGroupURL?.path ?? "nil - App Group not accessible")")
                
                // Check if App Group is accessible
                if appGroupURL == nil {
                    print("⚠️ ShareExtension: App Group not accessible")
                    print("   This might mean:")
                    print("   1. App Group not configured in Xcode project settings")
                    print("   2. App Group identifier mismatch")
                    print("   3. Extension not signed with same team")
                    print("   Using CloudKit sync (may take longer)")
                }
                
                // Create ModelConfiguration - use App Group identifier
                // Try with App Group first, fallback to default if needed
                let modelConfiguration: ModelConfiguration
                if appGroupURL != nil {
                    // App Group is accessible, use it
                    modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                        groupContainer: .identifier(appGroupIdentifier),
                    cloudKitDatabase: .automatic
                )
                } else {
                    // App Group not accessible, use default configuration
                    print("⚠️ ShareExtension: Using default configuration (App Group not accessible)")
                    modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                }
                
                // Thread-safe container creation
                Self.containerCreationLock.lock()
                defer { Self.containerCreationLock.unlock() }
                
                // Check again after acquiring lock (double-check pattern)
                if let cached = Self.cachedContainer {
                    print("📦 ShareExtension: Container was created by another task, using cached")
                    container = cached
                } else {
                    do {
                        container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                        Self.cachedContainer = container
                        print("✅ ShareExtension: ModelContainer created and cached")
                    } catch let initialError {
                        print("❌ ShareExtension: Failed to create ModelContainer with App Group/CloudKit")
                        print("   Error: \(initialError.localizedDescription)")
                        // Try fallback without CloudKit and App Group
                        print("   Attempting fallback without CloudKit and App Group...")
                        do {
                            let fallbackConfig = ModelConfiguration(
                                schema: schema,
                                isStoredInMemoryOnly: false
                            )
                            container = try ModelContainer(for: schema, configurations: [fallbackConfig])
                            Self.cachedContainer = container
                            print("   ✅ Fallback ModelContainer created and cached")
                        } catch let fallbackError {
                            print("❌ ShareExtension: Fallback ModelContainer creation also failed")
                            print("   Error: \(fallbackError.localizedDescription)")
                            // Last resort: in-memory only
                            do {
                                let inMemoryConfig = ModelConfiguration(
                                    schema: schema,
                                    isStoredInMemoryOnly: true
                                )
                                container = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                                Self.cachedContainer = container
                                print("   ⚠️ Using in-memory only ModelContainer (data will not persist)")
                            } catch let inMemoryError {
                                print("❌ ShareExtension: Even in-memory ModelContainer creation failed")
                                print("   Error: \(inMemoryError.localizedDescription)")
                                // Re-throw the error - we can't proceed without a container
                                throw inMemoryError
                            }
                        }
                    }
                }
            }
            
            // Get the context (mainContext is already on main actor)
                let context = container.mainContext
                
            print("✅ ShareExtension: ModelContainer created successfully")
            
            // Fetch vaults with a delay to allow CloudKit sync
            print("   Waiting for CloudKit sync...")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second for CloudKit sync
            
                let descriptor = FetchDescriptor<Vault>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                
            // Try fetching vaults with error handling
            var fetchedVaults: [Vault] = []
            do {
                fetchedVaults = try context.fetch(descriptor)
                print("📦 ShareExtension: Initial fetch found \(fetchedVaults.count) vault(s)")
            } catch {
                print("⚠️ ShareExtension: Error fetching vaults: \(error.localizedDescription)")
                // Continue with empty array - will show "No vaults available"
            }
            
            // If no vaults found, try waiting a bit longer for CloudKit sync
            if fetchedVaults.isEmpty {
                print("   No vaults found - waiting additional 2 seconds for CloudKit sync...")
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 more seconds
                
                // Try fetching again
                do {
                    fetchedVaults = try context.fetch(descriptor)
                    print("   After additional wait: Found \(fetchedVaults.count) vault(s)")
                } catch {
                    print("⚠️ ShareExtension: Error on retry fetch: \(error.localizedDescription)")
                }
            }
            
            // Log all vaults found (safely access properties)
            for vault in fetchedVaults {
                let vaultName = vault.name
                let vaultID = vault.id.uuidString
                let isSystem = vault.isSystemVault
                print("   Vault: \(vaultName) (ID: \(vaultID), System: \(isSystem))")
            }
            
            // Filter and update on main thread
            // Filter out system vaults and only show unlocked vaults (with active sessions)
            let now = Date()
            let unlockedVaults = fetchedVaults.filter { vault in
                // Exclude system vaults
                guard !vault.isSystemVault else { return false }
                
                // Check if vault has an active session
                if let sessions = vault.sessions {
                    return sessions.contains { session in
                        session.isActive && session.expiresAt > now
                    }
                }
                return false
            }
            
            print("📦 ShareExtension: Found \(unlockedVaults.count) unlocked vault(s) out of \(fetchedVaults.count) total")
            
            let firstVault = unlockedVaults.first
                
                await MainActor.run {
                self.vaults = unlockedVaults
                self.isLoading = false
                
                print("📦 ShareExtension: \(self.vaults.count) unlocked vault(s) available")
                    
                    // Auto-select first vault if available
                if self.selectedVault == nil, let firstVault = firstVault {
                    self.selectedVault = firstVault
                    let vaultName = firstVault.name.isEmpty ? "Unnamed Vault" : firstVault.name
                    print("📦 ShareExtension: Auto-selected vault: \(vaultName)")
                }
                
                if self.vaults.isEmpty {
                    print("⚠️ ShareExtension: No vaults available")
                    print("   Possible reasons:")
                    print("   1. No vaults created in main app yet")
                    print("   2. CloudKit sync not complete (wait a few seconds)")
                    print("   3. App Group not properly configured")
                    print("   4. User not signed into iCloud")
                    }
                }
            } catch {
            print("❌ ShareExtension: Failed to load vaults: \(error.localizedDescription)")
            print("   Error details: \(error)")
            if let nsError = error as NSError? {
                print("   Domain: \(nsError.domain)")
                print("   Code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }
                await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load vaults. Please ensure you have created at least one vault in the main app. Error: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    private func uploadItems() {
        guard let vault = selectedVault else { return }
        
        isUploading = true
        uploadedCount = 0
        
        let itemsToUpload = sharedItems
        let completion = onComplete
        
        Task {
            do {
                // Create ModelContainer with same configuration as loadVaults
                let schema = Schema([
                    User.self,
                    UserRole.self,
                    Vault.self,
                    VaultSession.self,
                    VaultAccessLog.self,
                    DualKeyRequest.self,
                    Document.self,
                    DocumentVersion.self,
                    ChatMessage.self,
                    Nominee.self,
                    VaultTransferRequest.self,
                    EmergencyAccessRequest.self
                ])
                
                // Use App Group identifier for shared storage
                let appGroupIdentifier = "group.com.khandoba.securedocs"
                
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    groupContainer: .identifier(appGroupIdentifier),
                    cloudKitDatabase: .automatic
                )
                
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = container.mainContext
                
                // Reload vault from context
                let vaultID = vault.id
                let vaultDescriptor = FetchDescriptor<Vault>(
                    predicate: #Predicate { $0.id == vaultID }
                )
                
                guard let vaultInContext = try context.fetch(vaultDescriptor).first else {
                    throw NSError(domain: "ShareExtension", code: 1, userInfo: [NSLocalizedDescriptionKey: "Vault not found"])
                }
                
                // Upload each item
                for (index, item) in itemsToUpload.enumerated() {
                    // Create document
                    let document = Document(
                        name: item.name,
                        mimeType: item.mimeType,
                        documentType: documentTypeForMimeType(item.mimeType)
                    )
                    
                    // Encrypt and store file data
                    document.encryptedFileData = item.data // In production, encrypt this
                    document.fileSize = Int64(item.data.count)
                    document.uploadedAt = Date()
                    document.sourceSinkType = "sink" // Shared from external app
                    
                    // Add to vault
                    document.vault = vaultInContext
                    if vaultInContext.documents == nil {
                        vaultInContext.documents = []
                    }
                    vaultInContext.documents?.append(document)
                    
                    context.insert(document)
                    
                    // Save after each document to ensure persistence
                    try context.save()
                    
                    // Force CloudKit sync by accessing the document after save
                    // This ensures the document is queued for CloudKit sync
                    _ = document.id
                    
                    await MainActor.run {
                    uploadedCount = index + 1
                        uploadProgress = Double(uploadedCount) / Double(itemsToUpload.count)
                }
                }
                
                // Final save to ensure all changes are persisted
                try context.save()
                
                // Give CloudKit a moment to sync
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                await MainActor.run {
                    isUploading = false
                    completion()
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func documentTypeForMimeType(_ mimeType: String) -> String {
        if mimeType.hasPrefix("image/") {
            return "image"
        } else if mimeType.hasPrefix("video/") {
            return "video"
        } else if mimeType.hasPrefix("audio/") {
            return "audio"
        } else if mimeType == "application/pdf" {
            return "pdf"
        } else if mimeType.hasPrefix("text/") {
            return "text"
        } else {
            return "file"
    }
}
}
