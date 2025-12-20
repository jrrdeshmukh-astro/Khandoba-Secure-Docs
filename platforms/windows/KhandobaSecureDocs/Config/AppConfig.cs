namespace KhandobaSecureDocs.Config
{
    public static class AppConfig
    {
        // PRODUCTION MODE - Real Microsoft Account required
        public const bool IsDevelopmentMode = false;

        // App Information
        public const string AppVersion = "1.0.1";
        public const int AppBuildNumber = 30;
        public const string AppName = "Khandoba Secure Docs";

        // Supabase Configuration (for cross-platform vault access)
        public const bool UseSupabase = true; // Feature flag - always true for Windows
        public static string SupabaseURL => SupabaseConfig.CurrentEnvironment.SupabaseURL;
        public static string SupabaseAnonKey => SupabaseConfig.CurrentEnvironment.SupabaseAnonKey;

        // Feature Flags
        public const bool EnableAnalytics = true;
        public const bool EnableCrashReporting = true;
        public const bool EnablePushNotifications = true;

        // Security
        public const bool RequireBiometricAuth = true;
        public const int SessionTimeoutMinutes = 30;
        public const int MaxLoginAttempts = 5;

        // Development user credentials (only used if IsDevelopmentMode = true)
        public const string DevUserID = "dev-user-123";
        public const string DevUserName = "Developer User";
        public const string DevUserEmail = "dev@khandoba.local";

        // Admin role removed - autopilot mode (ML handles everything)
        
        // Azure Cognitive Services Configuration (for DocumentIndexingService)
        // Get these from: https://portal.azure.com → Create Cognitive Services resource
        public const string AzureCognitiveServicesEndpoint = "https://your-region.cognitiveservices.azure.com/";
        public const string AzureCognitiveServicesKey = "YOUR_AZURE_COGNITIVE_SERVICES_KEY";
        
        // Azure AD Configuration (for AuthenticationService)
        // Get these from: https://portal.azure.com → Azure Active Directory → App registrations
        public const string AzureADClientId = "YOUR_AZURE_AD_CLIENT_ID";
        public const string AzureADTenantId = "YOUR_AZURE_AD_TENANT_ID"; // Optional: For single-tenant apps
        public const string AzureADRedirectUri = "msal://YOUR_APP_PACKAGE_ID"; // e.g., msal://com.khandoba.securedocs
        
        // Azure Storage Configuration (if using Azure Storage instead of Supabase Storage)
        public const string AzureStorageConnectionString = ""; // Optional: Leave empty to use Supabase Storage
        public const string AzureStorageContainerName = "encrypted-documents"; // Only used if connection string is set
    }
}

