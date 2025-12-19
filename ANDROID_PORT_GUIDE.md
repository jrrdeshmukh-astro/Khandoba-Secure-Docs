# 📱 Android Port Guide - Khandoba Secure Docs

## 🎯 Overview

This guide provides a complete roadmap for porting the iOS Khandoba Secure Docs app to Android. The Android version will maintain feature parity with the iOS app while using Android-native technologies.

---

## 🏗️ Architecture Mapping

### iOS → Android Technology Stack

| iOS Component | Android Equivalent |
|--------------|-------------------|
| SwiftUI | Jetpack Compose |
| SwiftData | Room Database |
| CloudKit | Firebase Firestore / Supabase |
| Apple Sign In | Google Sign In |
| CryptoKit | Android Keystore + Security Crypto |
| AVFoundation | CameraX + MediaRecorder |
| NaturalLanguage | ML Kit (Text Recognition, Entity Extraction) |
| StoreKit | Google Play Billing |
| Combine | Kotlin Coroutines + Flow |
| Swift Concurrency | Kotlin Coroutines |

---

## 📁 Project Structure

```
Khandoba Secure Docs Android/
├── app/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── java/com/khandoba/securedocs/
│       │   │   ├── KhandobaApplication.kt
│       │   │   ├── MainActivity.kt
│       │   │   ├── config/
│       │   │   │   └── AppConfig.kt
│       │   │   ├── data/
│       │   │   │   ├── database/
│       │   │   │   │   ├── KhandobaDatabase.kt
│       │   │   │   │   └── Converters.kt
│       │   │   │   ├── entity/
│       │   │   │   │   ├── UserEntity.kt
│       │   │   │   │   ├── VaultEntity.kt
│       │   │   │   │   ├── DocumentEntity.kt
│       │   │   │   │   └── ... (all entities)
│       │   │   │   ├── dao/
│       │   │   │   │   ├── UserDao.kt
│       │   │   │   │   ├── VaultDao.kt
│       │   │   │   │   └── ... (all DAOs)
│       │   │   │   └── repository/
│       │   │   │       ├── UserRepository.kt
│       │   │   │       └── ... (all repositories)
│       │   │   ├── domain/
│       │   │   │   ├── model/
│       │   │   │   │   ├── User.kt
│       │   │   │   │   ├── Vault.kt
│       │   │   │   │   └── ... (domain models)
│       │   │   │   └── usecase/
│       │   │   │       └── ... (use cases)
│       │   │   ├── service/
│       │   │   │   ├── AuthenticationService.kt
│       │   │   │   ├── EncryptionService.kt
│       │   │   │   ├── VaultService.kt
│       │   │   │   ├── DocumentService.kt
│       │   │   │   ├── DocumentIndexingService.kt
│       │   │   │   ├── FormalLogicEngine.kt
│       │   │   │   ├── InferenceEngine.kt
│       │   │   │   ├── TranscriptionService.kt
│       │   │   │   ├── VoiceMemoService.kt
│       │   │   │   ├── MLThreatAnalysisService.kt
│       │   │   │   ├── DualKeyApprovalService.kt
│       │   │   │   ├── ThreatMonitoringService.kt
│       │   │   │   ├── LocationService.kt
│       │   │   │   ├── SubscriptionService.kt
│       │   │   │   └── ... (all services)
│       │   │   ├── ui/
│       │   │   │   ├── theme/
│       │   │   │   │   ├── Color.kt
│       │   │   │   │   ├── Theme.kt
│       │   │   │   │   └── Type.kt
│       │   │   │   ├── navigation/
│       │   │   │   │   └── NavGraph.kt
│       │   │   │   ├── ContentView.kt
│       │   │   │   ├── authentication/
│       │   │   │   │   ├── WelcomeView.kt
│       │   │   │   │   └── AccountSetupView.kt
│       │   │   │   ├── vaults/
│       │   │   │   │   ├── VaultListView.kt
│       │   │   │   │   └── VaultDetailView.kt
│       │   │   │   ├── documents/
│       │   │   │   │   ├── DocumentUploadView.kt
│       │   │   │   │   └── DocumentPreviewView.kt
│       │   │   │   ├── media/
│       │   │   │   │   ├── VideoRecordingView.kt
│       │   │   │   │   └── VoiceRecordingView.kt
│       │   │   │   └── ... (all views)
│       │   │   └── viewmodel/
│       │   │       ├── AuthenticationViewModel.kt
│       │   │       ├── VaultViewModel.kt
│       │   │       └── ... (all ViewModels)
│       │   └── res/
│       │       ├── values/
│       │       │   ├── strings.xml
│       │       │   ├── colors.xml
│       │       │   └── themes.xml
│       │       └── xml/
│       │           ├── backup_rules.xml
│       │           └── file_paths.xml
│       └── test/
├── build.gradle.kts
├── settings.gradle.kts
└── gradle.properties
```

---

## 🔧 Setup Instructions

### 1. Create Android Studio Project

1. Open Android Studio
2. Create New Project → Empty Activity
3. Name: "Khandoba Secure Docs"
4. Package: `com.khandoba.securedocs`
5. Language: Kotlin
6. Minimum SDK: API 26 (Android 8.0)
7. Build configuration: Gradle Kotlin DSL

### 2. Configure Gradle Files

#### `build.gradle.kts` (Project Level)
```kotlin
plugins {
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.20" apply false
}
```

#### `app/build.gradle.kts` (Module Level)
See the complete file in the code examples below.

### 3. Add Dependencies

Key dependencies needed:
- **Jetpack Compose**: UI framework
- **Room**: Database
- **Coroutines**: Async operations
- **Google Sign In**: Authentication
- **ML Kit**: AI/ML features
- **CameraX**: Camera/video
- **Play Billing**: Subscriptions
- **Firebase/Supabase**: Backend

---

## 📊 Data Layer Porting

### Models → Room Entities

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

**Android (Room):**
```kotlin
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val googleUserID: String = "", // Android equivalent
    val fullName: String = "",
    // ...
)
```

### DAOs (Data Access Objects)

```kotlin
@Dao
interface UserDao {
    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun getUserById(id: UUID): UserEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)
    
    @Update
    suspend fun updateUser(user: UserEntity)
    
    @Delete
    suspend fun deleteUser(user: UserEntity)
}
```

### Database

```kotlin
@Database(
    entities = [
        UserEntity::class,
        VaultEntity::class,
        DocumentEntity::class,
        // ... all entities
    ],
    version = 1
)
@TypeConverters(Converters::class)
abstract class KhandobaDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun vaultDao(): VaultDao
    // ... all DAOs
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

**Android Pattern:**
```kotlin
class AuthenticationService @Inject constructor(
    private val userRepository: UserRepository,
    private val googleSignInClient: GoogleSignInClient
) {
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()
    
    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()
    
    suspend fun signInWithGoogle(): Result<User> {
        // Implementation
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

**Android (Android Keystore):**
```kotlin
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import android.security.keystore.KeyGenParameterSpec

class EncryptionService {
    private val keyStore = KeyStore.getInstance("AndroidKeyStore")
    
    fun encrypt(data: ByteArray, keyAlias: String): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val key = keyStore.getKey(keyAlias, null) as SecretKey
        cipher.init(Cipher.ENCRYPT_MODE, key)
        return cipher.doFinal(data)
    }
}
```

---

## 🎨 UI Layer Porting

### SwiftUI → Jetpack Compose

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

**Android (Compose):**
```kotlin
@Composable
fun WelcomeView(
    onSignInClick: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Welcome")
        Button(onClick = onSignInClick) {
            Text("Sign In")
        }
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

**Android:**
```kotlin
NavHost(
    navController = navController,
    startDestination = "welcome"
) {
    composable("welcome") { WelcomeView() }
    composable("vaults") { VaultListView() }
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

**Android (ML Kit):**
```kotlin
import com.google.mlkit.nl.entityextraction.EntityExtractor

val extractor = EntityExtraction.getClient(
    EntityExtractorOptions.Builder(EntityExtractorOptions.ENGLISH)
        .build()
)

extractor.annotate(text)
    .addOnSuccessListener { entities ->
        // Process entities
    }
```

### Text Recognition (OCR)

**Android (ML Kit):**
```kotlin
import com.google.mlkit.vision.text.TextRecognition

val recognizer = Text.getClient()
val image = InputImage.fromBitmap(bitmap)

recognizer.process(image)
    .addOnSuccessListener { visionText ->
        // Extract text
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

**Android (CameraX):**
```kotlin
val videoCapture = VideoCapture.Builder()
    .setTargetResolution(Size(1920, 1080))
    .build()

videoCapture.startRecording(
    outputFileOptions,
    cameraExecutor,
    object : VideoCapture.OnVideoSavedCallback {
        override fun onVideoSaved(outputFileResults: VideoCapture.OutputFileResults) {
            // Handle saved video
        }
    }
)
```

### Voice Recording

**Android (MediaRecorder):**
```kotlin
val recorder = MediaRecorder().apply {
    setAudioSource(MediaRecorder.AudioSource.MIC)
    setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
    setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
    setOutputFile(outputFile.absolutePath)
    prepare()
    start()
}
```

---

## 💳 Subscription System Porting

### StoreKit → Google Play Billing

**iOS (StoreKit):**
```swift
let products = try await Product.products(for: productIDs)
```

**Android (Play Billing):**
```kotlin
val billingClient = BillingClient.newBuilder(context)
    .setListener(purchasesUpdatedListener)
    .enablePendingPurchases()
    .build()

billingClient.queryProductDetailsAsync(
    ProductDetailsParams.newBuilder()
        .setProductList(productIdList)
        .build()
) { billingResult, productDetailsList ->
    // Handle products
}
```

---

## 🔄 State Management

### iOS (Combine)
```swift
@Published var state: StateType
```

### Android (StateFlow)
```kotlin
private val _state = MutableStateFlow<StateType>(initialValue)
val state: StateFlow<StateType> = _state.asStateFlow()
```

### ViewModel Pattern
```kotlin
class VaultViewModel @Inject constructor(
    private val vaultRepository: VaultRepository
) : ViewModel() {
    private val _vaults = MutableStateFlow<List<Vault>>(emptyList())
    val vaults: StateFlow<List<Vault>> = _vaults.asStateFlow()
    
    init {
        viewModelScope.launch {
            vaultRepository.getAllVaults().collect { vaults ->
                _vaults.value = vaults
            }
        }
    }
}
```

---

## 📱 Key Implementation Files

### 1. AppConfig.kt
```kotlin
object AppConfig {
    const val APP_VERSION = "1.0.1"
    const val APP_BUILD_NUMBER = 30
    const val USE_SUPABASE = false
    const val SESSION_TIMEOUT_MINUTES = 30
    // ... configuration
}
```

### 2. MainActivity.kt
```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            KhandobaSecureDocsTheme {
                ContentView()
            }
        }
    }
}
```

### 3. ContentView.kt
```kotlin
@Composable
fun ContentView() {
    val authService = remember { AuthenticationService() }
    val isAuthenticated by authService.isAuthenticated.collectAsState()
    
    when {
        !isAuthenticated -> WelcomeView()
        else -> ClientMainView()
    }
}
```

---

## 🚀 Migration Checklist

### Phase 1: Foundation ✅
- [x] Create Android project structure
- [x] Set up Gradle configuration
- [x] Configure AndroidManifest
- [ ] Port all data models to Room entities
- [ ] Create DAOs and repositories
- [ ] Set up database

### Phase 2: Core Services
- [ ] Port AuthenticationService (Google Sign In)
- [ ] Port EncryptionService (Android Keystore)
- [ ] Port VaultService
- [ ] Port DocumentService
- [ ] Port LocationService

### Phase 3: AI/ML Services
- [ ] Port DocumentIndexingService (ML Kit)
- [ ] Port FormalLogicEngine
- [ ] Port InferenceEngine
- [ ] Port TranscriptionService (Speech-to-Text)
- [ ] Port VoiceMemoService (Text-to-Speech)
- [ ] Port MLThreatAnalysisService

### Phase 4: UI Layer
- [ ] Create theme system (Material 3)
- [ ] Port WelcomeView
- [ ] Port AccountSetupView
- [ ] Port VaultListView
- [ ] Port VaultDetailView
- [ ] Port DocumentUploadView
- [ ] Port all other views

### Phase 5: Media Features
- [ ] Port VideoRecordingView (CameraX)
- [ ] Port VoiceRecordingView (MediaRecorder)
- [ ] Port camera features

### Phase 6: Premium Features
- [ ] Port SubscriptionService (Play Billing)
- [ ] Port StoreView
- [ ] Port subscription management

### Phase 7: Testing & Polish
- [ ] Unit tests
- [ ] UI tests
- [ ] Integration tests
- [ ] Performance optimization
- [ ] Security audit

---

## 📚 Additional Resources

### Android Documentation
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Room Database](https://developer.android.com/training/data-storage/room)
- [ML Kit](https://developers.google.com/ml-kit)
- [CameraX](https://developer.android.com/training/camerax)
- [Play Billing](https://developer.android.com/google/play/billing)

### Migration Patterns
- Combine → Coroutines/Flow
- SwiftData → Room
- SwiftUI → Compose
- CryptoKit → Android Keystore

---

## 🎯 Next Steps

1. **Set up the Android project** using the structure above
2. **Port data models** first (foundation)
3. **Port core services** (authentication, encryption, vaults)
4. **Port UI layer** (Compose views)
5. **Port AI/ML services** (ML Kit integration)
6. **Port media features** (CameraX, MediaRecorder)
7. **Port subscription system** (Play Billing)
8. **Test and optimize**

---

**Status:** Foundation created, ready for implementation  
**Last Updated:** December 2024
