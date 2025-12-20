package com.khandoba.securedocs.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.data.entity.VaultSessionEntity
import com.khandoba.securedocs.service.VaultService
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.UUID

class VaultViewModel(
    private val vaultService: VaultService
) : ViewModel() {
    
    val vaults: StateFlow<List<VaultEntity>> = vaultService.vaults
    val isLoading: StateFlow<Boolean> = vaultService.isLoading
    val activeSessions: StateFlow<Map<UUID, VaultSessionEntity>> = vaultService.activeSessions
    
    fun configure(userID: UUID) {
        vaultService.configure(userID)
    }
    
    fun loadVaults() {
        viewModelScope.launch {
            vaultService.loadVaults()
        }
    }
    
    fun createVault(
        name: String,
        description: String? = null,
        keyType: String = "single",
        onResult: (Result<VaultEntity>) -> Unit
    ) {
        viewModelScope.launch {
            val result = vaultService.createVault(name, description, keyType)
            onResult(result)
        }
    }
    
    fun unlockVault(
        vaultId: UUID,
        password: String? = null,
        onResult: (Result<VaultSessionEntity>) -> Unit
    ) {
        viewModelScope.launch {
            val result = vaultService.unlockVault(vaultId, password)
            onResult(result)
        }
    }
    
    fun lockVault(vaultId: UUID) {
        viewModelScope.launch {
            vaultService.lockVault(vaultId)
        }
    }
    
    fun deleteVault(vaultId: UUID, onResult: (Result<Unit>) -> Unit) {
        viewModelScope.launch {
            val result = vaultService.deleteVault(vaultId)
            onResult(result)
        }
    }
}

