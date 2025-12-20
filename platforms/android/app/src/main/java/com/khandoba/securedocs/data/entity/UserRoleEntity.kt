package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "user_roles",
    foreignKeys = [
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["id"],
            childColumns = ["userId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["userId"])]
)
data class UserRoleEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val roleRawValue: String = "client",
    val assignedAt: Date = Date(),
    val isActive: Boolean = true,
    val userId: UUID? = null
)
