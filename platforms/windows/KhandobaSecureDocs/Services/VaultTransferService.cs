using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using KhandobaSecureDocs.Models;

namespace KhandobaSecureDocs.Services
{
    public class VaultTransferService
    {
        private readonly VaultService _vaultService;
        private readonly SupabaseService _supabaseService;

        public VaultTransferService(
            VaultService vaultService,
            SupabaseService supabaseService)
        {
            _vaultService = vaultService;
            _supabaseService = supabaseService;
        }

        public async Task<VaultTransferRequest> RequestOwnershipTransferAsync(
            Vault vault,
            string? newOwnerEmail = null,
            string? newOwnerPhone = null,
            string? newOwnerName = null,
            string? reason = null)
        {
            try
            {
                var transferRequest = new VaultTransferRequest
                {
                    Id = Guid.NewGuid(),
                    VaultId = vault.Id,
                    RequestedByUserID = vault.OwnerID,
                    NewOwnerEmail = newOwnerEmail,
                    NewOwnerPhone = newOwnerPhone,
                    NewOwnerName = newOwnerName,
                    Reason = reason,
                    Status = "pending",
                    RequestedAt = DateTime.UtcNow,
                    TransferToken = Guid.NewGuid().ToString()
                };

                // TODO: Insert to Supabase
                // await _supabaseService.InsertAsync("vault_transfer_requests", transferRequest);

                Console.WriteLine($"✅ Transfer request created: {transferRequest.Id}");
                Console.WriteLine($"   Transfer Token: {transferRequest.TransferToken}");
                return transferRequest;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error creating transfer request: {ex.Message}");
                throw;
            }
        }

        public async Task<Vault> AcceptOwnershipTransferAsync(string transferToken)
        {
            try
            {
                // TODO: Find transfer request by token and accept it
                // Update vault ownership
                // Update transfer request status to "completed"
                throw new NotImplementedException("Transfer acceptance not yet implemented");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error accepting transfer: {ex.Message}");
                throw;
            }
        }
    }
}
