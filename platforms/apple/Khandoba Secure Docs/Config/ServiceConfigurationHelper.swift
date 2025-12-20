//
//  ServiceConfigurationHelper.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation
import SwiftData
import SwiftUI

/// Helper utility to configure services based on backend mode (SwiftData/Supabase)
struct ServiceConfigurationHelper {
    /// Configure NomineeService based on backend mode
    static func configureNomineeService(
        _ service: NomineeService,
        modelContext: ModelContext?,
        supabaseService: SupabaseService?,
        userID: UUID? = nil
    ) {
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            service.configure(supabaseService: supabaseService, currentUserID: userID)
        } else if let modelContext = modelContext {
            service.configure(modelContext: modelContext, currentUserID: userID)
        }
    }
    
    /// Configure VaultService based on backend mode
    static func configureVaultService(
        _ service: VaultService,
        modelContext: ModelContext?,
        supabaseService: SupabaseService?,
        userID: UUID
    ) {
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            service.configure(supabaseService: supabaseService, userID: userID)
        } else if let modelContext = modelContext {
            service.configure(modelContext: modelContext, userID: userID)
        }
    }
    
    /// Configure DocumentService based on backend mode
    static func configureDocumentService(
        _ service: DocumentService,
        modelContext: ModelContext?,
        supabaseService: SupabaseService?,
        userID: UUID? = nil
    ) {
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            service.configure(supabaseService: supabaseService, userID: userID)
        } else if let modelContext = modelContext {
            service.configure(modelContext: modelContext, userID: userID)
        }
    }
    
    /// Configure ChatService based on backend mode
    static func configureChatService(
        _ service: ChatService,
        modelContext: ModelContext?,
        supabaseService: SupabaseService?,
        userID: UUID
    ) {
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            service.configure(supabaseService: supabaseService, userID: userID)
        } else if let modelContext = modelContext {
            service.configure(modelContext: modelContext, userID: userID)
        }
    }
}

/// View extension to easily access SupabaseService
extension View {
    /// Get SupabaseService from environment, or nil if not available
    func getSupabaseService() -> SupabaseService? {
        // This is a helper that views can use
        // In practice, views should use @EnvironmentObject var supabaseService: SupabaseService
        return nil // Placeholder - views should use @EnvironmentObject
    }
}
