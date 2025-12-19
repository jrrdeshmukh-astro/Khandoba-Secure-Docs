package com.khandoba.securedocs.config

object AppConfig {
    // App Information
    const val APP_VERSION = "1.0.1"
    const val APP_BUILD_NUMBER = 30
    const val APP_NAME = "Khandoba Secure Docs"
    
    // Backend Configuration
    // Using same Supabase database as iOS app for cross-platform sync
    const val USE_SUPABASE = true // Set to true to use Supabase (same DB as iOS)
    const val SUPABASE_URL = "https://uremtyiorzlapwthjsko.supabase.co"
    const val SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVyZW10eWlvcnpsYXB3dGhqc2tvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5NjI3MDcsImV4cCI6MjA4MTUzODcwN30.P4Yg4Gl040Msv0TeRuHQ-_SuGfeNEHCV234W5TTSN7Y"
    
    // Supabase Storage Buckets (same as iOS)
    const val ENCRYPTED_DOCUMENTS_BUCKET = "encrypted-documents"
    const val VOICE_MEMOS_BUCKET = "voice-memos"
    const val INTEL_REPORTS_BUCKET = "intel-reports"
    
    // Real-time Configuration
    const val ENABLE_REALTIME = true
    
    // Firebase Configuration (if not using Supabase)
    const val FIREBASE_PROJECT_ID = "khandoba-secure-docs"
    
    // Feature Flags
    const val ENABLE_ANALYTICS = true
    const val ENABLE_CRASH_REPORTING = true
    const val ENABLE_PUSH_NOTIFICATIONS = true
    
    // Security
    const val REQUIRE_BIOMETRIC_AUTH = true
    const val SESSION_TIMEOUT_MINUTES = 30
    const val MAX_LOGIN_ATTEMPTS = 5
    
    // App Group/Shared Preferences
    const val SHARED_PREFS_NAME = "khandoba_secure_docs_prefs"
    const val PERMISSIONS_SETUP_COMPLETE_KEY = "permissions_setup_complete"
}
