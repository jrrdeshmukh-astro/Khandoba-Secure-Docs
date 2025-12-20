package com.khandoba.securedocs.viewmodel

import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.service.VaultService
import io.mockk.*
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.*

class VaultViewModelTest {
    private lateinit var mockVaultService: VaultService
    private lateinit var vaultViewModel: VaultViewModel
    
    @Before
    fun setup() {
        mockVaultService = mockk(relaxed = true)
        vaultViewModel = VaultViewModel(mockVaultService)
    }
    
    @Test
    fun `test load vaults`() = runTest {
        val userId = UUID.randomUUID()
        val vaults = listOf(
            VaultEntity(id = UUID.randomUUID(), name = "Vault 1", ownerId = userId),
            VaultEntity(id = UUID.randomUUID(), name = "Vault 2", ownerId = userId)
        )
        
        coEvery { mockVaultService.vaults } returns flowOf(vaults)
        every { mockVaultService.loadVaults() } just Runs
        
        vaultViewModel.loadVaults()
        
        coVerify { mockVaultService.loadVaults() }
    }
    
    @Test
    fun `test create vault`() = runTest {
        val vaultName = "Test Vault"
        val vaultDescription = "Test Description"
        val keyType = "single"
        
        val expectedVault = VaultEntity(
            id = UUID.randomUUID(),
            name = vaultName,
            vaultDescription = vaultDescription,
            keyType = keyType
        )
        
        coEvery { mockVaultService.createVault(vaultName, vaultDescription, keyType) } returns
            Result.success(expectedVault)
        
        var result: Result<VaultEntity>? = null
        vaultViewModel.createVault(vaultName, vaultDescription, keyType) { result = it }
        
        assertNotNull("Create vault should return result", result)
        assertTrue("Result should be success", result!!.isSuccess)
        assertEquals("Vault name should match", vaultName, result!!.getOrNull()?.name)
    }
}
