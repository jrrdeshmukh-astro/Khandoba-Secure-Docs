using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using KhandobaSecureDocs.Models;

namespace KhandobaSecureDocs.Services
{
    public class BroadcastVaultService
    {
        public const string OpenStreetVaultName = "Open Street";
        public const string OpenStreetVaultDescription = "A public broadcast vault accessible to everyone";
        
        private readonly VaultService _vaultService;

        public BroadcastVaultService(VaultService vaultService)
        {
            _vaultService = vaultService;
        }

        public bool IsBroadcastVault(Vault vault)
        {
            return vault.IsSystemVault && (
                vault.Name == OpenStreetVaultName ||
                vault.Name.Contains("Broadcast", StringComparison.OrdinalIgnoreCase)
            );
        }

        public async Task<Vault> GetOrCreateOpenStreetVaultAsync()
        {
            try
            {
                // Load all vaults and find Open Street
                await _vaultService.LoadVaultsAsync();
                var allVaults = _vaultService.Vaults;
                var openStreetVault = allVaults.FirstOrDefault(v => 
                    v.Name == OpenStreetVaultName && v.IsSystemVault
                );

                if (openStreetVault != null)
                {
                    Console.WriteLine("✅ Found existing Open Street vault");
                    return openStreetVault;
                }

                // Create new Open Street vault
                var result = await _vaultService.CreateVaultAsync(
                    name: OpenStreetVaultName,
                    description: OpenStreetVaultDescription,
                    keyType: "single"
                );

                if (result.IsSuccess && result.Value != null)
                {
                    var newVault = result.Value;
                    // Mark as system vault (this might need to be done directly in database)
                    // For now, we'll rely on VaultService to handle it
                    Console.WriteLine("✅ Created Open Street broadcast vault");
                    return newVault;
                }

                throw new InvalidOperationException("Failed to create Open Street vault");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error creating Open Street vault: {ex.Message}");
                throw;
            }
        }

        public List<Vault> GetBroadcastVaults(List<Vault> allVaults)
        {
            return allVaults.Where(IsBroadcastVault).ToList();
        }

        public bool HasAccessToBroadcastVault(Vault vault, Guid? userId)
        {
            return IsBroadcastVault(vault); // Broadcast vaults are public
        }
    }
}
