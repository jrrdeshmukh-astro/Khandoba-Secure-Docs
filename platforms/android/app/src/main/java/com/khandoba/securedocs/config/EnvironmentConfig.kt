package com.khandoba.securedocs.config

import android.content.Context
import android.content.res.Resources

enum class Environment {
    DEV,
    TEST,
    PROD
}

object EnvironmentConfig {
    private fun getEnvironment(context: Context): Environment {
        val packageName = context.packageName
        return when {
            packageName.endsWith(".dev") -> Environment.DEV
            packageName.endsWith(".test") -> Environment.TEST
            else -> Environment.PROD
        }
    }
    
    fun current(context: Context): Environment = getEnvironment(context)
    
    fun isDevelopment(context: Context): Boolean = current(context) == Environment.DEV
    fun isTest(context: Context): Boolean = current(context) == Environment.TEST
    fun isProduction(context: Context): Boolean = current(context) == Environment.PROD
    
    fun getSupabaseUrl(context: Context): String {
        val resources = context.resources
        val identifier = resources.getIdentifier("supabase_url", "string", context.packageName)
        return if (identifier != 0) {
            resources.getString(identifier)
        } else {
            AppConfig.SUPABASE_URL
        }
    }
    
    fun getSupabaseAnonKey(context: Context): String {
        val resources = context.resources
        val identifier = resources.getIdentifier("supabase_anon_key", "string", context.packageName)
        return if (identifier != 0) {
            resources.getString(identifier)
        } else {
            AppConfig.SUPABASE_ANON_KEY
        }
    }
    
    fun isLoggingEnabled(context: Context): Boolean {
        val resources = context.resources
        val identifier = resources.getIdentifier("enable_logging", "bool", context.packageName)
        return if (identifier != 0) {
            resources.getBoolean(identifier)
        } else {
            !isProduction(context)
        }
    }
    
    fun isAnalyticsEnabled(context: Context): Boolean {
        val resources = context.resources
        val identifier = resources.getIdentifier("enable_analytics", "bool", context.packageName)
        return if (identifier != 0) {
            resources.getBoolean(identifier)
        } else {
            isProduction(context) || isTest(context)
        }
    }
    
    fun isCrashReportingEnabled(context: Context): Boolean {
        val resources = context.resources
        val identifier = resources.getIdentifier("enable_crash_reporting", "bool", context.packageName)
        return if (identifier != 0) {
            resources.getBoolean(identifier)
        } else {
            isProduction(context) || isTest(context)
        }
    }
    
    fun shouldRequireBiometricAuth(context: Context): Boolean {
        val resources = context.resources
        val identifier = resources.getIdentifier("require_biometric_auth", "bool", context.packageName)
        return if (identifier != 0) {
            resources.getBoolean(identifier)
        } else {
            isProduction(context) || isTest(context)
        }
    }
    
    fun getSessionTimeoutMinutes(context: Context): Int {
        val resources = context.resources
        val identifier = resources.getIdentifier("session_timeout_minutes", "integer", context.packageName)
        return if (identifier != 0) {
            resources.getInteger(identifier)
        } else {
            AppConfig.SESSION_TIMEOUT_MINUTES
        }
    }
}
