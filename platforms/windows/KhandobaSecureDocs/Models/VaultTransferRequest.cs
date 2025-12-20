using System;

namespace KhandobaSecureDocs.Models
{
    public class VaultTransferRequest
    {
        public Guid Id { get; set; }
        public Guid? VaultId { get; set; }
        public Guid? RequestedByUserID { get; set; }
        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
        public string Status { get; set; } = "pending"; // "pending", "approved", "denied", "completed"
        public string? Reason { get; set; }
        public Guid? NewOwnerID { get; set; }
        public string? NewOwnerName { get; set; }
        public string? NewOwnerPhone { get; set; }
        public string? NewOwnerEmail { get; set; }
        public string TransferToken { get; set; } = Guid.NewGuid().ToString();
        public DateTime? ApprovedAt { get; set; }
        public Guid? ApproverID { get; set; }
    }
}
