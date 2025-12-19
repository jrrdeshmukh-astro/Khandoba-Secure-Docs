package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "vault_sessions",
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
            childColumns = ["userId"],
            onDelete = ForeignKey.SET_NULL
        )
    ],
    indices = [Index(value = ["vaultId"]), Index(value = ["userId"])]
)
data class VaultSessionEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val startedAt: Date = Date(),
    val expiresAt: Date = Date(),
    val isActive: Boolean = false,
    val wasExtended: Boolean = false,
    val vaultId: UUID? = null,
    val userId: UUID? = null
)
