//
//  URLAssetDownloadService.swift
//  Khandoba Secure Docs
//
//  Service to download assets (images, videos, documents) from public URLs
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class URLAssetDownloadService: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadError: String?
    
    private var downloadTask: URLSessionDataTask?
    
    nonisolated init() {}
    
    /// Download asset from a URL
    /// Returns the downloaded data, MIME type, and suggested filename
    func downloadAsset(from urlString: String) async throws -> (data: Data, mimeType: String, fileName: String) {
        guard let url = URL(string: urlString) else {
            throw URLDownloadError.invalidURL
        }
        
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
            downloadError = nil
        }
        
        defer {
            Task { @MainActor in
                isDownloading = false
            }
        }
        
        print("📥 URLAssetDownloadService: Downloading from \(urlString)")
        
        // Create URLSession with progress tracking
        let session = URLSession(configuration: .default)
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: url) { data, response, error in
                Task { @MainActor in
                    if let error = error {
                        print("❌ URLAssetDownloadService: Download error: \(error.localizedDescription)")
                        self.downloadError = error.localizedDescription
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("❌ URLAssetDownloadService: Invalid response")
                        self.downloadError = "Invalid response from server"
                        continuation.resume(throwing: URLDownloadError.invalidResponse)
                        return
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("❌ URLAssetDownloadService: HTTP error: \(httpResponse.statusCode)")
                        self.downloadError = "Server returned error: \(httpResponse.statusCode)"
                        continuation.resume(throwing: URLDownloadError.httpError(httpResponse.statusCode))
                        return
                    }
                    
                    guard let data = data, !data.isEmpty else {
                        print("❌ URLAssetDownloadService: No data received")
                        self.downloadError = "No data received from server"
                        continuation.resume(throwing: URLDownloadError.noData)
                        return
                    }
                    
                    // Determine MIME type from response
                    let mimeType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces) ?? "application/octet-stream"
                    
                    // Generate filename from URL or use default
                    let fileName = self.generateFileName(from: url, mimeType: mimeType)
                    
                    print("✅ URLAssetDownloadService: Downloaded \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                    print("   MIME type: \(mimeType)")
                    print("   Filename: \(fileName)")
                    
                    self.downloadProgress = 1.0
                    continuation.resume(returning: (data, mimeType, fileName))
                }
            }
            
            // Track progress
            task.resume()
            downloadTask = task
            
            // Simulate progress (URLSession doesn't provide easy progress tracking for data tasks)
            Task { [weak self] in
                guard let self = self else { return }
                var progress: Double = 0.0
                while progress < 0.9 {
                    let isStillDownloading = await MainActor.run {
                        self.isDownloading
                    }
                    guard isStillDownloading else { break }
                    
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    progress += 0.1
                    await MainActor.run {
                        self.downloadProgress = progress
                    }
                }
            }
        }
    }
    
    /// Generate a filename from URL and MIME type
    private func generateFileName(from url: URL, mimeType: String) -> String {
        // Try to get filename from URL path
        let pathComponent = url.lastPathComponent
        if !pathComponent.isEmpty && pathComponent != "/" {
            // Check if it has an extension
            if !pathComponent.contains(".") {
                // Add extension based on MIME type
                let fileExt = fileExtension(for: mimeType)
                return "\(pathComponent).\(fileExt)"
            }
            return pathComponent
        }
        
        // Generate filename from MIME type and timestamp
        let fileExt = fileExtension(for: mimeType)
        let prefix = filePrefix(for: mimeType)
        return "\(prefix)_\(Date().timeIntervalSince1970).\(fileExt)"
    }
    
    /// Get file extension from MIME type
    private func fileExtension(for mimeType: String) -> String {
        if mimeType.hasPrefix("image/") {
            if mimeType.contains("jpeg") || mimeType.contains("jpg") {
                return "jpg"
            } else if mimeType.contains("png") {
                return "png"
            } else if mimeType.contains("gif") {
                return "gif"
            } else if mimeType.contains("heic") || mimeType.contains("heif") {
                return "heic"
            } else if mimeType.contains("webp") {
                return "webp"
            }
            return "jpg"
        } else if mimeType.hasPrefix("video/") {
            if mimeType.contains("mp4") {
                return "mp4"
            } else if mimeType.contains("quicktime") || mimeType.contains("mov") {
                return "mov"
            } else if mimeType.contains("webm") {
                return "webm"
            }
            return "mp4"
        } else if mimeType.hasPrefix("audio/") {
            if mimeType.contains("mpeg") || mimeType.contains("mp3") {
                return "mp3"
            } else if mimeType.contains("wav") {
                return "wav"
            } else if mimeType.contains("aac") {
                return "m4a"
            }
            return "mp3"
        } else if mimeType == "application/pdf" {
            return "pdf"
        } else if mimeType.hasPrefix("text/") {
            return "txt"
        }
        return "bin"
    }
    
    /// Get file prefix from MIME type
    private func filePrefix(for mimeType: String) -> String {
        if mimeType.hasPrefix("image/") {
            return "image"
        } else if mimeType.hasPrefix("video/") {
            return "video"
        } else if mimeType.hasPrefix("audio/") {
            return "audio"
        } else if mimeType == "application/pdf" {
            return "document"
        }
        return "file"
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        Task { @MainActor in
            isDownloading = false
            downloadProgress = 0.0
        }
    }
}

// MARK: - Error Types

enum URLDownloadError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
    case downloadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please check the link and try again."
        case .invalidResponse:
            return "Invalid response from server."
        case .httpError(let code):
            return "Server returned error code: \(code)"
        case .noData:
            return "No data received from the URL."
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        }
    }
}

