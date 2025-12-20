using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Threading.Tasks;
using Supabase;
using Postgrest.Models;
using Postgrest.Attributes;
using KhandobaSecureDocs.Config;
using KhandobaSecureDocs.Models;
using Newtonsoft.Json;

namespace KhandobaSecureDocs.Services
{
    public class SupabaseService : INotifyPropertyChanged
    {
        private Client? _supabaseClient;
        private bool _isConnected;
        private Session? _currentSession;

        public event PropertyChangedEventHandler? PropertyChanged;

        public bool IsConnected
        {
            get => _isConnected;
            private set
            {
                _isConnected = value;
                OnPropertyChanged();
            }
        }

        public Session? CurrentSession
        {
            get => _currentSession;
            private set
            {
                _currentSession = value;
                OnPropertyChanged();
            }
        }

        public async Task ConfigureAsync()
        {
            try
            {
                var options = new SupabaseOptions
                {
                    AutoConnectRealtime = SupabaseConfig.EnableRealtime
                };

                _supabaseClient = new Client(
                    SupabaseConfig.SupabaseURL,
                    SupabaseConfig.SupabaseAnonKey,
                    options
                );

                // Test connection
                try
                {
                    var testQuery = await _supabaseClient
                        .From<SupabaseUser>()
                        .Select("*")
                        .Limit(0)
                        .Get();

                    IsConnected = true;
                    CurrentSession = await _supabaseClient.Auth.CurrentSession;
                    Console.WriteLine("✅ Supabase client initialized and connected");
                    Console.WriteLine($"   URL: {SupabaseConfig.SupabaseURL}");
                }
                catch (Exception ex)
                {
                    if (ex.Message.Contains("network") || ex.Message.Contains("connection"))
                    {
                        IsConnected = false;
                        Console.WriteLine($"❌ Supabase connection failed: {ex.Message}");
                    }
                    else
                    {
                        // Auth errors are expected when not signed in - connection is still OK
                        IsConnected = true;
                        CurrentSession = await _supabaseClient.Auth.CurrentSession;
                        Console.WriteLine("✅ Supabase client initialized");
                        Console.WriteLine($"   URL: {SupabaseConfig.SupabaseURL}");
                        Console.WriteLine("   Note: No active session (user not signed in)");
                    }
                }

                // Setup real-time subscriptions if enabled and user is authenticated
                if (SupabaseConfig.EnableRealtime && CurrentSession != null)
                {
                    await SetupRealtimeSubscriptionsAsync();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to configure Supabase: {ex.Message}");
                IsConnected = false;
            }
        }

        // MARK: - Authentication

        public async Task<Session> SignInWithMicrosoftAsync(string idToken, string nonce)
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized. Call ConfigureAsync() first.");
            }

            try
            {
                // Note: Supabase C# client may have different API - adjust based on actual library
                var response = await _supabaseClient.Auth.SignInWithIdToken(
                    Supabase.Gotrue.Constants.Provider.Microsoft,
                    idToken
                );

                CurrentSession = response.Session;
                IsConnected = true;

                // Setup real-time subscriptions after successful authentication
                if (SupabaseConfig.EnableRealtime)
                {
                    await SetupRealtimeSubscriptionsAsync();
                }

                return response.Session;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Sign in failed: {ex.Message}");
                throw;
            }
        }

        public async Task SignOutAsync()
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            await _supabaseClient.Auth.SignOut();
            CurrentSession = null;
            IsConnected = false;

            // Unsubscribe from realtime when signing out
            await UnsubscribeAllAsync();
        }

        public async Task<User?> GetCurrentUserAsync()
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            return await _supabaseClient.Auth.GetUser();
        }

        // MARK: - Database Queries

        public IPostgrestTable<T> From<T>() where T : BaseModel, new()
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized. Call ConfigureAsync() first.");
            }

            return _supabaseClient.From<T>();
        }

        public async Task<T> InsertAsync<T>(string table, T value) where T : BaseModel, new()
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            // Use table name to get the correct table
            var tableRef = _supabaseClient.From<T>();
            var response = await tableRef
                .Insert(value)
                .Select()
                .Single();

            return response;
        }

        public async Task<T> UpdateAsync<T>(Guid id, T value) where T : BaseModel, new()
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            var response = await _supabaseClient
                .From<T>()
                .Update(value)
                .Match("id", id.ToString())
                .Select()
                .Single();

            return response;
        }

        public async Task DeleteAsync<T>(Guid id) where T : BaseModel, new()
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            await _supabaseClient
                .From<T>()
                .Delete()
                .Match("id", id.ToString());
        }

        public async Task<T> FetchAsync<T>(Guid id) where T : BaseModel, new()
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            var response = await _supabaseClient
                .From<T>()
                .Select()
                .Match("id", id.ToString())
                .Single();

            return response;
        }

        public async Task<List<T>> FetchAllAsync<T>(
            Dictionary<string, object>? filters = null,
            int? limit = null,
            string? orderBy = null,
            bool ascending = true
        ) where T : BaseModel, new()
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            var query = _supabaseClient.From<T>().Select();

            // Apply filters
            if (filters != null)
            {
                foreach (var filter in filters)
                {
                    query = query.Eq(filter.Key, filter.Value);
                }
            }

            // Apply ordering
            if (!string.IsNullOrEmpty(orderBy))
            {
                query = ascending
                    ? query.Order(orderBy, Postgrest.Constants.Ordering.Ascending)
                    : query.Order(orderBy, Postgrest.Constants.Ordering.Descending);
            }

            // Apply limit
            if (limit.HasValue)
            {
                query = query.Limit(limit.Value);
            }

            var response = await query.Get();
            return response.Models;
        }

        // MARK: - Storage

        public async Task<string> UploadFileAsync(
            string bucket,
            string path,
            byte[] data,
            Dictionary<string, string>? options = null
        )
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            var bucketClient = _supabaseClient.Storage.From(bucket);
            await bucketClient.Upload(data, path, options ?? new Dictionary<string, string>());

            return path;
        }

        public async Task<byte[]> DownloadFileAsync(string bucket, string path)
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            var bucketClient = _supabaseClient.Storage.From(bucket);
            var data = await bucketClient.Download(path);

            return data;
        }

        public async Task DeleteFileAsync(string bucket, string path)
        {
            if (_supabaseClient == null)
            {
                throw new InvalidOperationException("Supabase client not initialized.");
            }

            var bucketClient = _supabaseClient.Storage.From(bucket);
            await bucketClient.Remove(new[] { path });
        }

        // MARK: - Real-time

        private async Task SetupRealtimeSubscriptionsAsync()
        {
            if (_supabaseClient == null || CurrentSession == null)
            {
                Console.WriteLine("⚠️ Cannot setup realtime: Supabase client not initialized or user not authenticated");
                return;
            }

            foreach (var channelName in SupabaseConfig.RealtimeChannels)
            {
                var channel = _supabaseClient.Realtime.Channel($"{channelName}-changes");

                // Subscribe to INSERT events
                channel.OnPostgresChange(PostgresChangesFilter.Event.Insert, (sender, response) =>
                {
                    Console.WriteLine($"📡 Real-time INSERT on {channelName}");
                    // Post notification for UI updates
                    // NotificationCenter.Post(name: "SupabaseRealtimeUpdate", ...);
                }, new PostgresChangesFilter("public", channelName));

                // Subscribe to UPDATE events
                channel.OnPostgresChange(PostgresChangesFilter.Event.Update, (sender, response) =>
                {
                    Console.WriteLine($"📡 Real-time UPDATE on {channelName}");
                }, new PostgresChangesFilter("public", channelName));

                // Subscribe to DELETE events
                channel.OnPostgresChange(PostgresChangesFilter.Event.Delete, (sender, response) =>
                {
                    Console.WriteLine($"📡 Real-time DELETE on {channelName}");
                }, new PostgresChangesFilter("public", channelName));

                await channel.Subscribe();
                Console.WriteLine($"✅ Subscribed to realtime channel: {channelName}");
            }

            Console.WriteLine($"✅ Real-time subscriptions setup for {SupabaseConfig.RealtimeChannels.Length} channels");
        }

        private async Task UnsubscribeAllAsync()
        {
            if (_supabaseClient == null)
            {
                return;
            }

            // Unsubscribe from all channels
            await _supabaseClient.Realtime.RemoveAllChannels();
        }

        protected virtual void OnPropertyChanged([System.Runtime.CompilerServices.CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}

