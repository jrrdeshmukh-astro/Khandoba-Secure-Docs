//
//  EnvironmentConfig.swift
//  Khandoba Secure Docs
//
//  Environment-specific configuration based on build configuration
//

import Foundation

enum Environment: String {
    case development
    case test
    case production
    
    static var current: Environment {
        #if DEVELOPMENT
        return .development
        #elseif TEST
        return .test
        #else
        return .production
        #endif
    }
    
    var name: String {
        switch self {
        case .development: return "Development"
        case .test: return "Test"
        case .production: return "Production"
        }
    }
    
    var bundleIdentifier: String {
        switch self {
        case .development: return "com.khandoba.securedocs.dev"
        case .test: return "com.khandoba.securedocs.test"
        case .production: return "com.khandoba.securedocs"
        }
    }
    
    // iOS-ONLY: Using CloudKit exclusively - no Supabase configuration needed
    
    // Feature Flags
    var enableLogging: Bool {
        switch self {
        case .development, .test: return true
        case .production: return false
        }
    }
    
    var enableAnalytics: Bool {
        switch self {
        case .development: return false
        case .test, .production: return true
        }
    }
    
    var enableCrashReporting: Bool {
        switch self {
        case .development: return false
        case .test, .production: return true
        }
    }
    
    var enablePushNotifications: Bool {
        return true // Enabled for all environments
    }
    
    // Security Settings
    var sessionTimeoutMinutes: Int {
        switch self {
        case .development: return 60 // Longer timeout for dev
        case .test: return 30
        case .production: return 30
        }
    }
    
    var requireBiometricAuth: Bool {
        switch self {
        case .development: return false // Disable for easier testing
        case .test, .production: return true
        }
    }
}

struct EnvironmentConfig {
    static let current = Environment.current
    
    static var isDevelopment: Bool {
        current == .development
    }
    
    static var isTest: Bool {
        current == .test
    }
    
    static var isProduction: Bool {
        current == .production
    }
}
