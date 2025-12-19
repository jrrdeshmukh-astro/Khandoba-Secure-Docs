package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "vault_access_logs",
    foreignKeys = [
        ForeignKey(
            entity = VaultEntity::class,
            parentColumns = ["id"],
            childColumns = ["vaultId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["vaultId"]), Index(value = ["userID"])]
)
data class VaultAccessLogEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val timestamp: Date = Date(),
    val accessType: String = "viewed", // "opened", "closed", "viewed", "modified", etc.
    val userID: UUID? = null,
    val userName: String? = null,
    val deviceInfo: String? = null,
    val locationLatitude: Double? = null,
    val locationLongitude: Double? = null,
    val ipAddress: String? = null,
    val documentID: UUID? = null,
    val documentName: String? = null,
    val vaultId: UUID? = null
)
