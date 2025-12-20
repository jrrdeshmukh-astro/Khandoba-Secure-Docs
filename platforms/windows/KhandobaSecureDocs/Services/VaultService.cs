using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;
using KhandobaSecureDocs.Config;
using KhandobaSecureDocs.Models;
using Windows.Devices.Geolocation;

namespace KhandobaSecureDocs.Services
{
    public class VaultService : INotifyPropertyChanged
    {
        private readonly SupabaseService _supabaseService;
        private readonly EncryptionService _encryptionService;
        private readonly MLApprovalService? _mlApprovalService;
        private readonly LocationService _locationService;
        private List<Vault> _vaults = new();
        private bool _isLoading;
        private Dictionary<Guid, VaultSession> _activeSessions = new();
        private Guid? _currentUserID;
        private User? _currentUser;

        public event PropertyChangedEventHandler? PropertyChanged;

        public List<Vault> Vaults
        {
            get => _vaults;
            private set
            {
                _vaults = value;
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

        public Dictionary<Guid, VaultSession> ActiveSessions => _activeSessions;

        public VaultService(
            SupabaseService supabaseService,
            EncryptionService encryptionService,
            LocationService locationService,
            MLApprovalService? mlApprovalService = null)
        {
            _supabaseService = supabaseService;
            _encryptionService = encryptionService;
            _locationService = locationService;
            _mlApprovalService = mlApprovalService;
        }

        public void Configure(Guid userID, User? user = null)
        {
            _currentUserID = userID;
            _currentUser = user;
        }

        public async Task LoadVaultsAsync()
        {
            IsLoading = true;
            try
            {
                if (!AppConfig.UseSupabase || _currentUserID == null)
                {
                    throw new InvalidOperationException("Supabase must be enabled and user must be authenticated");
                }

                // Load vaults from Supabase (RLS automatically filters by user access)
                var supabaseVaults = await _supabaseService.FetchAllAsync<SupabaseVault>(
                    filters: null,
                    orderBy: "created_at",
                    ascending: false
                );

                // Convert to domain models
                var vaults = new List<Vault>();
                foreach (var supabaseVault in supabaseVaults)
                {
                    var vault = ConvertToDomainVault(supabaseVault);
                    vaults.Add(vault);
                }

                Vaults = vaults;

                // Load active sessions
                await LoadActiveSessionsAsync();
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task<Vault> CreateVaultAsync(
            string name,
            string? description,
            string keyType,
            string vaultType = "both")
        {
            IsLoading = true;
            try
            {
                if (!AppConfig.UseSupabase || _currentUserID == null)
                {
                    throw new InvalidOperationException("Supabase must be enabled and user must be authenticated");
                }

                var supabaseVault = new SupabaseVault
                {
                    Id = Guid.NewGuid(),
                    Name = name,
                    VaultDescription = description,
                    OwnerID = _currentUserID.Value,
                    Status = "locked",
                    KeyType = keyType,
                    VaultType = vaultType,
                    IsSystemVault = false,
                    IsEncrypted = true,
                    IsZeroKnowledge = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                // Insert into Supabase
                var created = await _supabaseService.InsertAsync("vaults", supabaseVault);

                // Create access log
                var accessLog = new SupabaseVaultAccessLog
                {
                    Id = Guid.NewGuid(),
                    VaultID = created.Id,
                    Timestamp = DateTime.UtcNow,
                    AccessType = "created",
                    UserID = _currentUserID.Value,
                    UserName = _currentUser?.FullName,
                    CreatedAt = DateTime.UtcNow
                };

                // Add location if available
                var location = await _locationService.GetCurrentLocationAsync();
                if (location != null)
                {
                    accessLog.LocationLatitude = location.Coordinate.Latitude;
                    accessLog.LocationLongitude = location.Coordinate.Longitude;
                }

                await _supabaseService.InsertAsync("vault_access_logs", accessLog);

                // Reload vaults
                await LoadVaultsAsync();

                return ConvertToDomainVault(created);
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task OpenVaultAsync(Vault vault)
        {
            IsLoading = true;
            try
            {
                if (!AppConfig.UseSupabase || _currentUserID == null)
                {
                    throw new InvalidOperationException("Supabase must be enabled and user must be authenticated");
                }

                // Check if vault requires dual-key approval
                if (vault.KeyType == "dual")
                {
                    // Check for existing pending requests
                    var existingRequests = await _supabaseService.FetchAllAsync<SupabaseDualKeyRequest>(
                        filters: new Dictionary<string, object>
                        {
                            { "vault_id", vault.Id.ToString() },
                            { "requester_id", _currentUserID.Value.ToString() },
                            { "status", "pending" }
                        }
                    );

                    if (existingRequests.Any())
                    {
                        // Process existing request with ML (simplified - would need DualKeyApprovalService)
                        // For now, we'll create a new request
                    }
                    else
                    {
                        // Create new dual-key request
                        var request = new SupabaseDualKeyRequest
                        {
                            Id = Guid.NewGuid(),
                            VaultID = vault.Id,
                            RequesterID = _currentUserID.Value,
                            RequestedAt = DateTime.UtcNow,
                            Status = "pending",
                            Reason = "Requesting vault access",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };

                        var insertedRequest = await _supabaseService.InsertAsync("dual_key_requests", request);

                        // Process with ML approval service
                        if (_mlApprovalService != null)
                        {
                            var approvalResult = await _mlApprovalService.ProcessApprovalRequestAsync(
                                insertedRequest, 
                                _currentUserID.Value
                            );

                            if (approvalResult.ShouldApprove)
                            {
                                insertedRequest.Status = "approved";
                                insertedRequest.ApprovedAt = DateTime.UtcNow;
                                insertedRequest.MlScore = approvalResult.Score;
                                insertedRequest.LogicalReasoning = approvalResult.Reasoning;
                                insertedRequest.DecisionMethod = approvalResult.DecisionMethod;
                            }
                            else
                            {
                                insertedRequest.Status = "pending"; // Requires manual review
                                insertedRequest.MlScore = approvalResult.Score;
                                insertedRequest.LogicalReasoning = approvalResult.Reasoning;
                                insertedRequest.DecisionMethod = approvalResult.DecisionMethod;
                            }

                            await _supabaseService.UpdateAsync(insertedRequest.Id, insertedRequest);
                        }
                        else
                        {
                            // Fallback: Auto-approve if ML service not available
                            insertedRequest.Status = "approved";
                            insertedRequest.ApprovedAt = DateTime.UtcNow;
                            insertedRequest.DecisionMethod = "auto";
                            await _supabaseService.UpdateAsync(insertedRequest.Id, insertedRequest);
                        }
                    }
                }

                // Create vault session
                var expiresAt = DateTime.UtcNow.AddMinutes(AppConfig.SessionTimeoutMinutes);
                var supabaseSession = new SupabaseVaultSession
                {
                    Id = Guid.NewGuid(),
                    VaultID = vault.Id,
                    UserID = _currentUserID.Value,
                    StartedAt = DateTime.UtcNow,
                    ExpiresAt = expiresAt,
                    IsActive = true,
                    WasExtended = false,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                await _supabaseService.InsertAsync("vault_sessions", supabaseSession);

                // Update vault status
                var updatedVault = await _supabaseService.FetchAsync<SupabaseVault>(vault.Id);
                updatedVault.Status = "active";
                updatedVault.LastAccessedAt = DateTime.UtcNow;
                updatedVault.UpdatedAt = DateTime.UtcNow;
                await _supabaseService.UpdateAsync(vault.Id, updatedVault);

                // Create access log
                var accessLog = new SupabaseVaultAccessLog
                {
                    Id = Guid.NewGuid(),
                    VaultID = vault.Id,
                    Timestamp = DateTime.UtcNow,
                    AccessType = "opened",
                    UserID = _currentUserID.Value,
                    UserName = _currentUser?.FullName,
                    DeviceInfo = Windows.System.Profile.AnalyticsInfo.VersionInfo.DeviceFamily,
                    CreatedAt = DateTime.UtcNow
                };

                var location = await _locationService.GetCurrentLocationAsync();
                if (location != null)
                {
                    accessLog.LocationLatitude = location.Coordinate.Latitude;
                    accessLog.LocationLongitude = location.Coordinate.Longitude;
                }

                await _supabaseService.InsertAsync("vault_access_logs", accessLog);

                // Store session locally
                var vaultSession = new VaultSession
                {
                    Id = supabaseSession.Id,
                    VaultID = supabaseSession.VaultID,
                    UserID = supabaseSession.UserID,
                    StartedAt = supabaseSession.StartedAt,
                    ExpiresAt = supabaseSession.ExpiresAt,
                    IsActive = supabaseSession.IsActive,
                    WasExtended = supabaseSession.WasExtended,
                    CreatedAt = supabaseSession.CreatedAt,
                    UpdatedAt = supabaseSession.UpdatedAt,
                    Vault = vault
                };

                _activeSessions[vault.Id] = vaultSession;

                // Start session timeout timer
                StartSessionTimeout(vault);

                // Reload vaults
                await LoadVaultsAsync();
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task CloseVaultAsync(Vault vault)
        {
            IsLoading = true;
            try
            {
                if (!AppConfig.UseSupabase || _currentUserID == null)
                {
                    throw new InvalidOperationException("Supabase must be enabled and user must be authenticated");
                }

                // Update vault status to locked
                var updatedVault = await _supabaseService.FetchAsync<SupabaseVault>(vault.Id);
                updatedVault.Status = "locked";
                updatedVault.UpdatedAt = DateTime.UtcNow;
                await _supabaseService.UpdateAsync(vault.Id, updatedVault);

                // End all active sessions for this vault
                var activeSessions = await _supabaseService.FetchAllAsync<SupabaseVaultSession>(
                    filters: new Dictionary<string, object>
                    {
                        { "vault_id", vault.Id.ToString() },
                        { "is_active", true }
                    }
                );

                foreach (var session in activeSessions)
                {
                    session.IsActive = false;
                    session.UpdatedAt = DateTime.UtcNow;
                    await _supabaseService.UpdateAsync(session.Id, session);
                }

                // Create access log
                var accessLog = new SupabaseVaultAccessLog
                {
                    Id = Guid.NewGuid(),
                    VaultID = vault.Id,
                    Timestamp = DateTime.UtcNow,
                    AccessType = "closed",
                    UserID = _currentUserID.Value,
                    UserName = _currentUser?.FullName,
                    DeviceInfo = Windows.System.Profile.AnalyticsInfo.VersionInfo.DeviceFamily,
                    CreatedAt = DateTime.UtcNow
                };

                var location = await _locationService.GetCurrentLocationAsync();
                if (location != null)
                {
                    accessLog.LocationLatitude = location.Coordinate.Latitude;
                    accessLog.LocationLongitude = location.Coordinate.Longitude;
                }

                await _supabaseService.InsertAsync("vault_access_logs", accessLog);

                // Remove from local active sessions
                _activeSessions.Remove(vault.Id);

                // Reload vaults
                await LoadVaultsAsync();
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task DeleteVaultAsync(Vault vault)
        {
            if (!AppConfig.UseSupabase)
            {
                throw new InvalidOperationException("Supabase must be enabled");
            }

            await _supabaseService.DeleteAsync<SupabaseVault>(vault.Id);
            await LoadVaultsAsync();
        }

        public bool HasActiveSession(Guid vaultID)
        {
            if (_activeSessions.TryGetValue(vaultID, out var session))
            {
                return session.IsActive && session.ExpiresAt > DateTime.UtcNow;
            }
            return false;
        }

        private async Task LoadActiveSessionsAsync()
        {
            if (!AppConfig.UseSupabase || _currentUserID == null)
            {
                return;
            }

            try
            {
                var sessions = await _supabaseService.FetchAllAsync<SupabaseVaultSession>(
                    filters: new Dictionary<string, object>
                    {
                        { "user_id", _currentUserID.Value.ToString() },
                        { "is_active", true }
                    }
                );

                foreach (var session in sessions)
                {
                    if (session.ExpiresAt > DateTime.UtcNow)
                    {
                        var vault = Vaults.FirstOrDefault(v => v.Id == session.VaultID);
                        if (vault != null)
                        {
                            var vaultSession = new VaultSession
                            {
                                Id = session.Id,
                                VaultID = session.VaultID,
                                UserID = session.UserID,
                                StartedAt = session.StartedAt,
                                ExpiresAt = session.ExpiresAt,
                                IsActive = session.IsActive,
                                WasExtended = session.WasExtended,
                                CreatedAt = session.CreatedAt,
                                UpdatedAt = session.UpdatedAt,
                                Vault = vault
                            };

                            _activeSessions[session.VaultID] = vaultSession;
                            StartSessionTimeout(vault);
                        }
                    }
                    else
                    {
                        // Session expired - close it
                        session.IsActive = false;
                        session.UpdatedAt = DateTime.UtcNow;
                        await _supabaseService.UpdateAsync(session.Id, session);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to load sessions: {ex.Message}");
            }
        }

        private void StartSessionTimeout(Vault vault)
        {
            if (!_activeSessions.TryGetValue(vault.Id, out var session))
            {
                return;
            }

            var timeUntilExpiration = (session.ExpiresAt - DateTime.UtcNow).TotalMilliseconds;
            if (timeUntilExpiration <= 0)
            {
                // Session already expired
                Task.Run(async () => await CloseVaultAsync(vault));
                return;
            }

            // Start timer to auto-close vault when session expires
            Task.Delay(TimeSpan.FromMilliseconds(timeUntilExpiration))
                .ContinueWith(async _ =>
                {
                    if (_activeSessions.TryGetValue(vault.Id, out var currentSession) &&
                        currentSession.ExpiresAt <= DateTime.UtcNow)
                    {
                        await CloseVaultAsync(vault);
                    }
                });
        }

        private Vault ConvertToDomainVault(SupabaseVault supabaseVault)
        {
            return new Vault
            {
                Id = supabaseVault.Id,
                Name = supabaseVault.Name,
                VaultDescription = supabaseVault.VaultDescription,
                OwnerID = supabaseVault.OwnerID,
                CreatedAt = supabaseVault.CreatedAt,
                LastAccessedAt = supabaseVault.LastAccessedAt,
                Status = supabaseVault.Status,
                KeyType = supabaseVault.KeyType,
                VaultType = supabaseVault.VaultType,
                IsSystemVault = supabaseVault.IsSystemVault,
                EncryptionKeyData = supabaseVault.EncryptionKeyData,
                IsEncrypted = supabaseVault.IsEncrypted,
                IsZeroKnowledge = supabaseVault.IsZeroKnowledge,
                RelationshipOfficerID = supabaseVault.RelationshipOfficerID,
                IsAntiVault = supabaseVault.IsAntiVault,
                MonitoredVaultID = supabaseVault.MonitoredVaultID,
                AntiVaultID = supabaseVault.AntiVaultID,
                UpdatedAt = supabaseVault.UpdatedAt
            };
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}

