namespace KhandobaSecureDocs.Config
{
    public static class SupabaseConfig
    {
        // Supabase Project Configuration
        // Production credentials configured
        public const string SupabaseURL = "https://uremtyiorzlapwthjsko.supabase.co";
        public const string SupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVyZW10eWlvcnpsYXB3dGhqc2tvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5NjI3MDcsImV4cCI6MjA4MTUzODcwN30.P4Yg4Gl040Msv0TeRuHQ-_SuGfeNEHCV234W5TTSN7Y";

        // Environment Configuration
        public enum Environment
        {
            Development,
            Production
        }

        public static Environment CurrentEnvironment
        {
            get
            {
#if DEBUG
                return Environment.Development;
#else
                return Environment.Production;
#endif
            }
        }

        // Storage Bucket Configuration
        public const string EncryptedDocumentsBucket = "encrypted-documents";
        public const string VoiceMemosBucket = "voice-memos";
        public const string IntelReportsBucket = "intel-reports";

        // Real-time Configuration
        public const bool EnableRealtime = true;
        public static readonly string[] RealtimeChannels = new[]
        {
            "vaults",
            "documents",
            "nominees",
            "chat_messages",
            "vault_sessions"
        };

        // Database Configuration
        public const int DefaultPageSize = 50;
        public const int MaxRetryAttempts = 3;
        public const double RequestTimeout = 30.0;
    }
}

