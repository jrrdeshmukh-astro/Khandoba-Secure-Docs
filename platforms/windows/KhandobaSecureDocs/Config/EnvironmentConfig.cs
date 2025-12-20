//
//  EnvironmentConfig.cs
//  Khandoba Secure Docs - Windows
//
//  Environment-specific configuration
//

namespace KhandobaSecureDocs.Config
{
    public enum Environment
    {
        Development,
        Test,
        Production
    }

    public static class EnvironmentConfig
    {
#if DEBUG
        private static readonly Environment CurrentEnvironment = Environment.Development;
#elif TEST
        private static readonly Environment CurrentEnvironment = Environment.Test;
#else
        private static readonly Environment CurrentEnvironment = Environment.Production;
#endif

        public static Environment Current => CurrentEnvironment;

        public static bool IsDevelopment => CurrentEnvironment == Environment.Development;
        public static bool IsTest => CurrentEnvironment == Environment.Test;
        public static bool IsProduction => CurrentEnvironment == Environment.Production;

        public static string GetSupabaseUrl()
        {
            return CurrentEnvironment switch
            {
                Environment.Development => "https://uremtyiorzlapwthjsko.supabase.co", // Dev project
                Environment.Test => "https://uremtyiorzlapwthjsko.supabase.co", // Test project
                Environment.Production => "https://uremtyiorzlapwthjsko.supabase.co", // Prod project
                _ => AppConfig.SupabaseUrl
            };
        }

        public static string GetSupabaseAnonKey()
        {
            return CurrentEnvironment switch
            {
                Environment.Development => "YOUR_DEV_SUPABASE_ANON_KEY",
                Environment.Test => "YOUR_TEST_SUPABASE_ANON_KEY",
                Environment.Production => "YOUR_PROD_SUPABASE_ANON_KEY",
                _ => AppConfig.SupabaseAnonKey
            };
        }

        public static bool EnableLogging => CurrentEnvironment != Environment.Production;
        public static bool EnableAnalytics => CurrentEnvironment != Environment.Development;
        public static bool EnableCrashReporting => CurrentEnvironment != Environment.Development;
        public static bool EnablePushNotifications => true;
        public static bool RequireBiometricAuth => CurrentEnvironment != Environment.Development;

        public static int SessionTimeoutMinutes => CurrentEnvironment switch
        {
            Environment.Development => 60,
            Environment.Test => 30,
            Environment.Production => 30,
            _ => 30
        };
    }
}
