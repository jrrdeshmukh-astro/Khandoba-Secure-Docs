package com.khandoba.securedocs.service

import com.khandoba.securedocs.data.supabase.SupabaseService
import com.khandoba.securedocs.data.supabase.SupabaseVault
import io.mockk.*
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.*

class ThreatIndexServiceTest {
    private lateinit var mockSupabaseService: SupabaseService
    private lateinit var threatIndexService: ThreatIndexService
    
    @Before
    fun setup() {
        mockSupabaseService = mockk(relaxed = true)
        threatIndexService = ThreatIndexService(mockSupabaseService)
    }
    
    @Test
    fun `test update threat index`() = runTest {
        val vaultId = UUID.randomUUID()
        val threatIndex = 75.5
        val threatLevel = "high"
        
        threatIndexService.updateThreatIndex(vaultId, threatIndex, threatLevel)
        
        val currentIndices = threatIndexService.currentThreatIndices.first()
        assertEquals("Threat index should be updated", threatIndex, currentIndices[vaultId], 0.01)
        
        val history = threatIndexService.getThreatIndexHistory(vaultId)
        assertTrue("History should contain the update", history.isNotEmpty())
        assertEquals("History should have correct threat index", 
            threatIndex, history.first().threatIndex, 0.01)
    }
    
    @Test
    fun `test initialize threat index monitoring`() = runTest {
        val vaultId = UUID.randomUUID()
        val mockVault = mockk<SupabaseVault>(relaxed = true)
        
        every { mockVault.threat_index } returns 50.0
        every { mockVault.threat_level } returns "medium"
        coEvery { mockSupabaseService.fetch<SupabaseVault>(any(), vaultId) } returns mockVault
        
        threatIndexService.initializeThreatIndexMonitoring(vaultId)
        
        val currentIndex = threatIndexService.getCurrentThreatIndex(vaultId)
        assertEquals("Threat index should be initialized", 50.0, currentIndex, 0.01)
    }
    
    @Test
    fun `test threat index history limit`() = runTest {
        val vaultId = UUID.randomUUID()
        
        // Add more than 100 updates
        repeat(150) { index ->
            threatIndexService.updateThreatIndex(vaultId, index.toDouble(), "low")
        }
        
        val history = threatIndexService.getThreatIndexHistory(vaultId)
        assertTrue("History should be limited to 100 entries", history.size <= 100)
    }
}
