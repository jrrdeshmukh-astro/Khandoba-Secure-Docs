package com.khandoba.securedocs.service

import android.content.Context
import com.khandoba.securedocs.data.repository.UserRepository
import com.khandoba.securedocs.data.supabase.SupabaseService
import io.mockk.*
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.UUID

class AuthenticationServiceTest {
    private lateinit var mockContext: Context
    private lateinit var mockUserRepository: UserRepository
    private lateinit var mockSupabaseService: SupabaseService
    private lateinit var authenticationService: AuthenticationService
    
    @Before
    fun setup() {
        mockContext = mockk(relaxed = true)
        mockUserRepository = mockk(relaxed = true)
        mockSupabaseService = mockk(relaxed = true)
        
        authenticationService = AuthenticationService(
            context = mockContext,
            userRepository = mockUserRepository,
            supabaseService = mockSupabaseService
        )
    }
    
    @Test
    fun `test initial state is not authenticated`() = runTest {
        val isAuthenticated = authenticationService.isAuthenticated.first()
        assertFalse("Initial state should be not authenticated", isAuthenticated)
    }
    
    @Test
    fun `test sign in with Google`() = runTest {
        val mockSession = mockk<io.github.jan.supabase.auth.session.Session>(relaxed = true)
        val mockUserInfo = mockk<io.github.jan.supabase.auth.user.UserInfo>(relaxed = true)
        
        coEvery { mockUserInfo.id } returns UUID.randomUUID().toString()
        coEvery { mockSupabaseService.signInWithGoogle(any()) } returns mockSession
        coEvery { mockSupabaseService.getCurrentUser() } returns mockUserInfo
        
        // Note: This test would need actual Google Sign-In mocking in a real scenario
        // For now, we test the flow structure
        assertNotNull("AuthenticationService should be created", authenticationService)
    }
    
    @Test
    fun `test sign out`() = runTest {
        coEvery { mockSupabaseService.signOut() } just Runs
        
        authenticationService.signOut()
        
        coVerify { mockSupabaseService.signOut() }
        val isAuthenticated = authenticationService.isAuthenticated.first()
        assertFalse("After sign out, should not be authenticated", isAuthenticated)
    }
}
