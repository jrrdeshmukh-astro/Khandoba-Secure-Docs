//
//  URL+Extensions.swift
//  Khandoba Secure Docs
//
//  Shared URL extension for MIME type detection
//  Used by both main app and ShareExtension
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    /// Get MIME type for a URL
    /// Tries multiple methods: resourceValues, UTType from extension, fallback mapping
    func mimeType() -> String? {
        // Method 1: Try using resourceValues (most accurate)
        if let typeID = try? resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let utType = UTType(typeID) {
            return utType.preferredMIMEType
        }
        
        // Method 2: Try using filename extension with UTType
        if let uti = UTType(filenameExtension: self.pathExtension) {
            return uti.preferredMIMEType
        }
        
        // Method 3: Fallback to common extension mapping
        let ext = pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "gif": return "image/gif"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "m4v": return "video/x-m4v"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        case "mp3": return "audio/mpeg"
        case "m4a": return "audio/mp4"
        case "aac": return "audio/aac"
        default: return "application/octet-stream"
        }
    }
}

