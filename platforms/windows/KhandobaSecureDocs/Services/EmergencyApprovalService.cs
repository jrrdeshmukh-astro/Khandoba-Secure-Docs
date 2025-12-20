using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using KhandobaSecureDocs.Config;
using KhandobaSecureDocs.Models;
using Postgrest.Models;
using Postgrest.Attributes;

namespace KhandobaSecureDocs.Services
{
    public class EmergencyApprovalService
    {
        private readonly SupabaseService _supabaseService;

        public EmergencyApprovalService(SupabaseService supabaseService)
        {
            _supabaseService = supabaseService;
        }

        public async Task<List<EmergencyAccessRequest>> GetPendingRequestsAsync()
        {
            try
            {
                var requests = await _supabaseService.FetchAllAsync<SupabaseEmergencyAccessRequest>(
                    filters: new Dictionary<string, object>
                    {
                        { "status", "pending" }
                    },
                    orderBy: "requested_at",
                    ascending: false
                );

                return requests.Select(ConvertToDomainRequest).ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading pending requests: {ex.Message}");
                return new List<EmergencyAccessRequest>();
            }
        }

        public async Task<EmergencyAccessRequest> CreateEmergencyRequestAsync(
            Guid vaultId,
            Guid requesterID,
            string reason,
            string urgency)
        {
            try
            {
                var supabaseRequest = new SupabaseEmergencyAccessRequest
                {
                    Id = Guid.NewGuid(),
                    VaultID = vaultId,
                    RequesterID = requesterID,
                    RequestedAt = DateTime.UtcNow,
                    Reason = reason,
                    Urgency = urgency,
                    Status = "pending",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                await _supabaseService.InsertAsync("emergency_access_requests", supabaseRequest);
                return ConvertToDomainRequest(supabaseRequest);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error creating emergency request: {ex.Message}");
                throw;
            }
        }

        public async Task<EmergencyAccessRequest> ApproveEmergencyRequestAsync(
            Guid requestId,
            Guid approverID)
        {
            try
            {
                // Fetch request by ID
                var requests = await _supabaseService.FetchAllAsync<SupabaseEmergencyAccessRequest>(
                    filters: new Dictionary<string, object>
                    {
                        { "id", requestId.ToString() }
                    }
                );

                var request = requests.FirstOrDefault();
                if (request == null)
                {
                    throw new InvalidOperationException("Request not found");
                }

                // Generate pass code
                var passCode = Guid.NewGuid().ToString();
                var expiresAt = DateTime.UtcNow.AddHours(24);

                // Update request
                request.Status = "approved";
                request.ApprovedAt = DateTime.UtcNow;
                request.ApproverID = approverID;
                request.ExpiresAt = expiresAt;
                request.PassCode = passCode;
                request.UpdatedAt = DateTime.UtcNow;

                await _supabaseService.UpdateAsync(requestId, request);
                return ConvertToDomainRequest(request);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error approving emergency request: {ex.Message}");
                throw;
            }
        }

        public async Task DenyEmergencyRequestAsync(
            Guid requestId,
            Guid approverID)
        {
            try
            {
                // Fetch request by ID
                var requests = await _supabaseService.FetchAllAsync<SupabaseEmergencyAccessRequest>(
                    filters: new Dictionary<string, object>
                    {
                        { "id", requestId.ToString() }
                    }
                );

                var request = requests.FirstOrDefault();
                if (request != null)
                {
                    request.Status = "denied";
                    request.ApproverID = approverID;
                    request.UpdatedAt = DateTime.UtcNow;

                    await _supabaseService.UpdateAsync(requestId, request);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error denying emergency request: {ex.Message}");
                throw;
            }
        }

        public async Task<EmergencyAccessRequest?> VerifyEmergencyPassAsync(
            string passCode,
            Guid vaultId)
        {
            try
            {
                // Find request by pass code and vault ID
                var requests = await _supabaseService.FetchAllAsync<SupabaseEmergencyAccessRequest>(
                    filters: new Dictionary<string, object>
                    {
                        { "pass_code", passCode },
                        { "vault_id", vaultId.ToString() }
                    }
                );

                var request = requests.FirstOrDefault();
                if (request == null)
                {
                    return null;
                }

                // Check if expired
                if (request.ExpiresAt.HasValue && request.ExpiresAt.Value < DateTime.UtcNow)
                {
                    return null;
                }

                // Check if approved
                if (request.Status != "approved")
                {
                    return null;
                }

                return ConvertToDomainRequest(request);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error verifying emergency pass: {ex.Message}");
                return null;
            }
        }

        private EmergencyAccessRequest ConvertToDomainRequest(SupabaseEmergencyAccessRequest supabaseRequest)
        {
            return new EmergencyAccessRequest
            {
                Id = supabaseRequest.Id,
                VaultId = supabaseRequest.VaultID,
                RequesterID = supabaseRequest.RequesterID,
                RequestedAt = supabaseRequest.RequestedAt,
                Reason = supabaseRequest.Reason,
                Urgency = supabaseRequest.Urgency,
                Status = supabaseRequest.Status,
                ApprovedAt = supabaseRequest.ApprovedAt,
                ApproverID = supabaseRequest.ApproverID,
                ExpiresAt = supabaseRequest.ExpiresAt,
                PassCode = supabaseRequest.PassCode,
                MLScore = supabaseRequest.MLScore,
                MLRecommendation = supabaseRequest.MLRecommendation
            };
        }
    }

    // Supabase model for emergency access requests
    [Table("emergency_access_requests")]
    public class SupabaseEmergencyAccessRequest : BaseModel
    {
        [PrimaryKey("id")]
        public Guid Id { get; set; }

        [Column("vault_id")]
        public Guid VaultID { get; set; }

        [Column("requester_id")]
        public Guid RequesterID { get; set; }

        [Column("requested_at")]
        public DateTime RequestedAt { get; set; }

        [Column("reason")]
        public string Reason { get; set; } = string.Empty;

        [Column("urgency")]
        public string Urgency { get; set; } = "medium";

        [Column("status")]
        public string Status { get; set; } = "pending";

        [Column("approved_at")]
        public DateTime? ApprovedAt { get; set; }

        [Column("approver_id")]
        public Guid? ApproverID { get; set; }

        [Column("expires_at")]
        public DateTime? ExpiresAt { get; set; }

        [Column("pass_code")]
        public string? PassCode { get; set; }

        [Column("ml_score")]
        public double? MLScore { get; set; }

        [Column("ml_recommendation")]
        public string? MLRecommendation { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
