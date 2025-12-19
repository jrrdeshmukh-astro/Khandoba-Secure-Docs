# 🪟 Windows Code Examples - Khandoba Secure Docs

## 📋 Overview

This document provides code examples for key Windows implementation patterns, mapped from the iOS Swift codebase.

---

## 🗄️ Data Layer

### Entity Definition

```csharp
// Data/Entities/UserEntity.cs
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KhandobaSecureDocs.Data.Entities
{
    [Table("Users")]
    public class UserEntity
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        [MaxLength(255)]
        public string MicrosoftUserID { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(255)]
        public string FullName { get; set; } = string.Empty;
        
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        public virtual ICollection<VaultEntity> Vaults { get; set; } = new List<VaultEntity>();
    }
}
```

### DbContext

```csharp
// Data/Database/KhandobaDbContext.cs
using Microsoft.EntityFrameworkCore;
using KhandobaSecureDocs.Data.Entities;

namespace KhandobaSecureDocs.Data.Database
{
    public class KhandobaDbContext : DbContext
    {
        public DbSet<UserEntity> Users { get; set; } = null!;
        public DbSet<VaultEntity> Vaults { get; set; } = null!;
        public DbSet<DocumentEntity> Documents { get; set; } = null!;
        public DbSet<NomineeEntity> Nominees { get; set; } = null!;
        public DbSet<ChatMessageEntity> ChatMessages { get; set; } = null!;

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                var dbPath = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "KhandobaSecureDocs",
                    "khandoba.db"
                );
                
                Directory.CreateDirectory(Path.GetDirectoryName(dbPath)!);
                optionsBuilder.UseSqlite($"Data Source={dbPath}");
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // User-Vault relationship
            modelBuilder.Entity<VaultEntity>()
                .HasOne(v => v.User)
                .WithMany(u => u.Vaults)
                .HasForeignKey(v => v.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // Vault-Document relationship
            modelBuilder.Entity<DocumentEntity>()
                .HasOne(d => d.Vault)
                .WithMany(v => v.Documents)
                .HasForeignKey(d => d.VaultId)
                .OnDelete(DeleteBehavior.Cascade);

            // Configure indexes
            modelBuilder.Entity<UserEntity>()
                .HasIndex(u => u.MicrosoftUserID)
                .IsUnique();

            modelBuilder.Entity<VaultEntity>()
                .HasIndex(v => new { v.UserId, v.Name })
                .IsUnique();
        }
    }
}
```

### Repository Pattern

```csharp
// Data/Repositories/IVaultRepository.cs
namespace KhandobaSecureDocs.Data.Repositories
{
    public interface IVaultRepository
    {
        Task<List<VaultEntity>> GetAllByUserIdAsync(Guid userId);
        Task<VaultEntity?> GetByIdAsync(Guid id);
        Task<VaultEntity> CreateAsync(VaultEntity vault);
        Task<VaultEntity> UpdateAsync(VaultEntity vault);
        Task DeleteAsync(Guid id);
    }
}

// Data/Repositories/VaultRepository.cs
using Microsoft.EntityFrameworkCore;
using KhandobaSecureDocs.Data.Database;
using KhandobaSecureDocs.Data.Entities;

namespace KhandobaSecureDocs.Data.Repositories
{
    public class VaultRepository : IVaultRepository
    {
        private readonly KhandobaDbContext _context;

        public VaultRepository(KhandobaDbContext context)
        {
            _context = context;
        }

        public async Task<List<VaultEntity>> GetAllByUserIdAsync(Guid userId)
        {
            return await _context.Vaults
                .Include(v => v.Documents)
                .Where(v => v.UserId == userId)
                .OrderBy(v => v.Name)
                .ToListAsync();
        }

        public async Task<VaultEntity?> GetByIdAsync(Guid id)
        {
            return await _context.Vaults
                .Include(v => v.Documents)
                .Include(v => v.User)
                .FirstOrDefaultAsync(v => v.Id == id);
        }

        public async Task<VaultEntity> CreateAsync(VaultEntity vault)
        {
            vault.CreatedAt = DateTime.UtcNow;
            vault.UpdatedAt = DateTime.UtcNow;
            
            _context.Vaults.Add(vault);
            await _context.SaveChangesAsync();
            return vault;
        }

        public async Task<VaultEntity> UpdateAsync(VaultEntity vault)
        {
            vault.UpdatedAt = DateTime.UtcNow;
            _context.Vaults.Update(vault);
            await _context.SaveChangesAsync();
            return vault;
        }

        public async Task DeleteAsync(Guid id)
        {
            var vault = await _context.Vaults.FindAsync(id);
            if (vault != null)
            {
                _context.Vaults.Remove(vault);
                await _context.SaveChangesAsync();
            }
        }
    }
}
```

---

## 🔐 Services

### Authentication Service

```csharp
// Services/AuthenticationService.cs
using Microsoft.Graph;
using Microsoft.Graph.Auth;
using Microsoft.Identity.Client;
using KhandobaSecureDocs.Data.Entities;
using KhandobaSecureDocs.Data.Repositories;
using System.ComponentModel;

namespace KhandobaSecureDocs.Services
{
    public class AuthenticationService : INotifyPropertyChanged
    {
        private readonly IUserRepository _userRepository;
        private GraphServiceClient? _graphClient;
        private UserEntity? _currentUser;
        private bool _isAuthenticated;

        public event PropertyChangedEventHandler? PropertyChanged;

        public UserEntity? CurrentUser
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

        public AuthenticationService(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<bool> SignInWithMicrosoftAsync()
        {
            try
            {
                var publicClientApp = PublicClientApplicationBuilder
                    .Create(AppConfig.AzureClientId)
                    .WithRedirectUri(AppConfig.AzureRedirectUri)
                    .WithAuthority(AzureCloudInstance.AzurePublic, AppConfig.AzureTenantId)
                    .Build();

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
                    var authProvider = new ClientCredentialProvider(publicClientApp, scopes);
                    _graphClient = new GraphServiceClient(authProvider);

                    var graphUser = await _graphClient.Me.Request().GetAsync();
                    CurrentUser = await CreateOrUpdateUserAsync(graphUser);
                    IsAuthenticated = true;
                    return true;
                }

                return false;
            }
            catch (Exception ex)
            {
                // Log error
                return false;
            }
        }

        private async Task<UserEntity> CreateOrUpdateUserAsync(User graphUser)
        {
            var existingUser = await _userRepository.GetByMicrosoftIdAsync(graphUser.Id);
            
            if (existingUser != null)
            {
                existingUser.FullName = graphUser.DisplayName ?? string.Empty;
                existingUser.Email = graphUser.Mail ?? graphUser.UserPrincipalName ?? string.Empty;
                existingUser.UpdatedAt = DateTime.UtcNow;
                return await _userRepository.UpdateAsync(existingUser);
            }
            else
            {
                var newUser = new UserEntity
                {
                    MicrosoftUserID = graphUser.Id,
                    FullName = graphUser.DisplayName ?? string.Empty,
                    Email = graphUser.Mail ?? graphUser.UserPrincipalName ?? string.Empty
                };
                return await _userRepository.CreateAsync(newUser);
            }
        }

        public async Task SignOutAsync()
        {
            var publicClientApp = PublicClientApplicationBuilder
                .Create(AppConfig.AzureClientId)
                .Build();

            var accounts = await publicClientApp.GetAccountsAsync();
            foreach (var account in accounts)
            {
                await publicClientApp.RemoveAsync(account);
            }

            CurrentUser = null;
            IsAuthenticated = false;
            _graphClient = null;
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
```

### Encryption Service

```csharp
// Services/EncryptionService.cs
using Windows.Security.Cryptography;
using Windows.Security.Cryptography.DataProtection;
using System.Security.Cryptography;
using System.Text;

namespace KhandobaSecureDocs.Services
{
    public class EncryptionService
    {
        // AES-256-GCM encryption (like CryptoKit)
        public async Task<byte[]> EncryptAES256GCMAsync(byte[] data, byte[] key)
        {
            using var aes = Aes.Create();
            aes.Key = key;
            aes.Mode = CipherMode.GCM;
            aes.GenerateIV();

            using var encryptor = aes.CreateEncryptor();
            using var ms = new MemoryStream();
            
            // Write IV
            ms.Write(aes.IV, 0, aes.IV.Length);
            
            // Encrypt data
            using (var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write))
            {
                await cs.WriteAsync(data, 0, data.Length);
            }
            
            // Get authentication tag (GCM)
            var tag = aes.Tag;
            ms.Write(tag, 0, tag.Length);
            
            return ms.ToArray();
        }

        public async Task<byte[]> DecryptAES256GCMAsync(byte[] encryptedData, byte[] key)
        {
            using var aes = Aes.Create();
            aes.Key = key;
            aes.Mode = CipherMode.GCM;

            // Extract IV (first 12 bytes for GCM)
            var iv = new byte[12];
            Array.Copy(encryptedData, 0, iv, 0, 12);
            aes.IV = iv;

            // Extract tag (last 16 bytes)
            var tag = new byte[16];
            Array.Copy(encryptedData, encryptedData.Length - 16, tag, 0, 16);
            aes.Tag = tag;

            // Extract ciphertext (middle part)
            var ciphertext = new byte[encryptedData.Length - 12 - 16];
            Array.Copy(encryptedData, 12, ciphertext, 0, ciphertext.Length);

            using var decryptor = aes.CreateDecryptor();
            using var ms = new MemoryStream(ciphertext);
            using var cs = new CryptoStream(ms, decryptor, CryptoStreamMode.Read);
            using var result = new MemoryStream();
            
            await cs.CopyToAsync(result);
            return result.ToArray();
        }

        // Windows Data Protection API (DPAPI)
        public async Task<byte[]> EncryptWithDPAPIAsync(byte[] data)
        {
            var provider = new DataProtectionProvider("LOCAL=user");
            var buffer = CryptographicBuffer.CreateFromByteArray(data);
            var encryptedBuffer = await provider.ProtectAsync(buffer);
            
            CryptographicBuffer.CopyToByteArray(encryptedBuffer, out byte[] encrypted);
            return encrypted;
        }

        public async Task<byte[]> DecryptWithDPAPIAsync(byte[] encryptedData)
        {
            var provider = new DataProtectionProvider("LOCAL=user");
            var buffer = CryptographicBuffer.CreateFromByteArray(encryptedData);
            var decryptedBuffer = await provider.UnprotectAsync(buffer);
            
            CryptographicBuffer.CopyToByteArray(decryptedBuffer, out byte[] decrypted);
            return decrypted;
        }
    }
}
```

### Vault Service

```csharp
// Services/VaultService.cs
using KhandobaSecureDocs.Data.Entities;
using KhandobaSecureDocs.Data.Repositories;
using System.ComponentModel;

namespace KhandobaSecureDocs.Services
{
    public class VaultService : INotifyPropertyChanged
    {
        private readonly IVaultRepository _vaultRepository;
        private readonly EncryptionService _encryptionService;
        private List<VaultEntity> _vaults = new();

        public event PropertyChangedEventHandler? PropertyChanged;

        public List<VaultEntity> Vaults
        {
            get => _vaults;
            private set
            {
                _vaults = value;
                OnPropertyChanged();
            }
        }

        public VaultService(IVaultRepository vaultRepository, EncryptionService encryptionService)
        {
            _vaultRepository = vaultRepository;
            _encryptionService = encryptionService;
        }

        public async Task LoadVaultsAsync(Guid userId)
        {
            Vaults = await _vaultRepository.GetAllByUserIdAsync(userId);
        }

        public async Task<VaultEntity> CreateVaultAsync(string name, string password, Guid userId)
        {
            // Derive encryption key from password
            var key = DeriveKeyFromPassword(password);
            
            var vault = new VaultEntity
            {
                Id = Guid.NewGuid(),
                Name = name,
                UserId = userId,
                EncryptionKeyHash = HashPassword(password), // Store hash, not password
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            return await _vaultRepository.CreateAsync(vault);
        }

        public async Task<bool> UnlockVaultAsync(Guid vaultId, string password)
        {
            var vault = await _vaultRepository.GetByIdAsync(vaultId);
            if (vault == null) return false;

            // Verify password hash
            if (!VerifyPassword(password, vault.EncryptionKeyHash))
            {
                return false;
            }

            // Vault unlocked - store in session
            return true;
        }

        private byte[] DeriveKeyFromPassword(string password)
        {
            using var rfc2898 = new Rfc2898DeriveBytes(
                Encoding.UTF8.GetBytes(password),
                new byte[16], // Salt
                10000 // Iterations
            );
            return rfc2898.GetBytes(32); // 256-bit key
        }

        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hash);
        }

        private bool VerifyPassword(string password, string hash)
        {
            return HashPassword(password) == hash;
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
```

---

## 🎨 ViewModels

### Vault ViewModel

```csharp
// ViewModels/VaultViewModel.cs
using KhandobaSecureDocs.Data.Entities;
using KhandobaSecureDocs.Services;
using System.ComponentModel;
using System.Collections.ObjectModel;

namespace KhandobaSecureDocs.ViewModels
{
    public class VaultViewModel : INotifyPropertyChanged
    {
        private readonly VaultService _vaultService;
        private readonly AuthenticationService _authService;
        private ObservableCollection<VaultEntity> _vaults = new();
        private bool _isLoading;

        public event PropertyChangedEventHandler? PropertyChanged;

        public ObservableCollection<VaultEntity> Vaults
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

        public VaultViewModel(VaultService vaultService, AuthenticationService authService)
        {
            _vaultService = vaultService;
            _authService = authService;
            
            _vaultService.PropertyChanged += OnVaultServiceChanged;
            LoadVaultsAsync();
        }

        private void OnVaultServiceChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(VaultService.Vaults))
            {
                Vaults = new ObservableCollection<VaultEntity>(_vaultService.Vaults);
            }
        }

        private async void LoadVaultsAsync()
        {
            if (_authService.CurrentUser == null) return;

            IsLoading = true;
            try
            {
                await _vaultService.LoadVaultsAsync(_authService.CurrentUser.Id);
            }
            finally
            {
                IsLoading = false;
            }
        }

        public async Task CreateVaultAsync(string name, string password)
        {
            if (_authService.CurrentUser == null) return;

            IsLoading = true;
            try
            {
                await _vaultService.CreateVaultAsync(name, password, _authService.CurrentUser.Id);
                await LoadVaultsAsync();
            }
            finally
            {
                IsLoading = false;
            }
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
```

---

## 🎨 Views (XAML)

### Vault List View

```xml
<!-- Views/Vaults/VaultListView.xaml -->
<Page x:Class="KhandobaSecureDocs.Views.Vaults.VaultListView"
      xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
      xmlns:vm="using:KhandobaSecureDocs.ViewModels">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="20">
            <TextBlock Text="My Vaults" FontSize="32" FontWeight="Bold"/>
            <Button Content="+ New Vault" 
                    Click="OnCreateVaultClick"
                    Margin="20,0,0,0"
                    HorizontalAlignment="Right"/>
        </StackPanel>

        <!-- Vault List -->
        <ListView Grid.Row="1" 
                  ItemsSource="{x:Bind ViewModel.Vaults, Mode=OneWay}"
                  SelectionMode="Single"
                  ItemClick="OnVaultClick">
            <ListView.ItemTemplate>
                <DataTemplate>
                    <Grid Margin="10">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        
                        <!-- Icon -->
                        <SymbolIcon Symbol="Lock" 
                                    Grid.Column="0"
                                    FontSize="24"
                                    Margin="0,0,15,0"/>
                        
                        <!-- Vault Info -->
                        <StackPanel Grid.Column="1">
                            <TextBlock Text="{Binding Name}" 
                                       FontSize="18" 
                                       FontWeight="SemiBold"/>
                            <TextBlock Text="{Binding DocumentCount, StringFormat='{}{0} documents'}" 
                                       FontSize="14" 
                                       Foreground="Gray"/>
                        </StackPanel>
                        
                        <!-- Arrow -->
                        <SymbolIcon Symbol="ChevronRight" 
                                    Grid.Column="2"
                                    Foreground="Gray"/>
                    </Grid>
                </DataTemplate>
            </ListView.ItemTemplate>
        </ListView>

        <!-- Loading Indicator -->
        <ProgressRing Grid.Row="1" 
                      IsActive="{x:Bind ViewModel.IsLoading, Mode=OneWay}"
                      Width="50" 
                      Height="50"
                      HorizontalAlignment="Center"
                      VerticalAlignment="Center"/>
    </Grid>
</Page>
```

```csharp
// Views/Vaults/VaultListView.xaml.cs
using KhandobaSecureDocs.ViewModels;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace KhandobaSecureDocs.Views.Vaults
{
    public sealed partial class VaultListView : Page
    {
        public VaultViewModel ViewModel { get; }

        public VaultListView()
        {
            InitializeComponent();
            ViewModel = App.Services.GetRequiredService<VaultViewModel>();
        }

        private void OnCreateVaultClick(object sender, RoutedEventArgs e)
        {
            // Navigate to create vault view
            Frame.Navigate(typeof(CreateVaultView));
        }

        private void OnVaultClick(object sender, ItemClickEventArgs e)
        {
            if (e.ClickedItem is VaultEntity vault)
            {
                Frame.Navigate(typeof(VaultDetailView), vault.Id);
            }
        }
    }
}
```

---

## 📹 Media Capture

### Video Recording Service

```csharp
// Services/VideoRecordingService.cs
using Windows.Media.Capture;
using Windows.Media.MediaProperties;
using Windows.Storage;

namespace KhandobaSecureDocs.Services
{
    public class VideoRecordingService
    {
        private MediaCapture? _mediaCapture;
        private LowLagMediaRecording? _lowLagRecording;

        public MediaCapture? MediaCapture => _mediaCapture;

        public async Task InitializeAsync()
        {
            _mediaCapture = new MediaCapture();
            
            var settings = new MediaCaptureInitializationSettings
            {
                StreamingCaptureMode = StreamingCaptureMode.VideoAndAudio,
                VideoDeviceId = string.Empty // Use default camera
            };

            await _mediaCapture.InitializeAsync(settings);
        }

        public async Task StartRecordingAsync(StorageFile file)
        {
            if (_mediaCapture == null)
            {
                await InitializeAsync();
            }

            var encodingProfile = MediaEncodingProfile.CreateMp4(VideoEncodingQuality.HD1080p);
            _lowLagRecording = await _mediaCapture!.PrepareLowLagRecordToStorageFileAsync(
                encodingProfile, file);
            
            await _lowLagRecording.StartAsync();
        }

        public async Task StopRecordingAsync()
        {
            if (_lowLagRecording != null)
            {
                await _lowLagRecording.StopAsync();
                await _lowLagRecording.FinishAsync();
                _lowLagRecording = null;
            }
        }

        public void Dispose()
        {
            _mediaCapture?.Dispose();
        }
    }
}
```

---

## 🤖 AI/ML Services

### Document Indexing Service

```csharp
// Services/DocumentIndexingService.cs
using Azure.AI.TextAnalytics;
using KhandobaSecureDocs.Data.Entities;

namespace KhandobaSecureDocs.Services
{
    public class DocumentIndexingService
    {
        private readonly TextAnalyticsClient _textAnalyticsClient;

        public DocumentIndexingService()
        {
            _textAnalyticsClient = new TextAnalyticsClient(
                new Uri(AppConfig.TextAnalyticsEndpoint),
                new Azure.AzureKeyCredential(AppConfig.TextAnalyticsKey));
        }

        public async Task<DocumentIndex> IndexDocumentAsync(string text, Guid documentId)
        {
            // Language detection
            var languageResult = await _textAnalyticsClient.DetectLanguageAsync(text);
            var language = languageResult.Value.Iso6391Name;

            // Entity extraction
            var entitiesResult = await _textAnalyticsClient.RecognizeEntitiesAsync(text);
            var entities = entitiesResult.Value.Select(e => new EntityInfo
            {
                Text = e.Text,
                Category = e.Category.ToString(),
                Confidence = e.ConfidenceScore
            }).ToList();

            // Key phrase extraction
            var keyPhrasesResult = await _textAnalyticsClient.ExtractKeyPhrasesAsync(text);
            var keyPhrases = keyPhrasesResult.Value.ToList();

            // Sentiment analysis
            var sentimentResult = await _textAnalyticsClient.AnalyzeSentimentAsync(text);
            var sentiment = sentimentResult.Value.Sentiment.ToString();

            return new DocumentIndex
            {
                DocumentId = documentId,
                Language = language,
                Entities = entities,
                KeyPhrases = keyPhrases,
                Sentiment = sentiment,
                CreatedAt = DateTime.UtcNow
            };
        }
    }
}
```

---

## 💳 Subscription Service

```csharp
// Services/SubscriptionService.cs
using Windows.ApplicationModel.Store;
using Windows.Services.Store;

namespace KhandobaSecureDocs.Services
{
    public class SubscriptionService
    {
        private StoreContext? _storeContext;

        public async Task InitializeAsync()
        {
            _storeContext = StoreContext.GetDefault();
        }

        public async Task<List<SubscriptionProduct>> GetAvailableSubscriptionsAsync()
        {
            if (_storeContext == null)
            {
                await InitializeAsync();
            }

            var storeProducts = await _storeContext!.GetStoreProductsAsync(
                new string[] { "Durable" },
                new string[] { "monthly_premium", "yearly_premium" });

            var products = new List<SubscriptionProduct>();
            foreach (var product in storeProducts.Products.Values)
            {
                products.Add(new SubscriptionProduct
                {
                    Id = product.StoreId,
                    Title = product.Title,
                    Description = product.Description,
                    Price = product.Price.FormattedPrice,
                    IsPurchased = product.IsInUserCollection
                });
            }

            return products;
        }

        public async Task<bool> PurchaseSubscriptionAsync(string productId)
        {
            if (_storeContext == null)
            {
                await InitializeAsync();
            }

            var result = await _storeContext!.RequestPurchaseAsync(productId);
            return result.Status == StorePurchaseStatus.Succeeded;
        }
    }
}
```

---

## 🔧 Dependency Injection Setup

```csharp
// App.xaml.cs
using Microsoft.Extensions.DependencyInjection;

public partial class App : Application
{
    public static IServiceProvider Services { get; private set; } = null!;

    protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        var services = new ServiceCollection();
        ConfigureServices(services);
        Services = services.BuildServiceProvider();

        _mainWindow = new MainWindow();
        _mainWindow.Activate();
    }

    private void ConfigureServices(IServiceCollection services)
    {
        // Database
        services.AddDbContext<KhandobaDbContext>();

        // Repositories
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IVaultRepository, VaultRepository>();
        services.AddScoped<IDocumentRepository, DocumentRepository>();

        // Services
        services.AddSingleton<AuthenticationService>();
        services.AddSingleton<EncryptionService>();
        services.AddSingleton<VaultService>();
        services.AddSingleton<DocumentService>();
        services.AddSingleton<DocumentIndexingService>();
        services.AddSingleton<VideoRecordingService>();
        services.AddSingleton<SubscriptionService>();

        // ViewModels
        services.AddTransient<AuthenticationViewModel>();
        services.AddTransient<VaultViewModel>();
        services.AddTransient<DocumentViewModel>();
    }
}
```

---

**Last Updated:** December 2024  
**Status:** Code examples ready for implementation
