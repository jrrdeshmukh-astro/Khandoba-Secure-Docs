//
//  OAuthServiceTests.swift
//  Khandoba Secure DocsTests
//
//  Comprehensive unit tests for OAuthService
//

import XCTest
import AuthenticationServices
@testable import Khandoba_Secure_Docs

@MainActor
final class OAuthServiceTests: XCTestCase {
    var oauthService: OAuthService!
    
    override func setUp() {
        super.setUp()
        oauthService = OAuthService.shared
    }
    
    override func tearDown() {
        oauthService = nil
        super.tearDown()
    }
    
    func testProviderDisplayNames() {
        XCTAssertEqual(OAuthProvider.gmail.displayName, "Gmail")
        XCTAssertEqual(OAuthProvider.googleDrive.displayName, "Google Drive")
        XCTAssertEqual(OAuthProvider.dropbox.displayName, "Dropbox")
        XCTAssertEqual(OAuthProvider.oneDrive.displayName, "OneDrive")
        XCTAssertEqual(OAuthProvider.outlook.displayName, "Outlook")
    }
    
    func testProviderAuthURLs() {
        XCTAssertTrue(OAuthProvider.gmail.authURL.contains("accounts.google.com"))
        XCTAssertTrue(OAuthProvider.dropbox.authURL.contains("dropbox.com"))
        XCTAssertTrue(OAuthProvider.oneDrive.authURL.contains("microsoftonline.com"))
    }
    
    func testProviderTokenURLs() {
        XCTAssertTrue(OAuthProvider.gmail.tokenURL.contains("oauth2.googleapis.com"))
        XCTAssertTrue(OAuthProvider.dropbox.tokenURL.contains("dropboxapi.com"))
        XCTAssertTrue(OAuthProvider.oneDrive.tokenURL.contains("microsoftonline.com"))
    }
    
    func testProviderScopes() {
        XCTAssertFalse(OAuthProvider.gmail.scopes.isEmpty)
        XCTAssertTrue(OAuthProvider.gmail.scopes.contains("https://www.googleapis.com/auth/gmail.readonly"))
        XCTAssertFalse(OAuthProvider.googleDrive.scopes.isEmpty)
        XCTAssertTrue(OAuthProvider.googleDrive.scopes.contains("https://www.googleapis.com/auth/drive.readonly"))
    }
    
    func testAllProvidersListed() {
        let allProviders = OAuthProvider.allCases
        XCTAssertEqual(allProviders.count, 5)
        XCTAssertTrue(allProviders.contains(.gmail))
        XCTAssertTrue(allProviders.contains(.googleDrive))
        XCTAssertTrue(allProviders.contains(.dropbox))
        XCTAssertTrue(allProviders.contains(.oneDrive))
        XCTAssertTrue(allProviders.contains(.outlook))
    }
    
    func testOAuthErrorDescriptions() {
        let errors: [OAuthError] = [
            .configurationMissing,
            .authenticationCancelled,
            .tokenExchangeFailed,
            .tokenRefreshFailed,
            .invalidState,
            .keychainError,
            .tokenNotFound
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
