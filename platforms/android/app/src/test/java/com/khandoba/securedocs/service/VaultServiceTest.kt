package com.khandoba.securedocs.service

import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.data.repository.VaultRepository
import io.mockk.*
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.*

class VaultServiceTest {
    private lateinit var mockRepository: VaultRepository
    private lateinit var vaultService: VaultService
    
    @Before
    fun setup() {
        mockRepository = mockk(relaxed = true)
        vaultService = VaultService(mockRepository)
    }
    
    @Test
    fun `test create vault`() = runTest {
        val userId = UUID.randomUUID()
        val vaultId = UUID.randomUUID()
        val vaultName = "Test Vault"
        val vaultDescription = "Test Description"
        
        val expectedVault = VaultEntity(
            id = vaultId,
            name = vaultName,
            vaultDescription = vaultDescription,
            ownerId = userId,
            keyType = "single",
            vaultType = "both",
            status = "locked"
        )
        
        coEvery { mockRepository.createVault(any()) } returns Result.success(expectedVault)
        vaultService.configure(userId)
        
        val result = vaultService.createVault(vaultName, vaultDescription, "single")
        
        assertTrue("Vault creation should succeed", result.isSuccess)
        assertEquals("Vault name should match", vaultName, result.getOrNull()?.name)
        coVerify { mockRepository.createVault(any()) }
    }
    
    @Test
    fun `test load vaults`() = runTest {
        val userId = UUID.randomUUID()
        val vaults = listOf(
            VaultEntity(
                id = UUID.randomUUID(),
                name = "Vault 1",
                ownerId = userId,
                status = "locked"
            ),
            VaultEntity(
                id = UUID.randomUUID(),
                name = "Vault 2",
                ownerId = userId,
                status = "locked"
            )
        )
        
        coEvery { mockRepository.getVaultsByOwner(userId) } returns flowOf(vaults)
        vaultService.configure(userId)
        vaultService.loadVaults()
        
        val loadedVaults = vaultService.vaults.first()
        assertEquals("Should load all vaults", 2, loadedVaults.size)
    }
    
    @Test
    fun `test unlock vault`() = runTest {
        val vaultId = UUID.randomUUID()
        val userId = UUID.randomUUID()
        val password = "testPassword"
        
        val mockSession = mockk<com.khandoba.securedocs.data.entity.VaultSessionEntity>(relaxed = true)
        coEvery { mockRepository.unlockVault(vaultId, password, userId) } returns Result.success(mockSession)
        
        vaultService.configure(userId)
        val result = vaultService.unlockVault(vaultId, password)
        
        assertTrue("Vault unlock should succeed", result.isSuccess)
        coVerify { mockRepository.unlockVault(vaultId, password, userId) }
    }
    
    @Test
    fun `test lock vault`() = runTest {
        val vaultId = UUID.randomUUID()
        val userId = UUID.randomUUID()
        
        coEvery { mockRepository.lockVault(vaultId, userId) } just Runs
        vaultService.configure(userId)
        
        vaultService.lockVault(vaultId)
        
        coVerify { mockRepository.lockVault(vaultId, userId) }
    }
    
    @Test
    fun `test delete vault`() = runTest {
        val vaultId = UUID.randomUUID()
        val userId = UUID.randomUUID()
        
        coEvery { mockRepository.deleteVault(vaultId, userId) } returns Result.success(Unit)
        vaultService.configure(userId)
        
        val result = vaultService.deleteVault(vaultId)
        
        assertTrue("Vault deletion should succeed", result.isSuccess)
        coVerify { mockRepository.deleteVault(vaultId, userId) }
    }
}
