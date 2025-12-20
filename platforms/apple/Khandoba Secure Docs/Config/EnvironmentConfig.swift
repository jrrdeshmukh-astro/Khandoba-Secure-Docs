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
    
    // Supabase Configuration
    // Note: For production, uses SupabaseConfig. For dev/test, use separate Supabase projects if needed
    var supabaseURL: String {
        switch self {
        case .development:
            // Use same URL as production for now (can be changed to separate dev project)
            return SupabaseConfig.supabaseURL
        case .test:
            // Use same URL as production for now (can be changed to separate test project)
            return SupabaseConfig.supabaseURL
        case .production:
            return SupabaseConfig.supabaseURL
        }
    }
    
    var supabaseAnonKey: String {
        switch self {
        case .development:
            // Use production key for now (replace with dev key if using separate dev project)
            return SupabaseConfig.supabaseAnonKey
        case .test:
            // Use production key for now (replace with test key if using separate test project)
            return SupabaseConfig.supabaseAnonKey
        case .production:
            return SupabaseConfig.supabaseAnonKey
        }
    }
    
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
