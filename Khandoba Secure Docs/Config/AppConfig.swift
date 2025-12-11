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
    static let appVersion = "1.0"
    static let appBuildNumber = "22"
    static let appName = "Khandoba Secure Docs"
    
    // Production Configuration
    // Note: No custom API server needed - app uses CloudKit for all data sync
    // static let apiBaseURL = "https://api.khandoba.org" // Not used - CloudKit handles all sync
    static let cloudKitContainer = "iCloud.com.khandoba.securedocs"
    
    // CloudKit API Configuration
    static let cloudKitKeyID = "PR62QK662L"
    static let cloudKitTeamID = "Q5Y8754WU4"
    static let cloudKitKeyPath = "AuthKey_PR62QK662L.p8" // Relative to project root
    
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
}

