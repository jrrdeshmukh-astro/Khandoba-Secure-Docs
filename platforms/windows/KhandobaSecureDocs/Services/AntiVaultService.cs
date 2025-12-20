using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using KhandobaSecureDocs.Config;
using KhandobaSecureDocs.Models;

namespace KhandobaSecureDocs.Services
{
    public class AntiVault : INotifyPropertyChanged
    {
        public Guid Id { get; set; }
        public Guid VaultID { get; set; }
        public Guid MonitoredVaultID { get; set; }
        public Guid OwnerID { get; set; }
        public string Status { get; set; } = "locked"; // "locked", "active", "archived"
        public AutoUnlockPolicy AutoUnlockPolicy { get; set; } = new();
        public ThreatDetectionSettings ThreatDetectionSettings { get; set; } = new();
        public Guid? LastIntelReportID { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? LastUnlockedAt { get; set; }

        public event PropertyChangedEventHandler? PropertyChanged;
        protected virtual void OnPropertyChanged(string propertyName = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    public class AutoUnlockPolicy
    {
        public bool UnlockOnSessionNomination { get; set; } = true;
        public bool UnlockOnSubsetNomination { get; set; } = true;
        public bool RequireApproval { get; set; } = false;
        public List<Guid> ApprovalUserIDs { get; set; } = new();
    }

    public class ThreatDetectionSettings
    {
        public bool DetectContentDiscrepancies { get; set; } = true;
        public bool DetectMetadataMismatches { get; set; } = true;
        public bool DetectAccessPatternAnomalies { get; set; } = true;
        public bool DetectGeographicInconsistencies { get; set; } = true;
        public bool DetectEditHistoryDiscrepancies { get; set; } = true;
        public string MinThreatSeverity { get; set; } = "medium"; // "low", "medium", "high", "critical"
    }

    public class ThreatDetection
    {
        public string Id { get; set; } = Guid.NewGuid().ToString();
        public DateTime DetectedAt { get; set; } = DateTime.UtcNow;
        public string Type { get; set; } = string.Empty;
        public string Severity { get; set; } = "low"; // "low", "medium", "high", "critical"
        public string Description { get; set; } = string.Empty;
        public Guid? VaultID { get; set; }
    }

    public class AntiVaultService : INotifyPropertyChanged
    {
        private readonly SupabaseService _supabaseService;
        private readonly Guid _currentUserID;
        private ObservableCollection<AntiVault> _antiVaults = new();
        private bool _isLoading;
        private ObservableCollection<ThreatDetection> _detectedThreats = new();

        public event PropertyChangedEventHandler? PropertyChanged;

        public ObservableCollection<AntiVault> AntiVaults
        {
            get => _antiVaults;
            private set
            {
                _antiVaults = value;
                OnPropertyChanged();
            }
        }

        public bool IsLoading
        {
            get => _isLoading;
            private set
            {
                _isLoading = value;
                OnPropertyChanged();
            }
        }

        public ObservableCollection<ThreatDetection> DetectedThreats
        {
            get => _detectedThreats;
            private set
            {
                _detectedThreats = value;
                OnPropertyChanged();
            }
        }

        public AntiVaultService(SupabaseService supabaseService, Guid currentUserID)
        {
            _supabaseService = supabaseService;
            _currentUserID = currentUserID;
        }

        public async Task<AntiVault> CreateAntiVaultAsync(
            Vault monitoredVault,
            Guid ownerID,
            ThreatDetectionSettings? settings = null)
        {
            if (!AppConfig.UseSupabase)
            {
                throw new InvalidOperationException("Supabase must be enabled");
            }

            var antiVaultID = Guid.NewGuid();

            // Check if anti-vault already exists
            var existingVaults = await _supabaseService.FetchAllAsync<SupabaseAntiVault>(
                filters: new Dictionary<string, object> { { "monitored_vault_id", monitoredVault.Id.ToString() } }
            );

            var antiVault = existingVaults.FirstOrDefault() != null
                ? await UpdateExistingAntiVaultAsync(existingVaults.First(), settings)
                : await CreateNewAntiVaultAsync(antiVaultID, monitoredVault, ownerID, settings);

            await LoadAntiVaultsAsync();
            return antiVault;
        }

        private async Task<AntiVault> CreateNewAntiVaultAsync(
            Guid antiVaultID,
            Vault monitoredVault,
            Guid ownerID,
            ThreatDetectionSettings? settings)
        {
            var antiVault = new AntiVault
            {
                Id = antiVaultID,
                VaultID = monitoredVault.Id,
                MonitoredVaultID = monitoredVault.Id,
                OwnerID = ownerID,
                Status = "locked",
                AutoUnlockPolicy = new AutoUnlockPolicy(),
                ThreatDetectionSettings = settings ?? new ThreatDetectionSettings(),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            var supabaseAntiVault = new SupabaseAntiVault
            {
                Id = antiVault.Id,
                VaultID = antiVault.VaultID,
                MonitoredVaultID = antiVault.MonitoredVaultID,
                OwnerID = antiVault.OwnerID,
                Status = antiVault.Status,
                AutoUnlockPolicy = SerializePolicy(antiVault.AutoUnlockPolicy),
                ThreatDetectionSettings = SerializeSettings(antiVault.ThreatDetectionSettings),
                LastIntelReportID = antiVault.LastIntelReportID,
                CreatedAt = antiVault.CreatedAt,
                UpdatedAt = antiVault.UpdatedAt,
                LastUnlockedAt = antiVault.LastUnlockedAt
            };

            await _supabaseService.InsertAsync(supabaseAntiVault);

            // Update vault with anti-vault ID
            var currentVault = await _supabaseService.FetchAsync<SupabaseVault>(monitoredVault.Id);
            if (currentVault != null)
            {
                currentVault.AntiVaultID = antiVault.Id;
                currentVault.IsAntiVault = false; // The monitored vault is not the anti-vault itself
                await _supabaseService.UpdateAsync(monitoredVault.Id, currentVault);
            }

            return antiVault;
        }

        private async Task<AntiVault> UpdateExistingAntiVaultAsync(
            SupabaseAntiVault existing,
            ThreatDetectionSettings? settings)
        {
            var antiVault = ConvertFromSupabase(existing);
            if (settings != null)
            {
                antiVault.ThreatDetectionSettings = settings;
            }
            antiVault.UpdatedAt = DateTime.UtcNow;

            var supabaseAntiVault = new SupabaseAntiVault
            {
                Id = antiVault.Id,
                VaultID = antiVault.VaultID,
                MonitoredVaultID = antiVault.MonitoredVaultID,
                OwnerID = antiVault.OwnerID,
                Status = antiVault.Status,
                AutoUnlockPolicy = SerializePolicy(antiVault.AutoUnlockPolicy),
                ThreatDetectionSettings = SerializeSettings(antiVault.ThreatDetectionSettings),
                LastIntelReportID = antiVault.LastIntelReportID,
                CreatedAt = antiVault.CreatedAt,
                UpdatedAt = antiVault.UpdatedAt,
                LastUnlockedAt = antiVault.LastUnlockedAt
            };

            await _supabaseService.UpdateAsync(antiVault.Id, supabaseAntiVault);
            return antiVault;
        }

        public async Task LoadAntiVaultsAsync()
        {
            IsLoading = true;
            try
            {
                if (!AppConfig.UseSupabase)
                {
                    return;
                }

                var supabaseAntiVaults = await _supabaseService.FetchAllAsync<SupabaseAntiVault>(
                    filters: new Dictionary<string, object> { { "owner_id", _currentUserID.ToString() } }
                );

                var antiVaults = new ObservableCollection<AntiVault>();
                foreach (var supabase in supabaseAntiVaults)
                {
                    antiVaults.Add(ConvertFromSupabase(supabase));
                }

                AntiVaults = antiVaults;
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task UnlockAntiVaultAsync(AntiVault antiVault, Guid vaultID)
        {
            antiVault.Status = "active";
            antiVault.LastUnlockedAt = DateTime.UtcNow;
            antiVault.UpdatedAt = DateTime.UtcNow;

            var supabaseAntiVault = new SupabaseAntiVault
            {
                Id = antiVault.Id,
                VaultID = antiVault.VaultID,
                MonitoredVaultID = antiVault.MonitoredVaultID,
                OwnerID = antiVault.OwnerID,
                Status = antiVault.Status,
                AutoUnlockPolicy = SerializePolicy(antiVault.AutoUnlockPolicy),
                ThreatDetectionSettings = SerializeSettings(antiVault.ThreatDetectionSettings),
                LastIntelReportID = antiVault.LastIntelReportID,
                CreatedAt = antiVault.CreatedAt,
                UpdatedAt = antiVault.UpdatedAt,
                LastUnlockedAt = antiVault.LastUnlockedAt
            };

            await _supabaseService.UpdateAsync(antiVault.Id, supabaseAntiVault);
            await LoadAntiVaultsAsync();
        }

        public async Task LoadThreatsForAntiVaultAsync(Guid antiVaultID)
        {
            try
            {
                // Load threat events from database
                // This would query the threat_events table filtered by vault_id
                // For now, return empty list - implementation depends on threat_events table structure
                DetectedThreats = new ObservableCollection<ThreatDetection>();
            }
            catch (Exception)
            {
                // Handle error
            }
        }

        private AntiVault ConvertFromSupabase(SupabaseAntiVault supabase)
        {
            return new AntiVault
            {
                Id = supabase.Id,
                VaultID = supabase.VaultID,
                MonitoredVaultID = supabase.MonitoredVaultID,
                OwnerID = supabase.OwnerID,
                Status = supabase.Status,
                AutoUnlockPolicy = DeserializePolicy(supabase.AutoUnlockPolicy),
                ThreatDetectionSettings = DeserializeSettings(supabase.ThreatDetectionSettings),
                LastIntelReportID = supabase.LastIntelReportID,
                CreatedAt = supabase.CreatedAt,
                UpdatedAt = supabase.UpdatedAt,
                LastUnlockedAt = supabase.LastUnlockedAt
            };
        }

        private string SerializePolicy(AutoUnlockPolicy policy)
        {
            return JsonSerializer.Serialize(new
            {
                unlockOnSessionNomination = policy.UnlockOnSessionNomination,
                unlockOnSubsetNomination = policy.UnlockOnSubsetNomination,
                requireApproval = policy.RequireApproval,
                approvalUserIDs = policy.ApprovalUserIDs.Select(id => id.ToString()).ToList()
            });
        }

        private AutoUnlockPolicy DeserializePolicy(string? json)
        {
            if (string.IsNullOrEmpty(json))
                return new AutoUnlockPolicy();

            try
            {
                var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;
                return new AutoUnlockPolicy
                {
                    UnlockOnSessionNomination = root.GetProperty("unlockOnSessionNomination").GetBoolean(),
                    UnlockOnSubsetNomination = root.GetProperty("unlockOnSubsetNomination").GetBoolean(),
                    RequireApproval = root.GetProperty("requireApproval").GetBoolean(),
                    ApprovalUserIDs = root.GetProperty("approvalUserIDs").EnumerateArray()
                        .Select(e => Guid.Parse(e.GetString() ?? Guid.Empty.ToString()))
                        .ToList()
                };
            }
            catch
            {
                return new AutoUnlockPolicy();
            }
        }

        private string SerializeSettings(ThreatDetectionSettings settings)
        {
            return JsonSerializer.Serialize(new
            {
                detectContentDiscrepancies = settings.DetectContentDiscrepancies,
                detectMetadataMismatches = settings.DetectMetadataMismatches,
                detectAccessPatternAnomalies = settings.DetectAccessPatternAnomalies,
                detectGeographicInconsistencies = settings.DetectGeographicInconsistencies,
                detectEditHistoryDiscrepancies = settings.DetectEditHistoryDiscrepancies,
                minThreatSeverity = settings.MinThreatSeverity
            });
        }

        private ThreatDetectionSettings DeserializeSettings(string? json)
        {
            if (string.IsNullOrEmpty(json))
                return new ThreatDetectionSettings();

            try
            {
                var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;
                return new ThreatDetectionSettings
                {
                    DetectContentDiscrepancies = root.GetProperty("detectContentDiscrepancies").GetBoolean(),
                    DetectMetadataMismatches = root.GetProperty("detectMetadataMismatches").GetBoolean(),
                    DetectAccessPatternAnomalies = root.GetProperty("detectAccessPatternAnomalies").GetBoolean(),
                    DetectGeographicInconsistencies = root.GetProperty("detectGeographicInconsistencies").GetBoolean(),
                    DetectEditHistoryDiscrepancies = root.GetProperty("detectEditHistoryDiscrepancies").GetBoolean(),
                    MinThreatSeverity = root.GetProperty("minThreatSeverity").GetString() ?? "medium"
                };
            }
            catch
            {
                return new ThreatDetectionSettings();
            }
        }

        protected virtual void OnPropertyChanged(string propertyName = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
