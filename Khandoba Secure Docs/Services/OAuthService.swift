//
//  OAuthService.swift
//  Khandoba Secure Docs
//
//  OAuth 2.0 service for external service integrations
//

import Foundation
import AuthenticationServices
import Security
import Combine

/// OAuth provider types
enum OAuthProvider: String, CaseIterable {
    case gmail = "gmail"
    case googleDrive = "google_drive"
    case dropbox = "dropbox"
    case oneDrive = "onedrive"
    case outlook = "outlook"
    
    var displayName: String {
        switch self {
        case .gmail: return "Gmail"
        case .googleDrive: return "Google Drive"
        case .dropbox: return "Dropbox"
        case .oneDrive: return "OneDrive"
        case .outlook: return "Outlook"
        }
    }
    
    var authURL: String {
        switch self {
        case .gmail, .googleDrive:
            return "https://accounts.google.com/o/oauth2/v2/auth"
        case .dropbox:
            return "https://www.dropbox.com/oauth2/authorize"
        case .oneDrive, .outlook:
            return "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
        }
    }
    
    var tokenURL: String {
        switch self {
        case .gmail, .googleDrive:
            return "https://oauth2.googleapis.com/token"
        case .dropbox:
            return "https://api.dropboxapi.com/oauth2/token"
        case .oneDrive, .outlook:
            return "https://login.microsoftonline.com/common/oauth2/v2.0/token"
        }
    }
    
    var scopes: [String] {
        switch self {
        case .gmail:
            return ["https://www.googleapis.com/auth/gmail.readonly"]
        case .googleDrive:
            return ["https://www.googleapis.com/auth/drive.readonly"]
        case .dropbox:
            return ["files.metadata.read", "files.content.read"]
        case .oneDrive:
            return ["Files.Read", "offline_access"]
        case .outlook:
            return ["Mail.Read", "offline_access"]
        }
    }
    
    var clientIDKey: String {
        switch self {
        case .gmail, .googleDrive:
            return "GOOGLE_CLIENT_ID"
        case .dropbox:
            return "DROPBOX_CLIENT_ID"
        case .oneDrive, .outlook:
            return "MICROSOFT_CLIENT_ID"
        }
    }
    
    var clientSecretKey: String {
        switch self {
        case .gmail, .googleDrive:
            return "GOOGLE_CLIENT_SECRET"
        case .dropbox:
            return "DROPBOX_CLIENT_SECRET"
        case .oneDrive, .outlook:
            return "MICROSOFT_CLIENT_SECRET"
        }
    }
}

/// OAuth token storage
struct OAuthTokens: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
    let tokenType: String?
    let scope: String?
}

/// OAuth errors
enum OAuthError: LocalizedError {
    case configurationMissing
    case authenticationCancelled
    case tokenExchangeFailed
    case tokenRefreshFailed
    case invalidState
    case keychainError
    case tokenNotFound
    
    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            return "OAuth configuration is missing. Please configure client ID and secret."
        case .authenticationCancelled:
            return "Authentication was cancelled."
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for token."
        case .tokenRefreshFailed:
            return "Failed to refresh access token."
        case .invalidState:
            return "Invalid OAuth state parameter."
        case .keychainError:
            return "Failed to store token in keychain."
        case .tokenNotFound:
            return "OAuth token not found."
        }
    }
}

@MainActor
final class OAuthService: NSObject, ObservableObject {
    static let shared = OAuthService()
    
    @Published var connectedAccounts: [OAuthProvider: OAuthTokens] = [:]
    @Published var isAuthenticating = false
    
    private var authenticationSession: ASWebAuthenticationSession?
    private var pendingCompletion: ((Result<OAuthTokens, Error>) -> Void)?
    private var pendingState: String?
    
    private let redirectScheme = "khandoba-oauth"
    private let keychainService = "com.khandoba.securedocs.oauth"
    
    private override init() {
        super.init()
        loadStoredTokens()
    }
    
    // MARK: - Configuration
    
    /// Get OAuth configuration from Info.plist or environment
    private func getConfiguration(for provider: OAuthProvider) -> (clientID: String, clientSecret: String)? {
        // Try to get from Info.plist first
        if let clientID = Bundle.main.object(forInfoDictionaryKey: provider.clientIDKey) as? String,
           let clientSecret = Bundle.main.object(forInfoDictionaryKey: provider.clientSecretKey) as? String {
            return (clientID, clientSecret)
        }
        
        // Fallback to environment variables (for development)
        if let clientID = ProcessInfo.processInfo.environment[provider.clientIDKey],
           let clientSecret = ProcessInfo.processInfo.environment[provider.clientSecretKey] {
            return (clientID, clientSecret)
        }
        
        return nil
    }
    
    // MARK: - Authentication Flow
    
    /// Start OAuth authentication flow
    func authenticate(provider: OAuthProvider) async throws -> OAuthTokens {
        guard let config = getConfiguration(for: provider) else {
            throw OAuthError.configurationMissing
        }
        
        // Check if already connected
        if let existingTokens = connectedAccounts[provider] {
            // Check if token is still valid
            if let expiresAt = existingTokens.expiresAt, expiresAt > Date() {
                return existingTokens
            }
            // Try to refresh
            if let refreshToken = existingTokens.refreshToken {
                do {
                    let refreshed = try await self.refreshToken(provider: provider, refreshToken: refreshToken)
                    return refreshed
                } catch {
                    // Refresh failed, need to re-authenticate
                }
            }
        }
        
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        // Generate state for CSRF protection
        let state = generateState()
        pendingState = state
        
        // Build authorization URL
        let redirectURI = "\(redirectScheme)://oauth/\(provider.rawValue)"
        var components = URLComponents(string: provider.authURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: provider.scopes.joined(separator: " ")),
        ]
        
        // Provider-specific parameters
        switch provider {
        case .gmail, .googleDrive:
            components.queryItems?.append(contentsOf: [
                URLQueryItem(name: "access_type", value: "offline"),
                URLQueryItem(name: "prompt", value: "consent")
            ])
        case .dropbox:
            components.queryItems?.append(URLQueryItem(name: "token_access_type", value: "offline"))
        case .oneDrive, .outlook:
            // Microsoft uses default parameters
            break
        }
        
        guard let authURL = components.url else {
            throw OAuthError.configurationMissing
        }
        
        // Start authentication session
        return try await withCheckedThrowingContinuation { continuation in
            pendingCompletion = { result in
                continuation.resume(with: result)
            }
            
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: redirectScheme
            ) { [weak self] callbackURL, error in
                Task { @MainActor in
                    if let error = error {
                        if let authError = error as? ASWebAuthenticationSessionError,
                           authError.code == .canceledLogin {
                            self?.pendingCompletion?(.failure(OAuthError.authenticationCancelled))
                        } else {
                            self?.pendingCompletion?(.failure(error))
                        }
                        return
                    }
                    
                    guard let callbackURL = callbackURL,
                          let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                          let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
                          let state = components.queryItems?.first(where: { $0.name == "state" })?.value,
                          state == self?.pendingState else {
                        self?.pendingCompletion?(.failure(OAuthError.invalidState))
                        return
                    }
                    
                    // Exchange code for token
                    do {
                        let tokens = try await self?.exchangeCodeForToken(
                            provider: provider,
                            code: code,
                            redirectURI: redirectURI
                        )
                        if let tokens = tokens {
                            try await self?.storeTokens(provider: provider, tokens: tokens)
                            self?.connectedAccounts[provider] = tokens
                            self?.pendingCompletion?(.success(tokens))
                        } else {
                            self?.pendingCompletion?(.failure(OAuthError.tokenExchangeFailed))
                        }
                    } catch {
                        self?.pendingCompletion?(.failure(error))
                    }
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            
            self.authenticationSession = session
            session.start()
        }
    }
    
    // MARK: - Token Exchange
    
    /// Exchange authorization code for access token
    private func exchangeCodeForToken(
        provider: OAuthProvider,
        code: String,
        redirectURI: String
    ) async throws -> OAuthTokens {
        guard let config = getConfiguration(for: provider) else {
            throw OAuthError.configurationMissing
        }
        
        var request = URLRequest(url: URL(string: provider.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "client_secret", value: config.clientSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OAuthError.tokenExchangeFailed
        }
        
        let json = try JSONDecoder().decode([String: AnyCodable].self, from: data)
        
        let accessToken = json["access_token"]?.stringValue ?? ""
        let refreshToken = json["refresh_token"]?.stringValue
        let expiresIn = json["expires_in"]?.doubleValue
        let expiresAt = expiresIn.map { Date(timeIntervalSinceNow: $0) }
        let tokenType = json["token_type"]?.stringValue
        let scope = json["scope"]?.stringValue
        
        return OAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            tokenType: tokenType,
            scope: scope
        )
    }
    
    // MARK: - Token Refresh
    
    /// Refresh access token using refresh token
    func refreshToken(provider: OAuthProvider, refreshToken: String) async throws -> OAuthTokens {
        guard let config = getConfiguration(for: provider) else {
            throw OAuthError.configurationMissing
        }
        
        var request = URLRequest(url: URL(string: provider.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "client_secret", value: config.clientSecret),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "grant_type", value: "refresh_token")
        ]
        
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OAuthError.tokenRefreshFailed
        }
        
        let json = try JSONDecoder().decode([String: AnyCodable].self, from: data)
        
        let accessToken = json["access_token"]?.stringValue ?? ""
        let newRefreshToken = json["refresh_token"]?.stringValue ?? refreshToken
        let expiresIn = json["expires_in"]?.doubleValue
        let expiresAt = expiresIn.map { Date(timeIntervalSinceNow: $0) }
        let tokenType = json["token_type"]?.stringValue
        let scope = json["scope"]?.stringValue
        
        let tokens = OAuthTokens(
            accessToken: accessToken,
            refreshToken: newRefreshToken,
            expiresAt: expiresAt,
            tokenType: tokenType,
            scope: scope
        )
        
        try await storeTokens(provider: provider, tokens: tokens)
        connectedAccounts[provider] = tokens
        
        return tokens
    }
    
    // MARK: - Token Management
    
    /// Get valid access token (refreshes if needed)
    func getValidToken(for provider: OAuthProvider) async throws -> String {
        guard var tokens = connectedAccounts[provider] else {
            throw OAuthError.tokenNotFound
        }
        
        // Check if token needs refresh
        if let expiresAt = tokens.expiresAt, expiresAt <= Date() {
            guard let refreshToken = tokens.refreshToken else {
                throw OAuthError.tokenNotFound
            }
            tokens = try await self.refreshToken(provider: provider, refreshToken: refreshToken)
        }
        
        return tokens.accessToken
    }
    
    /// Disconnect OAuth account
    func disconnect(provider: OAuthProvider) throws {
        connectedAccounts.removeValue(forKey: provider)
        try deleteStoredTokens(for: provider)
    }
    
    // MARK: - Keychain Storage
    
    private func storeTokens(provider: OAuthProvider, tokens: OAuthTokens) throws {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(tokens) else {
            throw OAuthError.keychainError
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: provider.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing
        SecItemDelete(query as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw OAuthError.keychainError
        }
    }
    
    private func loadStoredTokens() {
        for provider in OAuthProvider.allCases {
            if let tokens = try? retrieveStoredTokens(for: provider) {
                connectedAccounts[provider] = tokens
            }
        }
    }
    
    private func retrieveStoredTokens(for provider: OAuthProvider) throws -> OAuthTokens {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: provider.rawValue,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw OAuthError.tokenNotFound
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(OAuthTokens.self, from: data)
    }
    
    private func deleteStoredTokens(for provider: OAuthProvider) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: provider.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw OAuthError.keychainError
        }
    }
    
    // MARK: - Helpers
    
    private func generateState() -> String {
        let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for OAuth presentation")
        }
        return window
    }
}

// MARK: - AnyCodable Helper

private struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    var stringValue: String? {
        value as? String
    }
    
    var doubleValue: Double? {
        if let double = value as? Double {
            return double
        }
        if let int = value as? Int {
            return Double(int)
        }
        return nil
    }
}

