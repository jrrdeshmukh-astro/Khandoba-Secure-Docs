package com.khandoba.securedocs.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.khandoba.securedocs.data.entity.NomineeEntity
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.service.NomineeService
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.Date
import java.util.UUID

class NomineeViewModel(
    private val nomineeService: NomineeService
) : ViewModel() {
    
    val nominees: StateFlow<List<NomineeEntity>> = nomineeService.nominees
    val isLoading: StateFlow<Boolean> = nomineeService.isLoading
    
    fun configure(userID: UUID?) {
        nomineeService.configure(userID)
    }
    
    fun loadNominees(vaultId: UUID) {
        viewModelScope.launch {
            nomineeService.loadNominees(vaultId)
        }
    }
    
    fun inviteNominee(
        vault: VaultEntity,
        name: String,
        email: String? = null,
        phoneNumber: String? = null,
        selectedDocumentIDs: List<UUID>? = null,
        sessionExpiresAt: Date? = null,
        isSubsetAccess: Boolean = false,
        onResult: (Result<NomineeEntity>) -> Unit
    ) {
        viewModelScope.launch {
            val result = nomineeService.inviteNominee(
                vault = vault,
                name = name,
                email = email,
                phoneNumber = phoneNumber,
                selectedDocumentIDs = selectedDocumentIDs,
                sessionExpiresAt = sessionExpiresAt,
                isSubsetAccess = isSubsetAccess
            )
            onResult(result)
        }
    }
    
    fun acceptNomineeInvitation(
        inviteToken: String,
        onResult: (Result<NomineeEntity>) -> Unit
    ) {
        viewModelScope.launch {
            val result = nomineeService.acceptNomineeInvitation(inviteToken)
            onResult(result)
        }
    }
    
    fun removeNominee(
        nominee: NomineeEntity,
        onResult: (Result<Unit>) -> Unit
    ) {
        viewModelScope.launch {
            val result = nomineeService.removeNominee(nominee)
            onResult(result)
        }
    }
    
    fun revokeNominee(
        nominee: NomineeEntity,
        onResult: (Result<Unit>) -> Unit
    ) {
        viewModelScope.launch {
            val result = nomineeService.revokeNominee(nominee)
            onResult(result)
        }
    }
}
