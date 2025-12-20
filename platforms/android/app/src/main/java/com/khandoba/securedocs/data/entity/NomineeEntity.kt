package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "nominees",
    foreignKeys = [
        ForeignKey(
            entity = VaultEntity::class,
            parentColumns = ["id"],
            childColumns = ["vaultId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["vaultId"]), Index(value = ["invitedByUserID"])]
)
data class NomineeEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val name: String = "",
    val phoneNumber: String? = null,
    val email: String? = null,
    val statusRaw: String = "pending", // "pending", "accepted", "active", "inactive", "revoked"
    val invitedAt: Date = Date(),
    val acceptedAt: Date? = null,
    val lastActiveAt: Date? = null,
    val cloudKitShareRecordID: String? = null,
    val cloudKitParticipantID: String? = null,
    val inviteToken: String = UUID.randomUUID().toString(),
    val vaultId: UUID? = null,
    val invitedByUserID: UUID? = null,
    val isCurrentlyActive: Boolean = false,
    val currentSessionID: UUID? = null,
    val selectedDocumentIDs: List<UUID>? = null,
    val sessionExpiresAt: Date? = null,
    val isSubsetAccess: Boolean = false
)
