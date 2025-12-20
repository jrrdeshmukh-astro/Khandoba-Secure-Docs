package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "vault_access_requests",
    foreignKeys = [
        ForeignKey(
            entity = VaultEntity::class,
            parentColumns = ["id"],
            childColumns = ["vaultId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["vaultId"]), Index(value = ["requesterUserID"])]
)
data class VaultAccessRequestEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val requestedAt: Date = Date(),
    val status: String = "pending", // "pending", "accepted", "declined", "expired"
    val requestType: String = "request", // "request" or "send"
    val message: String? = null,
    val expiresAt: Date? = null,
    val requesterUserID: UUID? = null,
    val requesterName: String? = null,
    val requesterEmail: String? = null,
    val requesterPhone: String? = null,
    val recipientUserID: UUID? = null,
    val recipientName: String? = null,
    val recipientEmail: String? = null,
    val recipientPhone: String? = null,
    val vaultId: UUID? = null,
    val vaultName: String? = null,
    val cloudKitShareRecordID: String? = null,
    val accessToken: String = UUID.randomUUID().toString(),
    val respondedAt: Date? = null,
    val responseMessage: String? = null
)
