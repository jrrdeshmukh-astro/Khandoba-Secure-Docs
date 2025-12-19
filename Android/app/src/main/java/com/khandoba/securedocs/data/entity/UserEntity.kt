package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val googleUserID: String = "", // Android equivalent of appleUserID
    val fullName: String = "",
    val email: String? = null,
    val profilePictureData: ByteArray? = null,
    val createdAt: Date = Date(),
    val lastActiveAt: Date = Date(),
    val isActive: Boolean = true,
    val isPremiumSubscriber: Boolean = false,
    val subscriptionExpiryDate: Date? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as UserEntity
        if (id != other.id) return false
        if (googleUserID != other.googleUserID) return false
        if (fullName != other.fullName) return false
        if (email != other.email) return false
        if (profilePictureData != null) {
            if (other.profilePictureData == null) return false
            if (!profilePictureData.contentEquals(other.profilePictureData)) return false
        } else if (other.profilePictureData != null) return false
        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + googleUserID.hashCode()
        result = 31 * result + fullName.hashCode()
        result = 31 * result + (email?.hashCode() ?: 0)
        result = 31 * result + (profilePictureData?.contentHashCode() ?: 0)
        return result
    }
}
