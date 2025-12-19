# 📝 Android Code Examples - Khandoba Secure Docs

## Complete Implementation Examples

### 1. app/build.gradle.kts

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("kotlin-kapt")
    id("kotlin-parcelize")
    id("com.google.devtools.ksp") version "1.9.20-1.0.14"
}

android {
    namespace = "com.khandoba.securedocs"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.khandoba.securedocs"
        minSdk = 26
        targetSdk = 34
        versionCode = 30
        versionName = "1.0.1"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
    
    buildFeatures {
        compose = true
    }
    
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.4"
    }
    
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Core Android
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
    implementation("androidx.activity:activity-compose:1.8.1")
    
    // Compose
    implementation(platform("androidx.compose:compose-bom:2023.10.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    
    // Navigation
    implementation("androidx.navigation:navigation-compose:2.7.5")
    
    // Room Database
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")
    
    // ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.6.2")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.6.2")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    
    // Google Sign In
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    
    // Biometric
    implementation("androidx.biometric:biometric:1.1.0")
    
    // Encryption
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    
    // ML Kit
    implementation("com.google.mlkit:text-recognition:16.0.0")
    implementation("com.google.mlkit:language-id:17.0.4")
    implementation("com.google.mlkit:entity-extraction:16.0.0")
    
    // CameraX
    implementation("androidx.camera:camera-camera2:1.3.0")
    implementation("androidx.camera:camera-lifecycle:1.3.0")
    implementation("androidx.camera:camera-view:1.3.0")
    
    // Media
    implementation("androidx.media3:media3-exoplayer:1.2.0")
    implementation("androidx.media3:media3-ui:1.2.0")
    
    // Location
    implementation("com.google.android.gms:play-services-location:21.0.1")
    
    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-messaging")
    
    // Supabase
    implementation(platform("io.github.jan-tennert.supabase:bom:2.3.0"))
    implementation("io.github.jan-tennert.supabase:postgrest-kt")
    implementation("io.github.jan-tennert.supabase:realtime-kt")
    implementation("io.github.jan-tennert.supabase:storage-kt")
    implementation("io.github.jan-tennert.supabase:auth-kt")
    
    // Play Billing
    implementation("com.android.billingclient:billing-ktx:6.1.0")
    
    // PDF
    implementation("com.tom-roush:pdfbox-android:2.0.27.0")
    
    // Image Loading
    implementation("io.coil-kt:coil-compose:2.5.0")
    
    // JSON
    implementation("com.google.code.gson:gson:2.10.1")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation(platform("androidx.compose:compose-bom:2023.10.01"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
```

### 2. AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
    <uses-feature android:name="android.hardware.microphone" android:required="false" />

    <application
        android:name=".KhandobaApplication"
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.KhandobaSecureDocs"
        android:usesCleartextTraffic="false"
        tools:targetApi="31">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.KhandobaSecureDocs"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="khandoba" />
            </intent-filter>
        </activity>
        
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
    </application>

</manifest>
```

### 3. KhandobaApplication.kt

```kotlin
package com.khandoba.securedocs

import android.app.Application
import androidx.room.Room
import com.khandoba.securedocs.data.database.KhandobaDatabase

class KhandobaApplication : Application() {
    
    val database: KhandobaDatabase by lazy {
        Room.databaseBuilder(
            applicationContext,
            KhandobaDatabase::class.java,
            "khandoba_database"
        )
            .fallbackToDestructiveMigration()
            .build()
    }
    
    override fun onCreate() {
        super.onCreate()
        // Initialize app-wide services
    }
}
```

### 4. MainActivity.kt

```kotlin
package com.khandoba.securedocs

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.khandoba.securedocs.ui.theme.KhandobaSecureDocsTheme
import com.khandoba.securedocs.ui.ContentView

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        setContent {
            KhandobaSecureDocsTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    ContentView()
                }
            }
        }
    }
}
```

### 5. AppConfig.kt

```kotlin
package com.khandoba.securedocs.config

object AppConfig {
    const val APP_VERSION = "1.0.1"
    const val APP_BUILD_NUMBER = 30
    const val APP_NAME = "Khandoba Secure Docs"
    
    const val USE_SUPABASE = false
    const val SUPABASE_URL = "https://your-project.supabase.co"
    const val SUPABASE_ANON_KEY = "your-anon-key"
    
    const val FIREBASE_PROJECT_ID = "khandoba-secure-docs"
    
    const val ENABLE_ANALYTICS = true
    const val ENABLE_CRASH_REPORTING = true
    const val ENABLE_PUSH_NOTIFICATIONS = true
    
    const val REQUIRE_BIOMETRIC_AUTH = true
    const val SESSION_TIMEOUT_MINUTES = 30
    const val MAX_LOGIN_ATTEMPTS = 5
    
    const val SHARED_PREFS_NAME = "khandoba_secure_docs_prefs"
    const val PERMISSIONS_SETUP_COMPLETE_KEY = "permissions_setup_complete"
}
```

### 6. KhandobaDatabase.kt

```kotlin
package com.khandoba.securedocs.data.database

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.khandoba.securedocs.data.dao.*
import com.khandoba.securedocs.data.entity.*

@Database(
    entities = [
        UserEntity::class,
        UserRoleEntity::class,
        VaultEntity::class,
        VaultSessionEntity::class,
        VaultAccessLogEntity::class,
        DocumentEntity::class,
        DocumentVersionEntity::class,
        NomineeEntity::class,
        DualKeyRequestEntity::class,
        EmergencyAccessRequestEntity::class,
        VaultTransferRequestEntity::class,
        VaultAccessRequestEntity::class,
        ChatMessageEntity::class
    ],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class KhandobaDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun vaultDao(): VaultDao
    abstract fun documentDao(): DocumentDao
    abstract fun vaultSessionDao(): VaultSessionDao
    abstract fun vaultAccessLogDao(): VaultAccessLogDao
    abstract fun nomineeDao(): NomineeDao
    abstract fun dualKeyRequestDao(): DualKeyRequestDao
    abstract fun chatMessageDao(): ChatMessageDao
}
```

### 7. Converters.kt

```kotlin
package com.khandoba.securedocs.data.database

import androidx.room.TypeConverter
import java.util.Date
import java.util.UUID

class Converters {
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }

    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }

    @TypeConverter
    fun fromUUID(value: UUID?): String? {
        return value?.toString()
    }

    @TypeConverter
    fun toUUID(value: String?): UUID? {
        return value?.let { UUID.fromString(it) }
    }

    @TypeConverter
    fun fromStringList(value: List<String>?): String {
        return value?.joinToString(",") ?: ""
    }

    @TypeConverter
    fun toStringList(value: String): List<String> {
        return if (value.isEmpty()) emptyList() else value.split(",")
    }
}
```

### 8. UserEntity.kt

```kotlin
package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val googleUserID: String = "",
    val fullName: String = "",
    val email: String? = null,
    val profilePictureData: ByteArray? = null,
    val createdAt: Date = Date(),
    val lastActiveAt: Date = Date(),
    val isActive: Boolean = true,
    val isPremiumSubscriber: Boolean = false,
    val subscriptionExpiryDate: Date? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as UserEntity
        if (id != other.id) return false
        if (googleUserID != other.googleUserID) return false
        if (fullName != other.fullName) return false
        if (email != other.email) return false
        if (profilePictureData != null) {
            if (other.profilePictureData == null) return false
            if (!profilePictureData.contentEquals(other.profilePictureData)) return false
        } else if (other.profilePictureData != null) return false
        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + googleUserID.hashCode()
        result = 31 * result + fullName.hashCode()
        result = 31 * result + (email?.hashCode() ?: 0)
        result = 31 * result + (profilePictureData?.contentHashCode() ?: 0)
        return result
    }
}
```

### 9. UserDao.kt

```kotlin
package com.khandoba.securedocs.data.dao

import androidx.room.*
import com.khandoba.securedocs.data.entity.UserEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface UserDao {
    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun getUserById(id: UUID): UserEntity?
    
    @Query("SELECT * FROM users WHERE googleUserID = :googleUserID")
    suspend fun getUserByGoogleID(googleUserID: String): UserEntity?
    
    @Query("SELECT * FROM users")
    fun getAllUsers(): Flow<List<UserEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)
    
    @Update
    suspend fun updateUser(user: UserEntity)
    
    @Delete
    suspend fun deleteUser(user: UserEntity)
}
```

### 10. ContentView.kt (Basic)

```kotlin
package com.khandoba.securedocs.ui

import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.khandoba.securedocs.ui.authentication.WelcomeView
import com.khandoba.securedocs.ui.vaults.ClientMainView

@Composable
fun ContentView(
    modifier: Modifier = Modifier
) {
    // TODO: Inject AuthenticationService
    var isAuthenticated by remember { mutableStateOf(false) }
    
    when {
        !isAuthenticated -> {
            WelcomeView(
                onSignInSuccess = { isAuthenticated = true }
            )
        }
        else -> {
            ClientMainView()
        }
    }
}
```

---

## Next Steps

1. Copy these files into your Android Studio project
2. Create the remaining entity files (VaultEntity, DocumentEntity, etc.)
3. Create corresponding DAOs
4. Implement services
5. Build UI with Compose

See `ANDROID_PORT_GUIDE.md` for complete implementation details.
