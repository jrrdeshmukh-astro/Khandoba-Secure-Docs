//
//  CloudStorageService.swift
//  Khandoba Secure Docs
//
//  Cloud storage integration service for Google Drive, Dropbox, OneDrive
//

import Foundation
import SwiftData
import Combine
import UniformTypeIdentifiers

/// Cloud storage provider types
enum CloudStorageProvider: String, CaseIterable {
    case googleDrive = "google_drive"
    case dropbox = "dropbox"
    case oneDrive = "onedrive"
    case iCloudDrive = "icloud_drive"
    
    var displayName: String {
        switch self {
        case .googleDrive: return "Google Drive"
        case .dropbox: return "Dropbox"
        case .oneDrive: return "OneDrive"
        case .iCloudDrive: return "iCloud Drive"
        }
    }
}

/// Cloud file structure
struct CloudFile: Identifiable, Codable {
    let id: String
    let name: String
    let mimeType: String?
    let size: Int64?
    let modifiedDate: Date?
    let isFolder: Bool
    let parentId: String?
    let downloadUrl: String?
    let thumbnailUrl: String?
}

/// Cloud storage errors
enum CloudStorageError: LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case fetchFailed
    case downloadFailed
    case uploadFailed
    case invalidProvider
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Cloud storage account is not authenticated."
        case .authenticationFailed:
            return "Failed to authenticate with cloud storage provider."
        case .fetchFailed:
            return "Failed to fetch files from cloud storage."
        case .downloadFailed:
            return "Failed to download file from cloud storage."
        case .uploadFailed:
            return "Failed to upload file to cloud storage."
        case .invalidProvider:
            return "Invalid cloud storage provider specified."
        }
    }
}

@MainActor
final class CloudStorageService: ObservableObject {
    static let shared = CloudStorageService()
    
    @Published var connectedProviders: Set<CloudStorageProvider> = []
    @Published var isFetching = false
    @Published var fetchedFiles: [CloudFile] = []
    
    private let oauthService = OAuthService.shared
    
    private init() {
        // Only iCloud Drive is supported - always available on iOS
        connectedProviders.insert(.iCloudDrive)
        // Remove other providers from connected set
        connectedProviders.remove(.googleDrive)
        connectedProviders.remove(.dropbox)
        connectedProviders.remove(.oneDrive)
    }
    
    // MARK: - Authentication
    
    /// Connect cloud storage provider using OAuth
    func connectProvider(_ provider: CloudStorageProvider) async throws {
        switch provider {
        case .googleDrive:
            _ = try await oauthService.authenticate(provider: .googleDrive)
        case .dropbox:
            _ = try await oauthService.authenticate(provider: .dropbox)
        case .oneDrive:
            _ = try await oauthService.authenticate(provider: .oneDrive)
        case .iCloudDrive:
            // iCloud Drive is native, no OAuth needed
            break
        }
        
        connectedProviders.insert(provider)
    }
    
    /// Disconnect cloud storage provider
    func disconnectProvider(_ provider: CloudStorageProvider) throws {
        switch provider {
        case .googleDrive:
            try oauthService.disconnect(provider: .googleDrive)
        case .dropbox:
            try oauthService.disconnect(provider: .dropbox)
        case .oneDrive:
            try oauthService.disconnect(provider: .oneDrive)
        case .iCloudDrive:
            // iCloud Drive cannot be disconnected
            break
        }
        
        connectedProviders.remove(provider)
    }
    
    // Only iCloud Drive is supported - no OAuth providers
    
    // MARK: - File Listing
    
    /// List files in cloud storage folder
    func listFiles(
        provider: CloudStorageProvider,
        folderId: String? = nil,
        maxResults: Int = 100
    ) async throws -> [CloudFile] {
        guard connectedProviders.contains(provider) else {
            throw CloudStorageError.notAuthenticated
        }
        
        isFetching = true
        defer { isFetching = false }
        
        switch provider {
        case .googleDrive:
            return try await listGoogleDriveFiles(folderId: folderId, maxResults: maxResults)
        case .dropbox:
            return try await listDropboxFiles(folderId: folderId, maxResults: maxResults)
        case .oneDrive:
            return try await listOneDriveFiles(folderId: folderId, maxResults: maxResults)
        case .iCloudDrive:
            // iCloud Drive uses native file picker, not API
            return []
        }
    }
    
    // MARK: - Google Drive Integration
    
    private func listGoogleDriveFiles(folderId: String?, maxResults: Int) async throws -> [CloudFile] {
        let accessToken = try await oauthService.getValidToken(for: .googleDrive)
        
        var urlComponents = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "pageSize", value: "\(maxResults)"),
            URLQueryItem(name: "fields", value: "files(id,name,mimeType,size,modifiedTime,parents,thumbnailLink)")
        ]
        
        if let folderId = folderId {
            queryItems.append(URLQueryItem(name: "q", value: "'\(folderId)' in parents"))
        } else {
            queryItems.append(URLQueryItem(name: "q", value: "'root' in parents"))
        }
        
        urlComponents.queryItems = queryItems
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GoogleDriveListResponse.self, from: data)
        
        let files = response.files.map { file in
            CloudFile(
                id: file.id,
                name: file.name,
                mimeType: file.mimeType,
                size: file.size.map { Int64($0) },
                modifiedDate: parseISO8601Date(file.modifiedTime),
                isFolder: file.mimeType == "application/vnd.google-apps.folder",
                parentId: file.parents?.first,
                downloadUrl: nil,
                thumbnailUrl: file.thumbnailLink
            )
        }
        
        fetchedFiles = files
        return files
    }
    
    // MARK: - Dropbox Integration
    
    private func listDropboxFiles(folderId: String?, maxResults: Int) async throws -> [CloudFile] {
        let accessToken = try await oauthService.getValidToken(for: .dropbox)
        
        let path = folderId ?? ""
        let requestBody = ["path": path]
        
        var request = URLRequest(url: URL(string: "https://api.dropboxapi.com/2/files/list_folder")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(DropboxListResponse.self, from: data)
        
        let files = response.entries.map { entry in
            CloudFile(
                id: entry.id,
                name: entry.name,
                mimeType: entry.contentHash != nil ? determineMimeType(from: entry.name) : "application/vnd.dropbox.folder",
                size: entry.size.map { Int64($0) },
                modifiedDate: parseDropboxDate(entry.serverModified),
                isFolder: entry.tag == ".folder",
                parentId: folderId,
                downloadUrl: nil,
                thumbnailUrl: nil
            )
        }
        
        fetchedFiles = files
        return files
    }
    
    // MARK: - OneDrive Integration
    
    private func listOneDriveFiles(folderId: String?, maxResults: Int) async throws -> [CloudFile] {
        let accessToken = try await oauthService.getValidToken(for: .oneDrive)
        
        let path = folderId != nil ? "/items/\(folderId!)/children" : "/me/drive/root/children"
        var urlComponents = URLComponents(string: "https://graph.microsoft.com/v1.0\(path)")!
        urlComponents.queryItems = [
            URLQueryItem(name: "$top", value: "\(maxResults)")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OneDriveListResponse.self, from: data)
        
        let files = response.value.map { item in
            CloudFile(
                id: item.id,
                name: item.name,
                mimeType: item.file?.mimeType,
                size: item.size.map { Int64($0) },
                modifiedDate: parseISO8601Date(item.lastModifiedDateTime),
                isFolder: item.folder != nil,
                parentId: item.parentReference?.id,
                downloadUrl: item.downloadUrl,
                thumbnailUrl: nil
            )
        }
        
        fetchedFiles = files
        return files
    }
    
    // MARK: - File Download
    
    /// Download file from cloud storage
    func downloadFile(
        provider: CloudStorageProvider,
        file: CloudFile
    ) async throws -> Data {
        let accessToken: String?
        
        switch provider {
        case .googleDrive:
            accessToken = try? await oauthService.getValidToken(for: .googleDrive)
        case .dropbox:
            accessToken = try? await oauthService.getValidToken(for: .dropbox)
        case .oneDrive:
            accessToken = try? await oauthService.getValidToken(for: .oneDrive)
        case .iCloudDrive:
            accessToken = nil // iCloud Drive uses native file picker
        }
        
        switch provider {
        case .googleDrive:
            return try await downloadGoogleDriveFile(fileId: file.id, accessToken: accessToken!)
        case .dropbox:
            return try await downloadDropboxFile(fileId: file.id, accessToken: accessToken!)
        case .oneDrive:
            if let downloadUrl = file.downloadUrl {
                return try await downloadOneDriveFile(downloadUrl: downloadUrl, accessToken: accessToken!)
            } else {
                return try await downloadOneDriveFile(fileId: file.id, accessToken: accessToken!)
            }
        case .iCloudDrive:
            throw CloudStorageError.invalidProvider // Use native file picker instead
        }
    }
    
    private func downloadGoogleDriveFile(fileId: String, accessToken: String) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    private func downloadDropboxFile(fileId: String, accessToken: String) async throws -> Data {
        // Dropbox uses path, not ID for download
        var request = URLRequest(url: URL(string: "https://content.dropboxapi.com/2/files/download")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("{\"path\":\"\(fileId)\"}", forHTTPHeaderField: "Dropbox-API-Arg")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    private func downloadOneDriveFile(downloadUrl: String, accessToken: String) async throws -> Data {
        var request = URLRequest(url: URL(string: downloadUrl)!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    private func downloadOneDriveFile(fileId: String, accessToken: String) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://graph.microsoft.com/v1.0/me/drive/items/\(fileId)/content")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    // MARK: - Helpers
    
    private func parseISO8601Date(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? formatter.date(from: dateString.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression))
    }
    
    private func parseDropboxDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: dateString)
    }
    
    private func determineMimeType(from filename: String) -> String {
        let pathExtension = (filename as NSString).pathExtension.lowercased()
        if let uti = UTType(filenameExtension: pathExtension),
           let mimeType = uti.preferredMIMEType {
            return mimeType
        }
        return "application/octet-stream"
    }
}

// MARK: - Google Drive API Response Models

private struct GoogleDriveListResponse: Codable {
    let files: [GoogleDriveFile]
}

private struct GoogleDriveFile: Codable {
    let id: String
    let name: String
    let mimeType: String?
    let size: Int?
    let modifiedTime: String
    let parents: [String]?
    let thumbnailLink: String?
}

// MARK: - Dropbox API Response Models

private struct DropboxListResponse: Codable {
    let entries: [DropboxEntry]
}

private struct DropboxEntry: Codable {
    let id: String
    let name: String
    let tag: String
    let size: Int?
    let serverModified: String
    let contentHash: String?
}

// MARK: - OneDrive API Response Models

private struct OneDriveListResponse: Codable {
    let value: [OneDriveItem]
}

private struct OneDriveItem: Codable {
    let id: String
    let name: String
    let size: Int?
    let lastModifiedDateTime: String
    let file: OneDriveFile?
    let folder: OneDriveFolder?
    let parentReference: OneDriveParentReference?
    let downloadUrl: String?
}

private struct OneDriveFile: Codable {
    let mimeType: String?
}

private struct OneDriveFolder: Codable {
    let childCount: Int?
}

private struct OneDriveParentReference: Codable {
    let id: String?
}

