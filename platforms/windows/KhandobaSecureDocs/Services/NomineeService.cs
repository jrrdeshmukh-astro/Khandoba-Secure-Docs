using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using KhandobaSecureDocs.Config;
using KhandobaSecureDocs.Models;

namespace KhandobaSecureDocs.Services
{
    public class NomineeService
    {
        private readonly SupabaseService _supabaseService;

        public NomineeService(SupabaseService supabaseService)
        {
            _supabaseService = supabaseService;
        }

        public async Task<List<Nominee>> GetNomineesForVaultAsync(Guid vaultId)
        {
            try
            {
                var supabaseNominees = await _supabaseService.FetchAllAsync<SupabaseNominee>(
                    filters: new Dictionary<string, object>
                    {
                        { "vault_id", vaultId.ToString() }
                    },
                    orderBy: "invited_at",
                    ascending: false
                );

                return supabaseNominees.Select(ConvertToDomainNominee).ToList();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading nominees: {ex.Message}");
                return new List<Nominee>();
            }
        }

        public async Task<Nominee> InviteNomineeAsync(
            Guid vaultId,
            string name,
            string? email = null,
            string? phoneNumber = null,
            Guid? invitedByUserID = null,
            bool isSubsetAccess = false,
            List<Guid>? selectedDocumentIDs = null)
        {
            try
            {
                // Note: SupabaseNominee is in SupabaseModels.cs - use that
                var supabaseNominee = new SupabaseNominee
                {
                    Id = Guid.NewGuid(),
                    VaultID = vaultId,
                    Name = name,
                    Email = email,
                    PhoneNumber = phoneNumber,
                    Status = "pending",
                    InvitedAt = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                var created = await _supabaseService.InsertAsync("nominees", supabaseNominee);
                return ConvertToDomainNominee(created);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error inviting nominee: {ex.Message}");
                throw;
            }
        }

        public async Task<Nominee> AcceptNomineeInvitationAsync(string inviteToken)
        {
            try
            {
                // Find nominee by invite token
                // Note: SupabaseNominee may not have invite_token field - this may need to be handled differently
                // For now, return empty list - this functionality may need database schema update
                var nominees = await _supabaseService.FetchAllAsync<SupabaseNominee>(
                    filters: null
                );
                nominees = nominees.Where(n => n.Id.ToString() == inviteToken).ToList();

                var nominee = nominees.FirstOrDefault();
                if (nominee == null)
                {
                    throw new InvalidOperationException("Invitation not found");
                }

                if (nominee.Status != "pending")
                {
                    throw new InvalidOperationException("Invitation already processed");
                }

                // Update status to accepted
                nominee.Status = "accepted";
                nominee.AcceptedAt = DateTime.UtcNow;
                nominee.UpdatedAt = DateTime.UtcNow;

                var updated = await _supabaseService.UpdateAsync(nominee.Id, nominee);
                return ConvertToDomainNominee(updated);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error accepting invitation: {ex.Message}");
                throw;
            }
        }

        public async Task RemoveNomineeAsync(Guid nomineeId)
        {
            try
            {
                await _supabaseService.DeleteAsync<SupabaseNominee>(nomineeId);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error removing nominee: {ex.Message}");
                throw;
            }
        }

        public async Task RevokeNomineeAsync(Guid nomineeId)
        {
            try
            {
                // Fetch nominee by ID
                var nominees = await _supabaseService.FetchAllAsync<SupabaseNominee>(
                    filters: new Dictionary<string, object>
                    {
                        { "id", nomineeId.ToString() }
                    }
                );

                var nominee = nominees.FirstOrDefault();
                if (nominee != null)
                {
                    nominee.Status = "revoked";
                    nominee.UpdatedAt = DateTime.UtcNow;
                    await _supabaseService.UpdateAsync(nomineeId, nominee);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error revoking nominee: {ex.Message}");
                throw;
            }
        }

        private Nominee ConvertToDomainNominee(SupabaseNominee supabaseNominee)
        {
            return new Nominee
            {
                Id = supabaseNominee.Id,
                VaultId = supabaseNominee.VaultID,
                UserID = supabaseNominee.UserID,
                Name = supabaseNominee.Name,
                Email = supabaseNominee.Email,
                PhoneNumber = supabaseNominee.PhoneNumber,
                Status = supabaseNominee.Status,
                InvitedAt = supabaseNominee.InvitedAt,
                AcceptedAt = supabaseNominee.AcceptedAt,
                LastActiveAt = null, // Not in SupabaseNominee model
                InviteToken = Guid.NewGuid().ToString(), // Generate new token
                InvitedByUserID = null, // Not in SupabaseNominee model
                IsSubsetAccess = false, // Default value
                CreatedAt = supabaseNominee.CreatedAt,
                UpdatedAt = supabaseNominee.UpdatedAt
            };
        }
    }

}
