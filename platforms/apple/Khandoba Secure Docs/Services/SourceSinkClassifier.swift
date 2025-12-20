//
//  SourceSinkClassifier.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import Photos
import AVFoundation

enum DocumentSource {
    case camera
    case microphone
    case userCreated
    case imported
    case shared
    case downloaded
    case unknown
    
    var isSourceData: Bool {
        // Data produced by the user
        switch self {
        case .camera, .microphone, .userCreated:
            return true
        case .imported, .shared, .downloaded:
            return false
        case .unknown:
            return false
        }
    }
    
    var isSinkData: Bool {
        // Data received from external sources
        !isSourceData
    }
}

class SourceSinkClassifier {
    
    /// Classify document based on its origin
    static func classify(fileURL: URL?, mimeType: String?, metadata: [String: Any]?) -> String {
        var isSource = false
        var isSink = false
        
        // Check if it's from camera/photos
        if let metadata = metadata {
            // Check EXIF data for camera info
            if metadata["Camera"] != nil || metadata["Make"] != nil {
                isSource = true
            }
            
            // Check for external source indicators
            if metadata["SourceApplication"] != nil || metadata["SharedFrom"] != nil {
                isSink = true
            }
        }
        
        // Check file URL for clues
        if let url = fileURL {
            let path = url.path.lowercased()
            
            // Camera/Photos indicators
            if path.contains("dcim") || path.contains("camera") || path.contains("photo") {
                isSource = true
            }
            
            // Download/Import indicators
            if path.contains("download") || path.contains("import") || path.contains("shared") {
                isSink = true
            }
        }
        
        // Check MIME type
        if let mimeType = mimeType {
            // Video from camera
            if mimeType.hasPrefix("video/") {
                isSource = true
            }
            
            // Audio recording
            if mimeType.hasPrefix("audio/") {
                isSource = true
            }
        }
        
        // Determine final classification
        if isSource && isSink {
            return "both"
        } else if isSource {
            return "source"
        } else if isSink {
            return "sink"
        } else {
            return "source" // Default to source if unknown
        }
    }
    
    /// Classify based on upload method
    /// - Video recording and voice memo are SOURCE (created by user)
    /// - Upload and download are SINK (received from external sources)
    static func classifyByUploadMethod(_ method: UploadMethod) -> String {
        switch method {
        case .camera, .photos, .voiceRecording, .videoRecording:
            // User-created content: camera photos, voice recordings, video recordings
            return "source"
        case .files, .fileUpload, .shareExtension, .import, .urlDownload:
            // External content: file uploads, imports, downloads, share extensions
            return "sink"
        }
    }
}

enum UploadMethod {
    case camera
    case photos
    case files
    case fileUpload // Alias for files (for clarity)
    case voiceRecording
    case videoRecording
    case shareExtension
    case `import`
    case urlDownload // New: for assets downloaded from URLs
}

