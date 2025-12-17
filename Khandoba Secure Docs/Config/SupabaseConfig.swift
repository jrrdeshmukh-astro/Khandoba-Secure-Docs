//
//  SupabaseConfig.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseConfig {
    // Supabase Project Configuration
    // TODO: Update anon key and service role key for the new project
    static let supabaseURL = "https://uremtyiorzlapwthjsko.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVyZW10eWlvcnpsYXB3dGhqc2tvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5NjI3MDcsImV4cCI6MjA4MTUzODcwN30.P4Yg4Gl040Msv0TeRuHQ-_SuGfeNEHCV234W5TTSN7Y"
    static let supabaseServiceRoleKey = "YOUR_NEW_SERVICE_ROLE_KEY_HERE" // TODO: Replace with service role key from new project
    
    // Environment Configuration
    enum Environment {
        case development
        case production
        
        var supabaseURL: String {
            switch self {
            case .development:
                return "https://uremtyiorzlapwthjsko.supabase.co"
            case .production:
                return SupabaseConfig.supabaseURL
            }
        }
        
        var supabaseAnonKey: String {
            switch self {
            case .development:
                return SupabaseConfig.supabaseAnonKey
            case .production:
                return SupabaseConfig.supabaseAnonKey
            }
        }
    }
    
    // Current environment (can be changed based on build configuration)
    static var currentEnvironment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    // Storage Bucket Configuration
    static let encryptedDocumentsBucket = "encrypted-documents"
    static let voiceMemosBucket = "voice-memos"
    static let intelReportsBucket = "intel-reports"
    
    // Real-time Configuration
    static let enableRealtime = true
    static let realtimeChannels = [
        "vaults",
        "documents",
        "nominees",
        "chat_messages",
        "vault_sessions"
    ]
    
    // Database Configuration
    static let defaultPageSize = 50
    static let maxRetryAttempts = 3
    static let requestTimeout: TimeInterval = 30.0
}
