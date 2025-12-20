package com.khandoba.securedocs.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.khandoba.securedocs.data.entity.UserEntity
import com.khandoba.securedocs.service.AuthenticationService
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class AuthenticationViewModel(
    private val authService: AuthenticationService
) : ViewModel() {
    
    val currentUser: StateFlow<UserEntity?> = authService.currentUser
    val isAuthenticated: StateFlow<Boolean> = authService.isAuthenticated
    val isLoading: StateFlow<Boolean> = authService.isLoading
    
    fun signInWithGoogle(account: GoogleSignInAccount) {
        viewModelScope.launch {
            authService.signInWithGoogle(account)
        }
    }
    
    fun signOut() {
        viewModelScope.launch {
            authService.signOut()
        }
    }
    
    fun getGoogleSignInClient() = authService.getGoogleSignInClient()
}

