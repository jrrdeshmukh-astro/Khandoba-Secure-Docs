# 🪟 Windows Port Guide - Khandoba Secure Docs

## 🎯 Overview

This guide provides a complete roadmap for porting the iOS Khandoba Secure Docs app to Windows. The Windows version will maintain feature parity with the iOS app while using Windows-native technologies and frameworks.

---

## 🏗️ Architecture Mapping

### iOS → Windows Technology Stack

| iOS Component | Windows Equivalent |
|--------------|-------------------|
| SwiftUI | WinUI 3 (XAML + C#) |
| SwiftData | Entity Framework Core + SQLite |
| CloudKit | Azure Cosmos DB / SQL Server |
| Apple Sign In | Microsoft Account / Azure AD |
| CryptoKit | Windows.Security.Cryptography |
| AVFoundation | MediaCapture API |
| NaturalLanguage | Windows ML + Azure Cognitive Services |
| StoreKit | Microsoft Store APIs |
| Combine | Reactive Extensions (Rx.NET) |
| Swift Concurrency | async/await (C#) |

---

## 📁 Project Structure

```
KhandobaSecureDocs.Windows/
├── KhandobaSecureDocs/
│   ├── KhandobaSecureDocs.csproj
│   ├── App.xaml
│   ├── App.xaml.cs
│   ├── MainWindow.xaml
│   ├── MainWindow.xaml.cs
│   ├── Config/
│   │   └── AppConfig.cs
│   ├── Data/
│   │   ├── Database/
│   │   │   ├── KhandobaDbContext.cs
│   │   │   └── Migrations/
│   │   ├── Entities/
│   │   │   ├── UserEntity.cs
│   │   │   ├── VaultEntity.cs
│   │   │   ├── DocumentEntity.cs
│   │   │   └── ... (all entities)
│   │   └── Repositories/
│   │       ├── UserRepository.cs
│   │       ├── VaultRepository.cs
│   │       └── ... (all repositories)
│   ├── Services/
│   │   ├── AuthenticationService.cs
│   │   ├── EncryptionService.cs
│   │   ├── VaultService.cs
│   │   ├── DocumentService.cs
│   │   ├── DocumentIndexingService.cs
│   │   ├── FormalLogicEngine.cs
│   │   ├── InferenceEngine.cs
│   │   ├── TranscriptionService.cs
│   │   ├── VoiceMemoService.cs
│   │   ├── MLThreatAnalysisService.cs
│   │   ├── DualKeyApprovalService.cs
│   │   ├── ThreatMonitoringService.cs
│   │   ├── LocationService.cs
│   │   ├── SubscriptionService.cs
│   │   └── ... (all services)
│   ├── ViewModels/
│   │   ├── AuthenticationViewModel.cs
│   │   ├── VaultViewModel.cs
│   │   ├── DocumentViewModel.cs
│   │   └── ... (all ViewModels)
│   ├── Views/
│   │   ├── Authentication/
│   │   │   ├── WelcomeView.xaml
│   │   │   └── AccountSetupView.xaml
│   │   ├── Vaults/
│   │   │   ├── VaultListView.xaml
│   │   │   └── VaultDetailView.xaml
│   │   ├── Documents/
│   │   │   ├── DocumentUploadView.xaml
│   │   │   └── DocumentPreviewView.xaml
│   │   ├── Media/
│   │   │   ├── VideoRecordingView.xaml
│   │   │   └── VoiceRecordingView.xaml
│   │   └── ... (all views)
│   ├── Theme/
│   │   ├── UnifiedTheme.cs
│   │   ├── ColorPalette.cs
│   │   └── Typography.cs
│   └── Utils/
│       ├── PlatformDetection.cs
│       └── Extensions.cs
├── KhandobaSecureDocs.Tests/
└── KhandobaSecureDocs.sln
```

---

## 🔧 Setup Instructions

### 1. Create Visual Studio Project

1. Open Visual Studio 2022
2. Create New Project → **Blank App, Packaged (WinUI 3 in Desktop)**
3. Name: "KhandobaSecureDocs"
4. Target Framework: **Windows 10, version 1809 (10.0; Build 17763)** or later
5. Minimum Version: **Windows 10, version 1809**
6. Language: **C#**

### 2. Configure Project File

#### `KhandobaSecureDocs.csproj`
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows10.0.17763.0</TargetFramework>
    <TargetPlatformMinVersion>10.0.17763.0</TargetPlatformMinVersion>
    <RootNamespace>KhandobaSecureDocs</RootNamespace>
    <ApplicationManifest>app.manifest</ApplicationManifest>
    <Platforms>x64;x86;ARM64</Platforms>
    <RuntimeIdentifiers>win10-x64;win10-x86;win10-arm64</RuntimeIdentifiers>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.WindowsAppSDK" Version="1.5.240627000" />
    <PackageReference Include="Microsoft.Windows.SDK.BuildTools" Version="10.0.22621.2428" />
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.0" />
    <PackageReference Include="Microsoft.Toolkit.Win32.UI.Controls" Version="6.1.2" />
    <PackageReference Include="Microsoft.Graph" Version="5.0.0" />
    <PackageReference Include="System.Reactive" Version="5.0.0" />
    <PackageReference Include="Windows.Media.SpeechSynthesis" Version="10.0.22621.0" />
    <PackageReference Include="Windows.Media.SpeechRecognition" Version="10.0.22621.0" />
  </ItemGroup>
</Project>
```

### 3. Configure Package.appxmanifest

```xml
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:mp="http://schemas.microsoft.com/appx/2014/phone/manifest"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities"
         IgnorableNamespaces="uap rescap">

  <Identity Name="KhandobaSecureDocs"
            Publisher="CN=YourPublisher"
            Version="1.0.0.0" />

  <mp:PhoneIdentity PhoneProductId="..." PhonePublisherId="..." />

  <Properties>
    <DisplayName>Khandoba Secure Docs</DisplayName>
    <PublisherDisplayName>Khandoba</PublisherDisplayName>
    <Logo>Assets\StoreLogo.png</Logo>
  </Properties>

  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" MaxVersionTested="10.0.22621.0" />
  </Dependencies>

  <Resources>
    <Resource Language="x-generate" />
  </Resources>

  <Applications>
    <Application Id="App"
                 Executable="$targetnametoken$.exe"
                 EntryPoint="$targetentrypoint$">
      <uap:VisualElements DisplayName="Khandoba Secure Docs"
                          Description="Enterprise-grade secure document management"
                          Square150x150Logo="Assets\Square150x150Logo.png"
                          Square44x44Logo="Assets\Square44x44Logo.png"
                          BackgroundColor="transparent">
        <uap:DefaultTile Wide310x150Logo="Assets\Wide310x150Logo.png" />
        <uap:SplashScreen Image="Assets\SplashScreen.png" />
      </uap:VisualElements>

      <Extensions>
        <uap:Extension Category="windows.protocol">
          <uap:Protocol Name="khandoba-securedocs" />
        </uap:Extension>
      </Extensions>
    </Application>
  </Applications>

  <Capabilities>
    <rescap:Capability Name="allowElevation" />
    <Capability Name="internetClient" />
    <Capability Name="privateNetworkClientServer" />
    <Capability Name="picturesLibrary" />
    <Capability Name="videosLibrary" />
    <Capability Name="musicLibrary" />
    <Capability Name="documentsLibrary" />
    <DeviceCapability Name="webcam" />
    <DeviceCapability Name="microphone" />
    <DeviceCapability Name="location" />
  </Capabilities>
</Package>
```

---

## 📊 Data Layer Porting

### Models → Entity Framework Entities

#### Example: User Model

**iOS (SwiftData):**
```swift
@Model
final class User {
    var id: UUID = UUID()
    var appleUserID: String = ""
    var fullName: String = ""
    // ...
}
```

**Windows (Entity Framework):**
```csharp
public class UserEntity
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    
    [Required]
    [MaxLength(255)]
    public string MicrosoftUserID { get; set; } = string.Empty; // Windows equivalent
    
    [Required]
    [MaxLength(255)]
    public string FullName { get; set; } = string.Empty;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual ICollection<VaultEntity> Vaults { get; set; } = new List<VaultEntity>();
}
```

### DbContext

```csharp
using Microsoft.EntityFrameworkCore;

public class KhandobaDbContext : DbContext
{
    public DbSet<UserEntity> Users { get; set; }
    public DbSet<VaultEntity> Vaults { get; set; }
    public DbSet<DocumentEntity> Documents { get; set; }
    // ... all entities

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        var dbPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "KhandobaSecureDocs",
            "khandoba.db"
        );
        
        Directory.CreateDirectory(Path.GetDirectoryName(dbPath)!);
        optionsBuilder.UseSqlite($"Data Source={dbPath}");
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure relationships
        modelBuilder.Entity<VaultEntity>()
            .HasOne(v => v.User)
            .WithMany(u => u.Vaults)
            .HasForeignKey(v => v.UserId)
            .OnDelete(DeleteBehavior.Cascade);
        
        // ... other configurations
    }
}
```

### Repository Pattern

```csharp
public interface IUserRepository
{
    Task<UserEntity?> GetByIdAsync(Guid id);
    Task<UserEntity?> GetByMicrosoftIdAsync(string microsoftId);
    Task<UserEntity> CreateAsync(UserEntity user);
    Task<UserEntity> UpdateAsync(UserEntity user);
    Task DeleteAsync(Guid id);
}

public class UserRepository : IUserRepository
{
    private readonly KhandobaDbContext _context;

    public UserRepository(KhandobaDbContext context)
    {
        _context = context;
    }

    public async Task<UserEntity?> GetByIdAsync(Guid id)
    {
        return await _context.Users
            .Include(u => u.Vaults)
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<UserEntity> CreateAsync(UserEntity user)
    {
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        return user;
    }
    
    // ... other methods
}
```

---

## 🔐 Service Layer Porting

### Authentication Service

**iOS Pattern:**
```swift
@MainActor
final class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
}
```

**Windows Pattern:**
```csharp
using System.Reactive.Subjects;
using Microsoft.Graph;

public class AuthenticationService : INotifyPropertyChanged
{
    private readonly GraphServiceClient _graphClient;
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

    public async Task<bool> SignInWithMicrosoftAsync()
    {
        try
        {
            // Use Microsoft Authentication Library (MSAL)
            var authResult = await AcquireTokenSilentAsync();
            
            // Get user info from Microsoft Graph
            var graphUser = await _graphClient.Me.Request().GetAsync();
            
            // Create or update user in local database
            var user = await CreateOrUpdateUserAsync(graphUser);
            CurrentUser = user;
            IsAuthenticated = true;
            
            return true;
        }
        catch (Exception ex)
        {
            // Handle error
            return false;
        }
    }
}
```

### Encryption Service

**iOS (CryptoKit):**
```swift
import CryptoKit

func encrypt(data: Data, key: SymmetricKey) -> Data {
    let sealedBox = try AES.GCM.seal(data, using: key)
    return sealedBox.combined!
}
```

**Windows (Windows.Security.Cryptography):**
```csharp
using Windows.Security.Cryptography;
using Windows.Security.Cryptography.DataProtection;
using System.Security.Cryptography;

public class EncryptionService
{
    public async Task<byte[]> EncryptAsync(byte[] data, string keyAlias)
    {
        // Use Windows Data Protection API (DPAPI) or CNG
        var provider = new DataProtectionProvider("LOCAL=user");
        
        var buffer = CryptographicBuffer.CreateFromByteArray(data);
        var encryptedBuffer = await provider.ProtectAsync(buffer);
        
        CryptographicBuffer.CopyToByteArray(encryptedBuffer, out byte[] encrypted);
        return encrypted;
    }

    public async Task<byte[]> DecryptAsync(byte[] encryptedData, string keyAlias)
    {
        var provider = new DataProtectionProvider("LOCAL=user");
        
        var buffer = CryptographicBuffer.CreateFromByteArray(encryptedData);
        var decryptedBuffer = await provider.UnprotectAsync(buffer);
        
        CryptographicBuffer.CopyToByteArray(decryptedBuffer, out byte[] decrypted);
        return decrypted;
    }
    
    // For AES-256-GCM (like CryptoKit)
    public byte[] EncryptAES256GCM(byte[] data, byte[] key)
    {
        using var aes = Aes.Create();
        aes.Key = key;
        aes.Mode = CipherMode.GCM;
        aes.GenerateIV();
        
        using var encryptor = aes.CreateEncryptor();
        using var ms = new MemoryStream();
        ms.Write(aes.IV, 0, aes.IV.Length);
        
        using (var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write))
        {
            cs.Write(data, 0, data.Length);
        }
        
        return ms.ToArray();
    }
}
```

---

## 🎨 UI Layer Porting

### SwiftUI → WinUI 3 (XAML)

#### Example: Welcome View

**iOS (SwiftUI):**
```swift
struct WelcomeView: View {
    var body: some View {
        VStack {
            Text("Welcome")
            Button("Sign In") { }
        }
    }
}
```

**Windows (WinUI 3 XAML):**
```xml
<!-- WelcomeView.xaml -->
<Page x:Class="KhandobaSecureDocs.Views.Authentication.WelcomeView"
      xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
      xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Grid>
        <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
            <TextBlock Text="Welcome" 
                       FontSize="32" 
                       HorizontalAlignment="Center"
                       Margin="0,0,0,20"/>
            <Button Content="Sign In" 
                    Click="OnSignInClick"
                    HorizontalAlignment="Center"/>
        </StackPanel>
    </Grid>
</Page>
```

```csharp
// WelcomeView.xaml.cs
public sealed partial class WelcomeView : Page
{
    private readonly AuthenticationViewModel _viewModel;

    public WelcomeView()
    {
        InitializeComponent();
        _viewModel = App.Current.Services.GetService<AuthenticationViewModel>()!;
        DataContext = _viewModel;
    }

    private async void OnSignInClick(object sender, RoutedEventArgs e)
    {
        await _viewModel.SignInAsync();
    }
}
```

### Navigation

**iOS:**
```swift
NavigationStack {
    NavigationLink("Vaults") {
        VaultListView()
    }
}
```

**Windows:**
```csharp
// MainWindow.xaml.cs
public sealed partial class MainWindow : Window
{
    private Frame? _contentFrame;

    public MainWindow()
    {
        InitializeComponent();
        _contentFrame = ContentFrame;
        NavigateToWelcome();
    }

    private void NavigateToWelcome()
    {
        _contentFrame?.Navigate(typeof(WelcomeView));
    }

    private void NavigateToVaults()
    {
        _contentFrame?.Navigate(typeof(VaultListView));
    }
}
```

---

## 🤖 AI/ML Services Porting

### Document Indexing

**iOS (NaturalLanguage):**
```swift
import NaturalLanguage

let tagger = NLTagger(tagSchemes: [.nameType])
tagger.string = text
// Extract entities
```

**Windows (Azure Cognitive Services + Windows ML):**
```csharp
using Azure.AI.TextAnalytics;
using Windows.Media.AI;

public class DocumentIndexingService
{
    private readonly TextAnalyticsClient _textAnalyticsClient;
    private readonly LanguageUnderstandingModel _luisModel;

    public async Task<DocumentIndex> IndexDocumentAsync(string text)
    {
        // Language detection
        var languageResult = await _textAnalyticsClient.DetectLanguageAsync(text);
        var language = languageResult.Value.Iso6391Name;

        // Entity extraction
        var entitiesResult = await _textAnalyticsClient.RecognizeEntitiesAsync(text);
        var entities = entitiesResult.Value.Select(e => new Entity
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
        var sentiment = sentimentResult.Value.Sentiment;

        return new DocumentIndex
        {
            Entities = entities,
            KeyPhrases = keyPhrases,
            Sentiment = sentiment,
            Language = language
        };
    }
}
```

### Text Recognition (OCR)

**Windows (Windows.Media.Ocr):**
```csharp
using Windows.Media.Ocr;
using Windows.Graphics.Imaging;

public class OCRService
{
    public async Task<string> ExtractTextFromImageAsync(SoftwareBitmap bitmap)
    {
        var ocrEngine = OcrEngine.TryCreateFromUserProfileLanguages();
        if (ocrEngine == null)
        {
            ocrEngine = OcrEngine.TryCreateFromLanguage(new Language("en"));
        }

        var ocrResult = await ocrEngine.RecognizeAsync(bitmap);
        
        var text = string.Join(" ", 
            ocrResult.Lines.SelectMany(line => 
                line.Words.Select(word => word.Text)));
        
        return text;
    }
}
```

---

## 📹 Media Features Porting

### Video Recording

**iOS (AVFoundation):**
```swift
let captureSession = AVCaptureSession()
let videoOutput = AVCaptureMovieFileOutput()
```

**Windows (MediaCapture):**
```csharp
using Windows.Media.Capture;
using Windows.Media.MediaProperties;
using Windows.Storage;

public class VideoRecordingService
{
    private MediaCapture? _mediaCapture;
    private LowLagMediaRecording? _lowLagRecording;

    public async Task InitializeAsync()
    {
        _mediaCapture = new MediaCapture();
        
        var settings = new MediaCaptureInitializationSettings
        {
            StreamingCaptureMode = StreamingCaptureMode.Video,
            VideoDeviceId = string.Empty // Use default camera
        };

        await _mediaCapture.InitializeAsync(settings);
    }

    public async Task StartRecordingAsync(StorageFile file)
    {
        if (_mediaCapture == null) return;

        var encodingProfile = MediaEncodingProfile.CreateMp4(VideoEncodingQuality.HD1080p);
        _lowLagRecording = await _mediaCapture.PrepareLowLagRecordToStorageFileAsync(
            encodingProfile, file);
        
        await _lowLagRecording.StartAsync();
    }

    public async Task StopRecordingAsync()
    {
        if (_lowLagRecording != null)
        {
            await _lowLagRecording.StopAsync();
            await _lowLagRecording.FinishAsync();
        }
    }
}
```

### Voice Recording

**Windows (MediaCapture):**
```csharp
public class VoiceRecordingService
{
    private MediaCapture? _mediaCapture;
    private LowLagMediaRecording? _lowLagRecording;

    public async Task StartRecordingAsync(StorageFile file)
    {
        _mediaCapture = new MediaCapture();
        
        var settings = new MediaCaptureInitializationSettings
        {
            StreamingCaptureMode = StreamingCaptureMode.Audio,
            AudioDeviceId = string.Empty
        };

        await _mediaCapture.InitializeAsync(settings);

        var encodingProfile = MediaEncodingProfile.CreateM4a(AudioEncodingQuality.High);
        _lowLagRecording = await _mediaCapture.PrepareLowLagRecordToStorageFileAsync(
            encodingProfile, file);
        
        await _lowLagRecording.StartAsync();
    }
}
```

---

## 💳 Subscription System Porting

### StoreKit → Microsoft Store APIs

**iOS (StoreKit):**
```swift
let products = try await Product.products(for: productIDs)
```

**Windows (Microsoft Store SDK):**
```csharp
using Microsoft.Services.Store.Engagement;
using Windows.ApplicationModel.Store;

public class SubscriptionService
{
    private StoreContext? _storeContext;

    public async Task InitializeAsync()
    {
        _storeContext = StoreContext.GetDefault();
    }

    public async Task<List<Product>> GetAvailableSubscriptionsAsync()
    {
        if (_storeContext == null) return new List<Product>();

        var storeProducts = await _storeContext.GetStoreProductsAsync(
            new string[] { "Durable" }, // Subscription products
            new string[] { "monthly_premium", "yearly_premium" });

        var products = new List<Product>();
        foreach (var product in storeProducts.Products.Values)
        {
            products.Add(new Product
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
        if (_storeContext == null) return false;

        var result = await _storeContext.RequestPurchaseAsync(productId);
        return result.Status == StorePurchaseStatus.Succeeded;
    }
}
```

---

## 🔄 State Management

### iOS (Combine)
```swift
@Published var state: StateType
```

### Windows (INotifyPropertyChanged + Reactive Extensions)
```csharp
public class VaultViewModel : INotifyPropertyChanged
{
    private readonly IVaultRepository _vaultRepository;
    private List<Vault> _vaults = new();
    private readonly BehaviorSubject<List<Vault>> _vaultsSubject;

    public event PropertyChangedEventHandler? PropertyChanged;

    public List<Vault> Vaults
    {
        get => _vaults;
        private set
        {
            _vaults = value;
            OnPropertyChanged();
            _vaultsSubject.OnNext(value);
        }
    }

    public IObservable<List<Vault>> VaultsObservable => _vaultsSubject.AsObservable();

    public VaultViewModel(IVaultRepository vaultRepository)
    {
        _vaultRepository = vaultRepository;
        _vaultsSubject = new BehaviorSubject<List<Vault>>(new List<Vault>());
        LoadVaultsAsync();
    }

    private async void LoadVaultsAsync()
    {
        var vaults = await _vaultRepository.GetAllAsync();
        Vaults = vaults;
    }

    protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
```

---

## 📱 Key Implementation Files

### 1. AppConfig.cs
```csharp
public static class AppConfig
{
    public const string AppVersion = "1.0.1";
    public const int AppBuildNumber = 30;
    public const string AppName = "Khandoba Secure Docs";
    
    // Azure Configuration
    public const string AzureTenantId = "your-tenant-id";
    public const string AzureClientId = "your-client-id";
    public const string AzureRedirectUri = "ms-appx-web://Microsoft.AAD.BrokerPlugin/...";
    
    // Azure Cognitive Services
    public const string TextAnalyticsEndpoint = "https://your-region.cognitiveservices.azure.com/";
    public const string TextAnalyticsKey = "your-key";
    
    // Feature Flags
    public const bool EnableAnalytics = true;
    public const bool EnableCrashReporting = true;
    public const bool EnablePushNotifications = true;
    
    // Security
    public const bool RequireBiometricAuth = true;
    public const int SessionTimeoutMinutes = 30;
    public const int MaxLoginAttempts = 5;
}
```

### 2. App.xaml.cs
```csharp
public partial class App : Application
{
    private Window? _mainWindow;
    public static IServiceProvider Services { get; private set; } = null!;

    protected override void OnLaunched(Microsoft.UI.Xaml.LaunchActivatedEventArgs args)
    {
        // Configure dependency injection
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
        // ... all repositories
        
        // Services
        services.AddSingleton<AuthenticationService>();
        services.AddSingleton<EncryptionService>();
        services.AddSingleton<VaultService>();
        // ... all services
        
        // ViewModels
        services.AddTransient<AuthenticationViewModel>();
        services.AddTransient<VaultViewModel>();
        // ... all ViewModels
    }
}
```

### 3. MainWindow.xaml.cs
```csharp
public sealed partial class MainWindow : Window
{
    private readonly AuthenticationService _authService;

    public MainWindow()
    {
        InitializeComponent();
        _authService = App.Services.GetRequiredService<AuthenticationService>();
        
        _authService.PropertyChanged += OnAuthStateChanged;
        NavigateToInitialView();
    }

    private void NavigateToInitialView()
    {
        if (_authService.IsAuthenticated)
        {
            ContentFrame.Navigate(typeof(ClientMainView));
        }
        else
        {
            ContentFrame.Navigate(typeof(WelcomeView));
        }
    }

    private void OnAuthStateChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(AuthenticationService.IsAuthenticated))
        {
            NavigateToInitialView();
        }
    }
}
```

---

## 🚀 Migration Checklist

### Phase 1: Foundation ✅
- [x] Create Windows project structure
- [x] Set up WinUI 3 project
- [x] Configure Package.appxmanifest
- [ ] Port all data models to Entity Framework entities
- [ ] Create repositories
- [ ] Set up database with migrations

### Phase 2: Core Services
- [ ] Port AuthenticationService (Microsoft Account)
- [ ] Port EncryptionService (Windows.Security.Cryptography)
- [ ] Port VaultService
- [ ] Port DocumentService
- [ ] Port LocationService (Windows.Devices.Geolocation)

### Phase 3: AI/ML Services
- [ ] Port DocumentIndexingService (Azure Cognitive Services)
- [ ] Port FormalLogicEngine
- [ ] Port InferenceEngine
- [ ] Port TranscriptionService (Speech-to-Text)
- [ ] Port VoiceMemoService (Text-to-Speech)
- [ ] Port MLThreatAnalysisService

### Phase 4: UI Layer
- [ ] Create theme system (WinUI 3 resources)
- [ ] Port WelcomeView
- [ ] Port AccountSetupView
- [ ] Port VaultListView
- [ ] Port VaultDetailView
- [ ] Port DocumentUploadView
- [ ] Port all other views

### Phase 5: Media Features
- [ ] Port VideoRecordingView (MediaCapture)
- [ ] Port VoiceRecordingView (MediaCapture)
- [ ] Port camera features

### Phase 6: Premium Features
- [ ] Port SubscriptionService (Microsoft Store APIs)
- [ ] Port StoreView
- [ ] Port subscription management

### Phase 7: Testing & Polish
- [ ] Unit tests
- [ ] UI tests
- [ ] Integration tests
- [ ] Performance optimization
- [ ] Security audit
- [ ] Microsoft Store submission

---

## 📚 Additional Resources

### Windows Documentation
- [WinUI 3 Documentation](https://learn.microsoft.com/en-us/windows/apps/winui/winui3/)
- [Entity Framework Core](https://learn.microsoft.com/en-us/ef/core/)
- [Windows.Security.Cryptography](https://learn.microsoft.com/en-us/uwp/api/windows.security.cryptography)
- [MediaCapture API](https://learn.microsoft.com/en-us/uwp/api/windows.media.capture.mediacapture)
- [Microsoft Store APIs](https://learn.microsoft.com/en-us/windows/apps/monetize/in-app-purchases-and-trials)
- [Azure Cognitive Services](https://learn.microsoft.com/en-us/azure/cognitive-services/)

### Migration Patterns
- Combine → Reactive Extensions (Rx.NET)
- SwiftData → Entity Framework Core
- SwiftUI → WinUI 3 XAML
- CryptoKit → Windows.Security.Cryptography
- AVFoundation → MediaCapture API
- NaturalLanguage → Azure Cognitive Services

---

## 🎯 Next Steps

1. **Set up the Windows project** using the structure above
2. **Port data models** first (foundation)
3. **Port core services** (authentication, encryption, vaults)
4. **Port UI layer** (WinUI 3 views)
5. **Port AI/ML services** (Azure Cognitive Services integration)
6. **Port media features** (MediaCapture API)
7. **Port subscription system** (Microsoft Store APIs)
8. **Test and optimize**
9. **Submit to Microsoft Store**

---

## 🔐 Security Considerations

### Windows-Specific Security Features

1. **Windows Hello** (Biometric Authentication)
   ```csharp
   using Windows.Security.Credentials.UI;
   
   var result = await UserConsentVerifier.RequestVerificationAsync("Verify identity");
   if (result == UserConsentVerificationResult.Verified)
   {
       // User authenticated
   }
   ```

2. **Windows Data Protection API (DPAPI)**
   - Use for encrypting sensitive data
   - Automatically uses user's Windows credentials

3. **Windows Credential Manager**
   - Store encrypted credentials securely
   - Access via `Windows.Security.Credentials.PasswordVault`

4. **App Container Isolation**
   - WinUI 3 apps run in sandboxed environment
   - Automatic security boundaries

---

## 🌐 Cloud Integration

### Azure Services

1. **Azure AD** - Authentication
2. **Azure Cosmos DB** - Cloud database (alternative to CloudKit)
3. **Azure Cognitive Services** - AI/ML features
   - Text Analytics (entity extraction, sentiment)
   - Speech Services (TTS/STT)
   - Computer Vision (OCR)
4. **Azure Blob Storage** - Document storage
5. **Azure Key Vault** - Secret management

### Sync Strategy

- **Entity Framework Core** with SQLite for local storage
- **Azure Cosmos DB** for cloud sync
- **Conflict Resolution**: Last-write-wins with manual override

---

**Status:** Foundation created, ready for implementation  
**Last Updated:** December 2024  
**Target Platform:** Windows 10/11 (Desktop)  
**Framework:** WinUI 3 + .NET 8
