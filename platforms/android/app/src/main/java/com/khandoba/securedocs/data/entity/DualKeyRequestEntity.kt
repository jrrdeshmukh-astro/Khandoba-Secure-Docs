package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "dual_key_requests",
    foreignKeys = [
        ForeignKey(
            entity = VaultEntity::class,
            parentColumns = ["id"],
            childColumns = ["vaultId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["id"],
            childColumns = ["requesterId"],
            onDelete = ForeignKey.SET_NULL
        )
    ],
    indices = [Index(value = ["vaultId"]), Index(value = ["requesterId"])]
)
data class DualKeyRequestEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val requestedAt: Date = Date(),
    val status: String = "pending", // "pending", "approved", "denied"
    val reason: String? = null,
    val approvedAt: Date? = null,
    val deniedAt: Date? = null,
    val approverID: UUID? = null,
    val mlScore: Double? = null,
    val logicalReasoning: String? = null,
    val decisionMethod: String? = null, // "ml_auto" or "logic_reasoning"
    val vaultId: UUID? = null,
    val requesterId: UUID? = null
)
