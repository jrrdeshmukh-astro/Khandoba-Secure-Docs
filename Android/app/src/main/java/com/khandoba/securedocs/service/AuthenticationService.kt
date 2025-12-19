package com.khandoba.securedocs.service

import android.content.Context
import android.util.Log
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Task
import com.khandoba.securedocs.R
import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.entity.UserEntity
import com.khandoba.securedocs.data.repository.UserRepository
import com.khandoba.securedocs.data.supabase.SupabaseService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date
import java.util.UUID

class AuthenticationService(
    private val context: Context,
    private val userRepository: UserRepository,
    private val supabaseService: SupabaseService
) {
    private val _currentUser = MutableStateFlow<UserEntity?>(null)
    val currentUser: StateFlow<UserEntity?> = _currentUser.asStateFlow()
    
    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val googleSignInClient: GoogleSignInClient by lazy {
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(context.getString(R.string.default_web_client_id)) // TODO: Add to strings.xml
            .requestEmail()
            .build()
        GoogleSignIn.getClient(context, gso)
    }
    
    init {
        checkAuthenticationState()
    }
    
    suspend fun checkAuthenticationState() {
        _isLoading.value = true
        try {
            if (AppConfig.USE_SUPABASE) {
                val session = supabaseService.currentSession.value
                if (session != null && !session.isExpired) {
                    // Get user from Supabase
                    val supabaseUser = supabaseService.getCurrentUser()
                    if (supabaseUser != null) {
                        val user = userRepository.getCurrentUser()
                        _currentUser.value = user
                        _isAuthenticated.value = true
                        Log.d("AuthService", "✅ User authenticated: ${user?.fullName}")
                    } else {
                        _isAuthenticated.value = false
                        _currentUser.value = null
                    }
                } else {
                    _isAuthenticated.value = false
                    _currentUser.value = null
                }
            } else {
                // Room database mode
                val user = userRepository.getCurrentUser()
                _currentUser.value = user
                _isAuthenticated.value = user != null
            }
        } catch (e: Exception) {
            Log.e("AuthService", "Error checking auth state: ${e.message}")
            _isAuthenticated.value = false
            _currentUser.value = null
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun signInWithGoogle(account: GoogleSignInAccount): Result<UserEntity> {
        _isLoading.value = true
        return try {
            // Get ID token
            val idToken = account.idToken
                ?: return Result.failure(Exception("No ID token from Google Sign In"))
            
            // Sign in to Supabase with Google
            if (AppConfig.USE_SUPABASE) {
                val session = supabaseService.signInWithGoogle(idToken)
                
                // Create or update user in database
                val user = UserEntity(
                    id = UUID.fromString(session.user.id),
                    googleUserID = account.id ?: "",
                    fullName = account.displayName ?: "User",
                    email = account.email,
                    createdAt = Date(),
                    lastActiveAt = Date(),
                    isActive = true
                )
                
                // Check if user exists
                val existingUser = userRepository.getCurrentUser()
                if (existingUser != null) {
                    // Update existing user
                    val updatedUser = existingUser.copy(
                        fullName = user.fullName,
                        email = user.email,
                        lastActiveAt = Date()
                    )
                    userRepository.updateUser(updatedUser)
                    _currentUser.value = updatedUser
                } else {
                    // Create new user
                    userRepository.insertUser(user)
                    _currentUser.value = user
                }
                
                _isAuthenticated.value = true
                Log.d("AuthService", "✅ Signed in with Google: ${user.fullName}")
                
                Result.success(_currentUser.value!!)
            } else {
                // Room database mode (no Supabase)
                val user = UserEntity(
                    id = UUID.randomUUID(),
                    googleUserID = account.id ?: "",
                    fullName = account.displayName ?: "User",
                    email = account.email,
                    createdAt = Date(),
                    lastActiveAt = Date(),
                    isActive = true
                )
                userRepository.insertUser(user)
                _currentUser.value = user
                _isAuthenticated.value = true
                Result.success(user)
            }
        } catch (e: Exception) {
            Log.e("AuthService", "Sign in failed: ${e.message}")
            Result.failure(e)
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun signOut() {
        _isLoading.value = true
        try {
            if (AppConfig.USE_SUPABASE) {
                supabaseService.signOut()
            }
            googleSignInClient.signOut()
            _currentUser.value = null
            _isAuthenticated.value = false
            Log.d("AuthService", "✅ Signed out")
        } catch (e: Exception) {
            Log.e("AuthService", "Sign out failed: ${e.message}")
        } finally {
            _isLoading.value = false
        }
    }
    
    fun getGoogleSignInClient(): GoogleSignInClient {
        return googleSignInClient
    }
}
