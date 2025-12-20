package com.khandoba.securedocs.service

import com.khandoba.securedocs.data.supabase.SupabaseService
import io.mockk.*
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.*

class AntiVaultServiceTest {
    private lateinit var mockSupabaseService: SupabaseService
    private lateinit var antiVaultService: AntiVaultService
    private val testUserId = UUID.randomUUID()
    
    @Before
    fun setup() {
        mockSupabaseService = mockk(relaxed = true)
        antiVaultService = AntiVaultService(
            supabaseService = mockSupabaseService,
            currentUserID = testUserId
        )
    }
    
    @Test
    fun `test create anti-vault`() = runTest {
        val vaultId = UUID.randomUUID()
        val autoUnlockPolicy = AntiVaultService.AutoUnlockPolicy(
            enabled = true,
            threatLevelThreshold = "high"
        )
        val threatDetectionSettings = AntiVaultService.ThreatDetectionSettings(
            enabled = true,
            severityThreshold = "medium"
        )
        
        val mockAntiVault = mockk<AntiVaultService.AntiVault>(relaxed = true)
        coEvery { mockSupabaseService.insert<Any>(any(), any()) } returns mockAntiVault
        
        val result = antiVaultService.createAntiVault(
            monitoredVaultId = vaultId,
            autoUnlockPolicy = autoUnlockPolicy,
            threatDetectionSettings = threatDetectionSettings
        )
        
        assertNotNull("Anti-vault creation should return result", result)
        coVerify { mockSupabaseService.insert<Any>(any(), any()) }
    }
    
    @Test
    fun `test load anti-vaults`() = runTest {
        val mockAntiVault = mockk<AntiVaultService.AntiVault>(relaxed = true)
        coEvery { mockSupabaseService.fetchAll<Any>(any(), any()) } returns listOf(mockAntiVault)
        
        val result = antiVaultService.loadAntiVaults()
        
        assertNotNull("Load anti-vaults should return result", result)
        coVerify { mockSupabaseService.fetchAll<Any>(any(), any()) }
    }
    
    @Test
    fun `test unlock anti-vault`() = runTest {
        val antiVaultId = UUID.randomUUID()
        val mockAntiVault = mockk<AntiVaultService.AntiVault>(relaxed = true)
        
        coEvery { mockSupabaseService.fetch<Any>(any(), antiVaultId) } returns mockAntiVault
        coEvery { mockSupabaseService.update<Any>(any(), any()) } returns mockAntiVault
        
        val result = antiVaultService.unlockAntiVault(antiVaultId)
        
        assertNotNull("Unlock anti-vault should return result", result)
        coVerify { mockSupabaseService.update<Any>(any(), any()) }
    }
}
