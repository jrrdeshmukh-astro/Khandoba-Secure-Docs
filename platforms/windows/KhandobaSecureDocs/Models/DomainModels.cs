using System;
using System.Collections.Generic;

namespace KhandobaSecureDocs.Models
{
    // Domain User Model (for local use)
    public class User
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string MicrosoftUserID { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? Email { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public List<Vault> OwnedVaults { get; set; } = new();
    }

    // Domain Vault Model
    public class Vault
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; } = string.Empty;
        public string? VaultDescription { get; set; }
        public Guid OwnerID { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? LastAccessedAt { get; set; }
        public string Status { get; set; } = "locked"; // "active", "locked", "archived"
        public string KeyType { get; set; } = "single"; // "single", "dual"
        public string VaultType { get; set; } = "both"; // "source", "sink", "both"
        public bool IsSystemVault { get; set; } = false;
        public byte[]? EncryptionKeyData { get; set; }
        public bool IsEncrypted { get; set; } = true;
        public bool IsZeroKnowledge { get; set; } = true;
        public Guid? RelationshipOfficerID { get; set; }
        public bool IsAntiVault { get; set; } = false;
        public Guid? MonitoredVaultID { get; set; }
        public Guid? AntiVaultID { get; set; }
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public User? Owner { get; set; }
        public List<Document> Documents { get; set; } = new();
        public List<VaultSession> Sessions { get; set; } = new();
        public List<VaultAccessLog> AccessLogs { get; set; } = new();
    }

    // Domain Document Model
    public class Document
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid VaultID { get; set; }
        public string Name { get; set; } = string.Empty;
        public string FileType { get; set; } = string.Empty;
        public long FileSize { get; set; }
        public byte[]? EncryptedFileData { get; set; }
        public string? StoragePath { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public List<string> AiTags { get; set; } = new();
        public string DocumentType { get; set; } = "both"; // "source", "sink", "both"

        // Navigation properties
        public Vault? Vault { get; set; }
    }

    // Domain Vault Session Model
    public class VaultSession
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid VaultID { get; set; }
        public Guid UserID { get; set; }
        public DateTime StartedAt { get; set; } = DateTime.UtcNow;
        public DateTime ExpiresAt { get; set; }
        public bool IsActive { get; set; } = true;
        public bool WasExtended { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public Vault? Vault { get; set; }
        public User? User { get; set; }
    }

    // Domain Vault Access Log Model
    public class VaultAccessLog
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid VaultID { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
        public string AccessType { get; set; } = "viewed"; // "opened", "closed", "viewed", "modified", etc.
        public Guid? UserID { get; set; }
        public string? UserName { get; set; }
        public string? DeviceInfo { get; set; }
        public double? LocationLatitude { get; set; }
        public double? LocationLongitude { get; set; }
        public string? IpAddress { get; set; }
        public Guid? DocumentID { get; set; }
        public string? DocumentName { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public Vault? Vault { get; set; }
    }

    // Domain Dual Key Request Model
    public class DualKeyRequest
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid VaultID { get; set; }
        public Guid RequesterID { get; set; }
        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
        public string Status { get; set; } = "pending"; // "pending", "approved", "denied"
        public string? Reason { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public DateTime? DeniedAt { get; set; }
        public Guid? ApproverID { get; set; }
        public double? MlScore { get; set; }
        public string? LogicalReasoning { get; set; }
        public string? DecisionMethod { get; set; } // "ml_auto" or "logic_reasoning"
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public Vault? Vault { get; set; }
        public User? Requester { get; set; }
    }

    // Domain Nominee Model
    public class Nominee
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid? VaultId { get; set; }
        public Guid VaultID => VaultId ?? Guid.Empty;
        public Guid? UserID { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string Status { get; set; } = "pending"; // "pending", "accepted", "active", "inactive", "revoked"
        public DateTime InvitedAt { get; set; } = DateTime.UtcNow;
        public DateTime? AcceptedAt { get; set; }
        public DateTime? LastActiveAt { get; set; }
        public string InviteToken { get; set; } = Guid.NewGuid().ToString();
        public Guid? InvitedByUserID { get; set; }
        public bool IsSubsetAccess { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public Vault? Vault { get; set; }
    }

    // Domain Chat Message Model
    public class ChatMessage
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid SenderID { get; set; }
        public Guid? ReceiverID { get; set; }
        public Guid? VaultID { get; set; }
        public string MessageText { get; set; } = string.Empty;
        public bool IsRead { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public User? Sender { get; set; }
        public User? Receiver { get; set; }
        public Vault? Vault { get; set; }
    }
}

