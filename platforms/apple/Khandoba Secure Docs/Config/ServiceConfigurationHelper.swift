//
//  ServiceConfigurationHelper.swift
//  Khandoba Secure Docs
//
//  Helper utility to configure services with CloudKit/SwiftData
//  iOS-ONLY: All services use SwiftData with CloudKit sync
//

import Foundation
import SwiftData
import SwiftUI

/// Helper utility to configure services with CloudKit/SwiftData
/// iOS-ONLY: All services use SwiftData with CloudKit sync
struct ServiceConfigurationHelper {
    /// Configure NomineeService with SwiftData/CloudKit
    static func configureNomineeService(
        _ service: NomineeService,
        modelContext: ModelContext,
        userID: UUID? = nil
    ) {
        service.configure(modelContext: modelContext, currentUserID: userID)
    }
    
    /// Configure VaultService with SwiftData/CloudKit
    static func configureVaultService(
        _ service: VaultService,
        modelContext: ModelContext,
        userID: UUID
    ) {
        service.configure(modelContext: modelContext, userID: userID)
    }
    
    /// Configure DocumentService with SwiftData/CloudKit
    static func configureDocumentService(
        _ service: DocumentService,
        modelContext: ModelContext,
        userID: UUID? = nil
    ) {
        service.configure(modelContext: modelContext, userID: userID)
    }
    
    /// Configure ChatService with SwiftData/CloudKit
    static func configureChatService(
        _ service: ChatService,
        modelContext: ModelContext,
        userID: UUID
    ) {
        service.configure(modelContext: modelContext, userID: userID)
    }
    
    /// Configure AuthenticationService with SwiftData/CloudKit
    static func configureAuthenticationService(
        _ service: AuthenticationService,
        modelContext: ModelContext
    ) {
        service.configure(modelContext: modelContext)
    }
}
