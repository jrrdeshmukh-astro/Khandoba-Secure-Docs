//
//  EmailIntegrationService.swift
//  Khandoba Secure Docs
//
//  Email integration service for Gmail and Outlook
//

import Foundation
import SwiftData
import Combine
import MessageUI

/// Email provider types
enum EmailProvider: String, CaseIterable {
    case gmail = "gmail"
    case outlook = "outlook"
    case imap = "imap"
    
    var displayName: String {
        switch self {
        case .gmail: return "Gmail"
        case .outlook: return "Outlook"
        case .imap: return "IMAP"
        }
    }
}

/// Email message structure
struct EmailMessage: Identifiable, Codable {
    let id: String
    let subject: String
    let from: String
    let to: [String]
    let date: Date
    let body: String
    let snippet: String?
    let attachments: [EmailAttachment]
    let threadId: String?
    let labels: [String]?
}

/// Email attachment structure
struct EmailAttachment: Identifiable, Codable {
    let id: String
    let filename: String
    let mimeType: String
    let size: Int64
    let attachmentId: String // Provider-specific attachment ID
}

/// Email filter options
struct EmailFilter: Codable {
    var folders: [String] = []
    var dateRange: DateRange?
    var sender: String?
    var subject: String?
    var hasAttachments: Bool?
    
    struct DateRange: Codable {
        let start: Date
        let end: Date
    }
}

/// Email integration errors
enum EmailIntegrationError: LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case fetchFailed
    case attachmentDownloadFailed
    case invalidProvider
    case filterError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Email account is not authenticated. Please connect your account first."
        case .authenticationFailed:
            return "Failed to authenticate with email provider."
        case .fetchFailed:
            return "Failed to fetch emails from provider."
        case .attachmentDownloadFailed:
            return "Failed to download email attachment."
        case .invalidProvider:
            return "Invalid email provider specified."
        case .filterError:
            return "Error applying email filter."
        }
    }
}

@MainActor
final class EmailIntegrationService: ObservableObject {
    static let shared = EmailIntegrationService()
    
    @Published var connectedProviders: Set<EmailProvider> = []
    @Published var isFetching = false
    @Published var fetchedEmails: [EmailMessage] = []
    
    private let oauthService = OAuthService.shared
    private var modelContext: ModelContext?
    
    private init() {
        // Only iCloud Mail is supported - always available
        // iCloud Mail uses native iOS Mail framework, no OAuth needed
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Authentication
    
    /// Connect email provider using OAuth
    func connectProvider(_ provider: EmailProvider) async throws {
        switch provider {
        case .gmail:
            _ = try await oauthService.authenticate(provider: .gmail)
        case .outlook:
            _ = try await oauthService.authenticate(provider: .outlook)
        case .imap:
            throw EmailIntegrationError.invalidProvider // IMAP requires manual configuration
        }
        
        connectedProviders.insert(provider)
    }
    
    /// Disconnect email provider
    func disconnectProvider(_ provider: EmailProvider) throws {
        switch provider {
        case .gmail:
            try oauthService.disconnect(provider: .gmail)
        case .outlook:
            try oauthService.disconnect(provider: .outlook)
        case .imap:
            break // IMAP doesn't use OAuth
        }
        
        connectedProviders.remove(provider)
    }
    
    // Only iCloud Mail is supported - uses native iOS Mail framework
    // No OAuth providers needed
    
    // MARK: - Email Fetching
    
    /// Fetch emails from provider with optional filter
    func fetchEmails(
        from provider: EmailProvider,
        maxResults: Int = 50,
        filter: EmailFilter? = nil
    ) async throws -> [EmailMessage] {
        guard connectedProviders.contains(provider) else {
            throw EmailIntegrationError.notAuthenticated
        }
        
        isFetching = true
        defer { isFetching = false }
        
        switch provider {
        case .gmail:
            return try await fetchGmailEmails(maxResults: maxResults, filter: filter)
        case .outlook:
            return try await fetchOutlookEmails(maxResults: maxResults, filter: filter)
        case .imap:
            throw EmailIntegrationError.invalidProvider // IMAP not yet implemented
        }
    }
    
    // MARK: - Gmail Integration
    
    private func fetchGmailEmails(
        maxResults: Int,
        filter: EmailFilter?
    ) async throws -> [EmailMessage] {
        let accessToken = try await oauthService.getValidToken(for: .gmail)
        
        // Build Gmail query
        var query = ""
        if let filter = filter {
            var queryParts: [String] = []
            
            if let sender = filter.sender {
                queryParts.append("from:\(sender)")
            }
            if let subject = filter.subject {
                queryParts.append("subject:\(subject)")
            }
            if filter.hasAttachments == true {
                queryParts.append("has:attachment")
            }
            if let dateRange = filter.dateRange {
                let startTimestamp = Int(dateRange.start.timeIntervalSince1970)
                let endTimestamp = Int(dateRange.end.timeIntervalSince1970)
                queryParts.append("after:\(startTimestamp) before:\(endTimestamp)")
            }
            if !filter.folders.isEmpty {
                // Gmail uses labels, map folders to labels
                for folder in filter.folders {
                    queryParts.append("label:\(folder)")
                }
            }
            
            query = queryParts.joined(separator: " ")
        }
        
        // Fetch message list
        var request = URLRequest(url: URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=\(maxResults)&\(query.isEmpty ? "" : "q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (listData, _) = try await URLSession.shared.data(for: request)
        let listResponse = try JSONDecoder().decode(GmailListResponse.self, from: listData)
        
        // Fetch full message details
        var emails: [EmailMessage] = []
        for messageRef in listResponse.messages.prefix(maxResults) {
            if let email = try await fetchGmailMessage(id: messageRef.id, accessToken: accessToken) {
                emails.append(email)
            }
        }
        
        fetchedEmails = emails
        return emails
    }
    
    private func fetchGmailMessage(id: String, accessToken: String) async throws -> EmailMessage? {
        var request = URLRequest(url: URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(id)")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let messageResponse = try JSONDecoder().decode(GmailMessageResponse.self, from: data)
        
        let headers = messageResponse.payload.headers
        let subject = headers.first(where: { $0.name.lowercased() == "subject" })?.value ?? "No Subject"
        let from = headers.first(where: { $0.name.lowercased() == "from" })?.value ?? "Unknown"
        let to = headers.first(where: { $0.name.lowercased() == "to" })?.value ?? ""
        let dateString = headers.first(where: { $0.name.lowercased() == "date" })?.value ?? ""
        let date = parseEmailDate(dateString) ?? Date()
        
        // Extract body
        let body = extractGmailBody(from: messageResponse.payload)
        
        // Extract attachments
        let attachments = extractGmailAttachments(from: messageResponse.payload)
        
        return EmailMessage(
            id: messageResponse.id,
            subject: subject,
            from: from,
            to: to.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            date: date,
            body: body,
            snippet: messageResponse.snippet,
            attachments: attachments,
            threadId: messageResponse.threadId,
            labels: messageResponse.labelIds
        )
    }
    
    private func extractGmailBody(from payload: GmailPayload) -> String {
        if let body = payload.body, let data = body.data {
            return decodeBase64URL(data) ?? ""
        }
        
        if let parts = payload.parts {
            for part in parts {
                if part.mimeType == "text/plain", let data = part.body?.data {
                    return decodeBase64URL(data) ?? ""
                }
            }
            
            // Fallback to HTML
            for part in parts {
                if part.mimeType == "text/html", let data = part.body?.data {
                    return decodeBase64URL(data) ?? ""
                }
            }
        }
        
        return ""
    }
    
    private func extractGmailAttachments(from payload: GmailPayload) -> [EmailAttachment] {
        var attachments: [EmailAttachment] = []
        
        func extractFromParts(_ parts: [GmailPart]?) {
            guard let parts = parts else { return }
            
            for part in parts {
                if let filename = part.filename, !filename.isEmpty,
                   let attachmentId = part.body?.attachmentId,
                   let size = part.body?.size {
                    attachments.append(EmailAttachment(
                        id: attachmentId,
                        filename: filename,
                        mimeType: part.mimeType ?? "application/octet-stream",
                        size: Int64(size),
                        attachmentId: attachmentId
                    ))
                }
                
                // Recursively check nested parts
                if let nestedParts = part.parts {
                    extractFromParts(nestedParts)
                }
            }
        }
        
        extractFromParts(payload.parts)
        return attachments
    }
    
    // MARK: - Outlook Integration
    
    private func fetchOutlookEmails(
        maxResults: Int,
        filter: EmailFilter?
    ) async throws -> [EmailMessage] {
        let accessToken = try await oauthService.getValidToken(for: .outlook)
        
        // Build Microsoft Graph API URL
        var urlComponents = URLComponents(string: "https://graph.microsoft.com/v1.0/me/messages")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "$top", value: "\(maxResults)")
        ]
        
        if let filter = filter {
            var filterParts: [String] = []
            
            if let sender = filter.sender {
                filterParts.append("from/emailAddress/address eq '\(sender)'")
            }
            if let subject = filter.subject {
                filterParts.append("contains(subject, '\(subject)')")
            }
            if filter.hasAttachments == true {
                filterParts.append("hasAttachments eq true")
            }
            if let dateRange = filter.dateRange {
                let startISO = ISO8601DateFormatter().string(from: dateRange.start)
                let endISO = ISO8601DateFormatter().string(from: dateRange.end)
                filterParts.append("receivedDateTime ge \(startISO) and receivedDateTime le \(endISO)")
            }
            
            if !filterParts.isEmpty {
                queryItems.append(URLQueryItem(name: "$filter", value: filterParts.joined(separator: " and ")))
            }
            
            if !filter.folders.isEmpty {
                // Outlook uses mail folders
                queryItems.append(URLQueryItem(name: "$expand", value: "parentFolder"))
            }
        }
        
        queryItems.append(URLQueryItem(name: "$orderby", value: "receivedDateTime desc"))
        urlComponents.queryItems = queryItems
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let graphResponse = try JSONDecoder().decode(OutlookMessagesResponse.self, from: data)
        
        let emails = graphResponse.value.map { message in
            EmailMessage(
                id: message.id,
                subject: message.subject ?? "No Subject",
                from: message.from?.emailAddress.address ?? "Unknown",
                to: message.toRecipients?.map { $0.emailAddress.address } ?? [],
                date: parseISO8601Date(message.receivedDateTime) ?? Date(),
                body: message.body?.content ?? "",
                snippet: message.bodyPreview,
                attachments: message.hasAttachments == true ? [] : [], // Would need separate API call to fetch attachments
                threadId: message.conversationId,
                labels: nil
            )
        }
        
        fetchedEmails = emails
        return emails
    }
    
    // MARK: - Attachment Download
    
    /// Download email attachment
    func downloadAttachment(
        from provider: EmailProvider,
        messageId: String,
        attachment: EmailAttachment
    ) async throws -> Data {
        let accessToken = try await oauthService.getValidToken(for: provider == .gmail ? .gmail : .outlook)
        
        switch provider {
        case .gmail:
            return try await downloadGmailAttachment(
                messageId: messageId,
                attachmentId: attachment.attachmentId,
                accessToken: accessToken
            )
        case .outlook:
            return try await downloadOutlookAttachment(
                messageId: messageId,
                attachmentId: attachment.attachmentId,
                accessToken: accessToken
            )
        case .imap:
            throw EmailIntegrationError.invalidProvider
        }
    }
    
    private func downloadGmailAttachment(
        messageId: String,
        attachmentId: String,
        accessToken: String
    ) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(messageId)/attachments/\(attachmentId)")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GmailAttachmentResponse.self, from: data)
        
        guard let attachmentData = Data(base64Encoded: response.data) else {
            throw EmailIntegrationError.attachmentDownloadFailed
        }
        
        return attachmentData
    }
    
    private func downloadOutlookAttachment(
        messageId: String,
        attachmentId: String,
        accessToken: String
    ) async throws -> Data {
        var request = URLRequest(url: URL(string: "https://graph.microsoft.com/v1.0/me/messages/\(messageId)/attachments/\(attachmentId)/$value")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    // MARK: - Ingestion to Vault
    
    /// Ingest email attachments into vault
    func ingestAttachmentsToVault(
        email: EmailMessage,
        vault: Vault,
        documentService: DocumentService
    ) async throws {
        guard let modelContext = modelContext else {
            throw EmailIntegrationError.fetchFailed
        }
        
        for attachment in email.attachments {
            do {
                let data = try await downloadAttachment(
                    from: email.from.contains("gmail") ? .gmail : .outlook,
                    messageId: email.id,
                    attachment: attachment
                )
                
                // Upload to vault
                _ = try await documentService.uploadDocument(
                    data: data,
                    name: attachment.filename,
                    mimeType: attachment.mimeType,
                    to: vault,
                    uploadMethod: .import
                )
            } catch {
                print("Failed to ingest attachment \(attachment.filename): \(error)")
                // Continue with other attachments
            }
        }
    }
    
    // MARK: - Helpers
    
    private func parseEmailDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
        return formatter.date(from: dateString)
    }
    
    private func parseISO8601Date(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? formatter.date(from: dateString.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression))
    }
    
    private func decodeBase64URL(_ base64URL: String) -> String? {
        var base64 = base64URL
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Gmail API Response Models

private struct GmailListResponse: Codable {
    let messages: [GmailMessageRef]
}

private struct GmailMessageRef: Codable {
    let id: String
    let threadId: String
}

private struct GmailMessageResponse: Codable {
    let id: String
    let threadId: String
    let snippet: String?
    let labelIds: [String]?
    let payload: GmailPayload
}

private struct GmailPayload: Codable {
    let headers: [GmailHeader]
    let body: GmailBody?
    let parts: [GmailPart]?
}

private struct GmailHeader: Codable {
    let name: String
    let value: String
}

private struct GmailBody: Codable {
    let data: String?
    let size: Int?
    let attachmentId: String?
}

private struct GmailPart: Codable {
    let mimeType: String?
    let filename: String?
    let body: GmailBody?
    let parts: [GmailPart]?
}

private struct GmailAttachmentResponse: Codable {
    let size: Int
    let data: String
}

// MARK: - Outlook API Response Models

private struct OutlookMessagesResponse: Codable {
    let value: [OutlookMessage]
}

private struct OutlookMessage: Codable {
    let id: String
    let subject: String?
    let from: OutlookRecipient?
    let toRecipients: [OutlookRecipient]?
    let receivedDateTime: String
    let body: OutlookBody?
    let bodyPreview: String?
    let hasAttachments: Bool?
    let conversationId: String?
}

private struct OutlookRecipient: Codable {
    let emailAddress: OutlookEmailAddress
}

private struct OutlookEmailAddress: Codable {
    let address: String
    let name: String?
}

private struct OutlookBody: Codable {
    let contentType: String
    let content: String
}

