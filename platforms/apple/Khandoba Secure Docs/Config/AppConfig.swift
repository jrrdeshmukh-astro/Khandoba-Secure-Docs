//
//  AppConfig.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import Combine

struct AppConfig {
    // PRODUCTION MODE - Real Apple Sign In required
    static let isDevelopmentMode = false
    
    // App Information
    static let appVersion = "1.0.1"
    static let appBuildNumber = "30"
    static let appName = "Khandoba Secure Docs"
    
    // Production Configuration
    // Note: Supabase is used for platform-agnostic vault access (web, iOS, Android, etc.)
    // CloudKit is available as fallback for iOS-only features
    static let cloudKitContainer = "iCloud.com.khandoba.securedocs"
    
    // CloudKit API Configuration (fallback for iOS-only features)
    static let cloudKitKeyID = "PR62QK662L"
    static let cloudKitTeamID = "Q5Y8754WU4"
    static let cloudKitKeyPath = "AuthKey_PR62QK662L.p8" // Relative to project root
    
    // Supabase Configuration
    // Production Supabase project configured for platform-agnostic access
    // Set to true to use Supabase (enables web, iOS, Android, and other platform access)
    // Set to false to use CloudKit/SwiftData (iOS-only, Apple's managed service)
    static let useSupabase = true // Feature flag to switch between CloudKit and Supabase
    static let supabaseURL = SupabaseConfig.currentEnvironment.supabaseURL
    static let supabaseAnonKey = SupabaseConfig.currentEnvironment.supabaseAnonKey
    
    // Feature Flags
    static let enableAnalytics = true
    static let enableCrashReporting = true
    static let enablePushNotifications = true
    
    // Security
    static let requireBiometricAuth = true
    static let sessionTimeoutMinutes = 30
    static let maxLoginAttempts = 5
    
    // Development user credentials (only used if isDevelopmentMode = true)
    static let devUserID = "dev-user-123"
    static let devUserName = "Developer User"
    static let devUserEmail = "dev@khandoba.local"
    
    // Admin role removed - autopilot mode (ML handles everything)
    
    // App Group Identifier (must match extension)
    static let appGroupIdentifier = "group.com.khandoba.securedocs"
}
