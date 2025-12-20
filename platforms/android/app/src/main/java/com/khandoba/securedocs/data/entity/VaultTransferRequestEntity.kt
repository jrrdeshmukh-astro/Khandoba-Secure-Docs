package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "vault_transfer_requests",
    foreignKeys = [
        ForeignKey(
            entity = VaultEntity::class,
            parentColumns = ["id"],
            childColumns = ["vaultId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["vaultId"]), Index(value = ["requestedByUserID"])]
)
data class VaultTransferRequestEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val requestedAt: Date = Date(),
    val status: String = "pending", // "pending", "approved", "denied", "completed"
    val reason: String? = null,
    val newOwnerID: UUID? = null,
    val newOwnerName: String? = null,
    val newOwnerPhone: String? = null,
    val newOwnerEmail: String? = null,
    val transferToken: String = UUID.randomUUID().toString(),
    val approvedAt: Date? = null,
    val approverID: UUID? = null,
    val vaultId: UUID? = null,
    val requestedByUserID: UUID? = null,
    val mlScore: Double? = null, // ML threat analysis score
    val mlRecommendation: String? = null, // ML recommendation (approve/deny/review)
    val threatIndex: Double? = null // Real-time threat index for this transfer
)
