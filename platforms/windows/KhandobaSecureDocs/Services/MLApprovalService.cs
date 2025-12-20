using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Models.SupabaseModels;

namespace KhandobaSecureDocs.Services
{
    /// <summary>
    /// ML-based approval service for dual-key vault access requests.
    /// Uses pattern analysis and risk scoring to automatically approve/deny requests.
    /// </summary>
    public class MLApprovalService
    {
        private readonly SupabaseService _supabaseService;

        public MLApprovalService(SupabaseService supabaseService)
        {
            _supabaseService = supabaseService;
        }

        /// <summary>
        /// Process a dual-key request with ML-based approval logic.
        /// Analyzes access patterns, user behavior, and risk factors.
        /// </summary>
        public async Task<MLApprovalResult> ProcessApprovalRequestAsync(SupabaseDualKeyRequest request, Guid userId)
        {
            try
            {
                // 1. Get user's access history
                var accessLogs = await GetUserAccessHistoryAsync(userId, request.VaultID);
                
                // 2. Calculate risk score
                var riskScore = CalculateRiskScore(request, accessLogs);
                
                // 3. Apply approval logic
                var shouldApprove = riskScore <= 0.3; // Approve if risk is low (<=30%)
                
                // 4. Generate reasoning
                var reasoning = GenerateReasoning(request, accessLogs, riskScore);
                
                return new MLApprovalResult
                {
                    ShouldApprove = shouldApprove,
                    Score = riskScore,
                    Reasoning = reasoning,
                    DecisionMethod = "ml_auto"
                };
            }
            catch (Exception ex)
            {
                // On error, deny for safety
                return new MLApprovalResult
                {
                    ShouldApprove = false,
                    Score = 1.0, // High risk
                    Reasoning = $"Error processing request: {ex.Message}",
                    DecisionMethod = "ml_auto_error"
                };
            }
        }

        private async Task<List<SupabaseVaultAccessLog>> GetUserAccessHistoryAsync(Guid userId, Guid vaultId)
        {
            try
            {
                var logs = await _supabaseService.FetchAllAsync<SupabaseVaultAccessLog>(
                    table: "vault_access_logs",
                    filters: new Dictionary<string, object>
                    {
                        { "user_id", userId },
                        { "vault_id", vaultId }
                    },
                    orderBy: "timestamp",
                    ascending: false,
                    limit: 100
                );
                
                return logs ?? new List<SupabaseVaultAccessLog>();
            }
            catch
            {
                return new List<SupabaseVaultAccessLog>();
            }
        }

        private double CalculateRiskScore(SupabaseDualKeyRequest request, List<SupabaseVaultAccessLog> accessLogs)
        {
            double riskScore = 0.0;
            int factors = 0;

            // Factor 1: Recent access history (lower risk if user accessed recently)
            if (accessLogs.Any())
            {
                var recentLogs = accessLogs.Take(10).ToList();
                var recentAccessCount = recentLogs.Count(log => 
                    (DateTime.UtcNow - log.Timestamp).TotalHours < 24);
                
                if (recentAccessCount > 0)
                {
                    riskScore += 0.1; // Recent access = lower risk
                }
                else
                {
                    riskScore += 0.3; // No recent access = higher risk
                }
                factors++;
            }
            else
            {
                riskScore += 0.5; // No history = higher risk
                factors++;
            }

            // Factor 2: Access pattern consistency
            if (accessLogs.Count > 5)
            {
                var timeOfDayAccess = accessLogs.Select(log => log.Timestamp.Hour).ToList();
                var currentHour = DateTime.UtcNow.Hour;
                
                // Check if current time is similar to historical access times
                var similarHourCount = timeOfDayAccess.Count(hour => Math.Abs(hour - currentHour) <= 2);
                if (similarHourCount > timeOfDayAccess.Count / 2)
                {
                    riskScore += 0.1; // Consistent access pattern = lower risk
                }
                else
                {
                    riskScore += 0.3; // Unusual access time = higher risk
                }
                factors++;
            }

            // Factor 3: Request reason analysis (simple keyword matching)
            if (!string.IsNullOrEmpty(request.Reason))
            {
                var reason = request.Reason.ToLower();
                var suspiciousKeywords = new[] { "urgent", "emergency", "hack", "test", "demo" };
                var hasSuspiciousKeyword = suspiciousKeywords.Any(keyword => reason.Contains(keyword));
                
                if (hasSuspiciousKeyword)
                {
                    riskScore += 0.3; // Suspicious keywords = higher risk
                }
                else
                {
                    riskScore += 0.1; // Normal reason = lower risk
                }
                factors++;
            }

            // Normalize risk score
            return factors > 0 ? riskScore / factors : 0.5;
        }

        private string GenerateReasoning(SupabaseDualKeyRequest request, List<SupabaseVaultAccessLog> accessLogs, double riskScore)
        {
            var reasons = new List<string>();

            if (accessLogs.Any())
            {
                var recentAccessCount = accessLogs.Count(log => 
                    (DateTime.UtcNow - log.Timestamp).TotalHours < 24);
                
                if (recentAccessCount > 0)
                {
                    reasons.Add($"User has {recentAccessCount} recent access(es) in the last 24 hours");
                }
                else
                {
                    reasons.Add("No recent access history");
                }
            }
            else
            {
                reasons.Add("No access history available");
            }

            if (riskScore <= 0.3)
            {
                reasons.Add("Risk score is low (ML auto-approved)");
            }
            else
            {
                reasons.Add($"Risk score is {riskScore:P0} (requires manual review)");
            }

            return string.Join("; ", reasons);
        }
    }

    public class MLApprovalResult
    {
        public bool ShouldApprove { get; set; }
        public double Score { get; set; } // 0.0 = low risk, 1.0 = high risk
        public string Reasoning { get; set; } = string.Empty;
        public string DecisionMethod { get; set; } = "ml_auto";
    }
}
