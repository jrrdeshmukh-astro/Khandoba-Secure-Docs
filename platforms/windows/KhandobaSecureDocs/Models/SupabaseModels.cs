using System;
using Postgrest.Models;
using Postgrest.Attributes;

namespace KhandobaSecureDocs.Models
{
    // Supabase User Model
    [Table("users")]
    public class SupabaseUser : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("microsoft_user_id")]
        public string MicrosoftUserID { get; set; } = string.Empty;

        [Column("full_name")]
        public string FullName { get; set; } = string.Empty;

        [Column("email")]
        public string? Email { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    // Supabase Vault Model
    [Table("vaults")]
    public class SupabaseVault : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("name")]
        public string Name { get; set; } = string.Empty;

        [Column("vault_description")]
        public string? VaultDescription { get; set; }

        [Column("owner_id")]
        public Guid OwnerID { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("last_accessed_at")]
        public DateTime? LastAccessedAt { get; set; }

        [Column("status")]
        public string Status { get; set; } = "locked"; // "active", "locked", "archived"

        [Column("key_type")]
        public string KeyType { get; set; } = "single"; // "single", "dual"

        [Column("vault_type")]
        public string VaultType { get; set; } = "both"; // "source", "sink", "both"

        [Column("is_system_vault")]
        public bool IsSystemVault { get; set; } = false;

        [Column("encryption_key_data")]
        public byte[]? EncryptionKeyData { get; set; }

        [Column("is_encrypted")]
        public bool IsEncrypted { get; set; } = true;

        [Column("is_zero_knowledge")]
        public bool IsZeroKnowledge { get; set; } = true;

        [Column("relationship_officer_id")]
        public Guid? RelationshipOfficerID { get; set; }

        [Column("is_anti_vault")]
        public bool IsAntiVault { get; set; } = false;

        [Column("monitored_vault_id")]
        public Guid? MonitoredVaultID { get; set; }

        [Column("anti_vault_id")]
        public Guid? AntiVaultID { get; set; }

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    // Supabase Document Model
    [Table("documents")]
    public class SupabaseDocument : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("vault_id")]
        public Guid VaultID { get; set; }

        [Column("name")]
        public string Name { get; set; } = string.Empty;

        [Column("file_type")]
        public string FileType { get; set; } = string.Empty;

        [Column("file_size")]
        public long FileSize { get; set; }

        [Column("encrypted_file_data")]
        public byte[]? EncryptedFileData { get; set; }

        [Column("storage_path")]
        public string? StoragePath { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        [Column("ai_tags")]
        public string? AiTags { get; set; } // JSON array

        [Column("document_type")]
        public string DocumentType { get; set; } = "both"; // "source", "sink", "both"
    }

    // Supabase Vault Session Model
    [Table("vault_sessions")]
    public class SupabaseVaultSession : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("vault_id")]
        public Guid VaultID { get; set; }

        [Column("user_id")]
        public Guid UserID { get; set; }

        [Column("started_at")]
        public DateTime StartedAt { get; set; } = DateTime.UtcNow;

        [Column("expires_at")]
        public DateTime ExpiresAt { get; set; }

        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        [Column("was_extended")]
        public bool WasExtended { get; set; } = false;

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    // Supabase Vault Access Log Model
    [Table("vault_access_logs")]
    public class SupabaseVaultAccessLog : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("vault_id")]
        public Guid VaultID { get; set; }

        [Column("timestamp")]
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;

        [Column("access_type")]
        public string AccessType { get; set; } = "viewed"; // "opened", "closed", "viewed", "modified", etc.

        [Column("user_id")]
        public Guid? UserID { get; set; }

        [Column("user_name")]
        public string? UserName { get; set; }

        [Column("device_info")]
        public string? DeviceInfo { get; set; }

        [Column("location_latitude")]
        public double? LocationLatitude { get; set; }

        [Column("location_longitude")]
        public double? LocationLongitude { get; set; }

        [Column("ip_address")]
        public string? IpAddress { get; set; }

        [Column("document_id")]
        public Guid? DocumentID { get; set; }

        [Column("document_name")]
        public string? DocumentName { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    // Supabase Dual Key Request Model
    [Table("dual_key_requests")]
    public class SupabaseDualKeyRequest : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("vault_id")]
        public Guid VaultID { get; set; }

        [Column("requester_id")]
        public Guid RequesterID { get; set; }

        [Column("requested_at")]
        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;

        [Column("status")]
        public string Status { get; set; } = "pending"; // "pending", "approved", "denied"

        [Column("reason")]
        public string? Reason { get; set; }

        [Column("approved_at")]
        public DateTime? ApprovedAt { get; set; }

        [Column("denied_at")]
        public DateTime? DeniedAt { get; set; }

        [Column("approver_id")]
        public Guid? ApproverID { get; set; }

        [Column("ml_score")]
        public double? MlScore { get; set; }

        [Column("logical_reasoning")]
        public string? LogicalReasoning { get; set; }

        [Column("decision_method")]
        public string? DecisionMethod { get; set; } // "ml_auto" or "logic_reasoning"

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    // Supabase Nominee Model
    [Table("nominees")]
    public class SupabaseNominee : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("vault_id")]
        public Guid VaultID { get; set; }

        [Column("user_id")]
        public Guid? UserID { get; set; }

        [Column("name")]
        public string Name { get; set; } = string.Empty;

        [Column("email")]
        public string? Email { get; set; }

        [Column("phone_number")]
        public string? PhoneNumber { get; set; }

        [Column("status")]
        public string Status { get; set; } = "pending"; // "pending", "accepted", "active", "revoked"

        [Column("invited_at")]
        public DateTime InvitedAt { get; set; } = DateTime.UtcNow;

        [Column("accepted_at")]
        public DateTime? AcceptedAt { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }

    // Supabase Chat Message Model
    [Table("chat_messages")]
    public class SupabaseChatMessage : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("sender_id")]
        public Guid SenderID { get; set; }

        [Column("receiver_id")]
        public Guid? ReceiverID { get; set; }

        [Column("vault_id")]
        public Guid? VaultID { get; set; }

        [Column("message_text")]
        public string MessageText { get; set; } = string.Empty;

        [Column("is_read")]
        public bool IsRead { get; set; } = false;

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

