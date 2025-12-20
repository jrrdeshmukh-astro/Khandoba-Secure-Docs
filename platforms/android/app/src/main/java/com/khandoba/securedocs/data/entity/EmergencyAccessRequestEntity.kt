package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "emergency_access_requests",
    foreignKeys = [
        ForeignKey(
            entity = VaultEntity::class,
            parentColumns = ["id"],
            childColumns = ["vaultId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["vaultId"]), Index(value = ["requesterID"])]
)
data class EmergencyAccessRequestEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val requestedAt: Date = Date(),
    val reason: String = "",
    val urgency: String = "medium", // "low", "medium", "high", "critical"
    val status: String = "pending", // "pending", "approved", "denied"
    val approvedAt: Date? = null,
    val approverID: UUID? = null,
    val expiresAt: Date? = null,
    val passCode: String? = null, // Generated identification pass code (UUID string)
    val mlScore: Double? = null, // ML confidence score (0.0 to 1.0)
    val mlRecommendation: String? = null, // ML reasoning/explanation
    val vaultId: UUID? = null,
    val requesterID: UUID? = null
)
