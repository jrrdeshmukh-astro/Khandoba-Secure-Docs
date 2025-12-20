package com.khandoba.securedocs.data.repository

import android.util.Log
import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.dao.NomineeDao
import com.khandoba.securedocs.data.entity.NomineeEntity
import com.khandoba.securedocs.data.supabase.SupabaseService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.first
import kotlinx.serialization.Serializable
import java.util.Date
import java.util.UUID

@Serializable
data class SupabaseNominee(
    val id: UUID,
    val vault_id: UUID,
    val user_id: UUID,
    val invited_by_user_id: UUID? = null,
    val status: String = "pending", // "pending", "accepted", "active", "inactive", "revoked"
    val invited_at: String, // ISO 8601 date string
    val accepted_at: String? = null,
    val declined_at: String? = null,
    val revoked_at: String? = null,
    val access_level: String = "read", // "read", "write", "admin"
    val selected_document_ids: List<String>? = null, // JSON array of UUID strings
    val session_expires_at: String? = null,
    val is_subset_access: Boolean = false,
    val created_at: String,
    val updated_at: String
)

class NomineeRepository(
    private val nomineeDao: NomineeDao,
    private val supabaseService: SupabaseService?
) {
    fun getNomineesForVault(vaultId: UUID): Flow<List<NomineeEntity>> {
        // For now, just return from Room
        // Supabase sync can be added later if needed
        return nomineeDao.getNomineesForVault(vaultId)
    }
    
    suspend fun insertNominee(nominee: NomineeEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseNominee = convertToSupabase(nominee)
                supabaseService.insert("nominees", supabaseNominee)
            } catch (e: Exception) {
                nomineeDao.insertNominee(nominee)
            }
        } else {
            nomineeDao.insertNominee(nominee)
        }
    }
    
    suspend fun updateNominee(nominee: NomineeEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseNominee = convertToSupabase(nominee)
                supabaseService.update("nominees", nominee.id, supabaseNominee)
            } catch (e: Exception) {
                nomineeDao.updateNominee(nominee)
            }
        } else {
            nomineeDao.updateNominee(nominee)
        }
    }
    
    suspend fun deleteNominee(nominee: NomineeEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                supabaseService.delete("nominees", nominee.id)
            } catch (e: Exception) {
                nomineeDao.deleteNominee(nominee)
            }
        } else {
            nomineeDao.deleteNominee(nominee)
        }
    }
    
    private fun convertToSupabase(entity: NomineeEntity): SupabaseNominee {
        // TODO: Need user_id from user lookup - for now use placeholder
        return SupabaseNominee(
            id = entity.id,
            vault_id = entity.vaultId ?: UUID.randomUUID(),
            user_id = UUID.randomUUID(), // TODO: Get from user lookup by email/phone
            invited_by_user_id = entity.invitedByUserID,
            status = entity.statusRaw,
            invited_at = entity.invitedAt.toISOString(),
            accepted_at = entity.acceptedAt?.toISOString(),
            declined_at = null,
            revoked_at = null,
            access_level = "read", // Default access level
            selected_document_ids = entity.selectedDocumentIDs?.map { it.toString() },
            session_expires_at = entity.sessionExpiresAt?.toISOString(),
            is_subset_access = entity.isSubsetAccess,
            created_at = entity.invitedAt.toISOString(),
            updated_at = Date().toISOString()
        )
    }
    
    private fun convertFromSupabase(supabaseNominee: SupabaseNominee): NomineeEntity {
        return NomineeEntity(
            id = supabaseNominee.id,
            name = "", // TODO: Fetch from users table using user_id
            email = null, // TODO: Fetch from users table
            phoneNumber = null,
            statusRaw = supabaseNominee.status,
            invitedAt = Date.from(java.time.Instant.parse(supabaseNominee.invited_at)),
            acceptedAt = supabaseNominee.accepted_at?.let { Date.from(java.time.Instant.parse(it)) },
            lastActiveAt = null, // Not in SupabaseNominee
            inviteToken = UUID.randomUUID().toString(), // Generate new token
            vaultId = supabaseNominee.vault_id,
            invitedByUserID = supabaseNominee.invited_by_user_id,
            isSubsetAccess = supabaseNominee.is_subset_access,
            selectedDocumentIDs = supabaseNominee.selected_document_ids?.mapNotNull { 
                try { UUID.fromString(it) } catch (e: Exception) { null }
            }
        )
    }
    
    private fun Date.toISOString(): String {
        return java.time.Instant.ofEpochMilli(this.time)
            .atZone(java.time.ZoneId.of("UTC"))
            .format(java.time.format.DateTimeFormatter.ISO_INSTANT)
    }
}
