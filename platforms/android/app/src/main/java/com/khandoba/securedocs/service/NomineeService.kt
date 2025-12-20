package com.khandoba.securedocs.service

import android.util.Log
import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.entity.NomineeEntity
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.data.repository.NomineeRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.Date
import java.util.UUID

class NomineeService(
    private val nomineeRepository: NomineeRepository
) {
    private val _nominees = MutableStateFlow<List<NomineeEntity>>(emptyList())
    val nominees: StateFlow<List<NomineeEntity>> = _nominees.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private var currentUserID: UUID? = null
    
    fun configure(userID: UUID?) {
        this.currentUserID = userID
    }
    
    suspend fun loadNominees(vaultId: UUID) {
        _isLoading.value = true
        try {
            // Collect once from Flow
            val nomineeList = nomineeRepository.getNomineesForVault(vaultId).first()
            _nominees.value = nomineeList
        } catch (e: Exception) {
            Log.e("NomineeService", "Error loading nominees: ${e.message}")
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun inviteNominee(
        vault: VaultEntity,
        name: String,
        email: String? = null,
        phoneNumber: String? = null,
        selectedDocumentIDs: List<UUID>? = null,
        sessionExpiresAt: Date? = null,
        isSubsetAccess: Boolean = false
    ): Result<NomineeEntity> {
        return try {
            if (currentUserID == null) {
                return Result.failure(Exception("User not authenticated"))
            }
            
            val nominee = NomineeEntity(
                id = UUID.randomUUID(),
                name = name,
                email = email,
                phoneNumber = phoneNumber,
                statusRaw = "pending",
                invitedAt = Date(),
                acceptedAt = null,
                lastActiveAt = null,
                inviteToken = UUID.randomUUID().toString(),
                vaultId = vault.id,
                invitedByUserID = currentUserID,
                isSubsetAccess = isSubsetAccess,
                selectedDocumentIDs = selectedDocumentIDs,
                sessionExpiresAt = sessionExpiresAt
            )
            
            nomineeRepository.insertNominee(nominee)
            
            // Reload nominees to update list
            loadNominees(vault.id)
            
            Log.d("NomineeService", "✅ Nominee invited: $name")
            Result.success(nominee)
        } catch (e: Exception) {
            Log.e("NomineeService", "Error inviting nominee: ${e.message}")
            Result.failure(e)
        }
    }
    
    suspend fun acceptNomineeInvitation(inviteToken: String): Result<NomineeEntity> {
        return try {
            // Find nominee by invite token
            val allNominees = _nominees.value
            val nominee = allNominees.firstOrNull { it.inviteToken == inviteToken }
                ?: return Result.failure(Exception("Invitation not found"))
            
            if (nominee.statusRaw != "pending") {
                return Result.failure(Exception("Invitation already processed"))
            }
            
            // Update status to accepted
            val updatedNominee = nominee.copy(
                statusRaw = "accepted",
                acceptedAt = Date()
            )
            
            nomineeRepository.updateNominee(updatedNominee)
            
            // Reload nominees
            if (nominee.vaultId != null) {
                loadNominees(nominee.vaultId!!)
            }
            
            Log.d("NomineeService", "✅ Nominee invitation accepted: ${nominee.name}")
            Result.success(updatedNominee)
        } catch (e: Exception) {
            Log.e("NomineeService", "Error accepting invitation: ${e.message}")
            Result.failure(e)
        }
    }
    
    suspend fun removeNominee(nominee: NomineeEntity): Result<Unit> {
        return try {
            nomineeRepository.deleteNominee(nominee)
            
            // Reload nominees
            if (nominee.vaultId != null) {
                loadNominees(nominee.vaultId!!)
            }
            
            Log.d("NomineeService", "✅ Nominee removed: ${nominee.name}")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e("NomineeService", "Error removing nominee: ${e.message}")
            Result.failure(e)
        }
    }
    
    suspend fun revokeNominee(nominee: NomineeEntity): Result<Unit> {
        return try {
            val updatedNominee = nominee.copy(
                statusRaw = "revoked"
            )
            
            nomineeRepository.updateNominee(updatedNominee)
            
            // Reload nominees
            if (nominee.vaultId != null) {
                loadNominees(nominee.vaultId!!)
            }
            
            Log.d("NomineeService", "✅ Nominee revoked: ${nominee.name}")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e("NomineeService", "Error revoking nominee: ${e.message}")
            Result.failure(e)
        }
    }
}
