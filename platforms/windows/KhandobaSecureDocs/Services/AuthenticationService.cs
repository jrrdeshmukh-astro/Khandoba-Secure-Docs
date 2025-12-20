using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Graph;
using Microsoft.Identity.Client;
using KhandobaSecureDocs.Config;
using KhandobaSecureDocs.Models;

namespace KhandobaSecureDocs.Services
{
    public class AuthenticationService : INotifyPropertyChanged
    {
        private readonly SupabaseService _supabaseService;
        private User? _currentUser;
        private bool _isAuthenticated;

        public event PropertyChangedEventHandler? PropertyChanged;

        public User? CurrentUser
        {
            get => _currentUser;
            private set
            {
                _currentUser = value;
                OnPropertyChanged();
            }
        }

        public bool IsAuthenticated
        {
            get => _isAuthenticated;
            private set
            {
                _isAuthenticated = value;
                OnPropertyChanged();
            }
        }

        public AuthenticationService(SupabaseService supabaseService)
        {
            _supabaseService = supabaseService;
        }

        public async Task<bool> SignInWithMicrosoftAsync()
        {
            try
            {
                // Use Microsoft Authentication Library (MSAL)
                var builder = PublicClientApplicationBuilder
                    .Create(AppConfig.AzureADClientId);
                
                if (!string.IsNullOrEmpty(AppConfig.AzureADRedirectUri))
                {
                    builder = builder.WithRedirectUri(AppConfig.AzureADRedirectUri);
                }
                else
                {
                    builder = builder.WithRedirectUri("ms-appx-web://Microsoft.AAD.BrokerPlugin/...");
                }
                
                if (!string.IsNullOrEmpty(AppConfig.AzureADTenantId))
                {
                    builder = builder.WithAuthority(AzureCloudInstance.AzurePublic, AppConfig.AzureADTenantId);
                }
                else
                {
                    builder = builder.WithAuthority(AzureCloudInstance.AzurePublic, "common");
                }
                
                var publicClientApp = builder.Build();

                var scopes = new[] { "User.Read", "offline_access" };
                var accounts = await publicClientApp.GetAccountsAsync();
                AuthenticationResult? result;

                try
                {
                    result = await publicClientApp.AcquireTokenSilent(scopes, accounts.FirstOrDefault())
                        .ExecuteAsync();
                }
                catch (MsalUiRequiredException)
                {
                    result = await publicClientApp.AcquireTokenInteractive(scopes)
                        .ExecuteAsync();
                }

                if (result != null)
                {
                    // Sign in to Supabase with Microsoft token
                    var supabaseSession = await _supabaseService.SignInWithMicrosoftAsync(
                        result.IdToken,
                        result.Account.Username
                    );

                    // Get user info from Microsoft Graph
                    var graphClient = new GraphServiceClient(
                        new DelegateAuthenticationProvider((requestMessage) =>
                        {
                            requestMessage.Headers.Authorization =
                                new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", result.AccessToken);
                            return Task.CompletedTask;
                        })
                    );

                    var graphUser = await graphClient.Me.Request().GetAsync();

                    // Create or update user in Supabase
                    var user = await CreateOrUpdateUserAsync(graphUser);

                    CurrentUser = user;
                    IsAuthenticated = true;

                    return true;
                }

                return false;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Sign in failed: {ex.Message}");
                return false;
            }
        }

        public async Task SignOutAsync()
        {
            await _supabaseService.SignOutAsync();
            CurrentUser = null;
            IsAuthenticated = false;
        }

        private async Task<User> CreateOrUpdateUserAsync(Microsoft.Graph.User graphUser)
        {
            // Check if user exists in Supabase
            var existingUsers = await _supabaseService.FetchAllAsync<SupabaseUser>(
                filters: new Dictionary<string, object>
                {
                    { "microsoft_user_id", graphUser.Id }
                }
            );

            if (existingUsers.Any())
            {
                // Update existing user
                var existing = existingUsers.First();
                existing.FullName = graphUser.DisplayName ?? string.Empty;
                existing.Email = graphUser.Mail ?? graphUser.UserPrincipalName;
                existing.UpdatedAt = DateTime.UtcNow;

                var updated = await _supabaseService.UpdateAsync(existing.Id, existing);

                return new User
                {
                    Id = updated.Id,
                    MicrosoftUserID = updated.MicrosoftUserID,
                    FullName = updated.FullName,
                    Email = updated.Email,
                    CreatedAt = updated.CreatedAt,
                    UpdatedAt = updated.UpdatedAt
                };
            }
            else
            {
                // Create new user
                var newUser = new SupabaseUser
                {
                    Id = Guid.NewGuid(),
                    MicrosoftUserID = graphUser.Id,
                    FullName = graphUser.DisplayName ?? string.Empty,
                    Email = graphUser.Mail ?? graphUser.UserPrincipalName,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                var created = await _supabaseService.InsertAsync("users", newUser);

                return new User
                {
                    Id = created.Id,
                    MicrosoftUserID = created.MicrosoftUserID,
                    FullName = created.FullName,
                    Email = created.Email,
                    CreatedAt = created.CreatedAt,
                    UpdatedAt = created.UpdatedAt
                };
            }
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
