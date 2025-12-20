package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "vaults",
    foreignKeys = [
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["id"],
            childColumns = ["ownerId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["ownerId"])]
)
data class VaultEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val name: String = "",
    val vaultDescription: String? = null,
    val createdAt: Date = Date(),
    val lastAccessedAt: Date? = null,
    val status: String = "locked", // "active", "locked", "archived"
    val keyType: String = "single", // "single", "dual"
    val vaultType: String = "both", // "source", "sink", "both"
    val isSystemVault: Boolean = false,
    val isAntiVault: Boolean = false,
    val monitoredVaultID: UUID? = null,
    val antiVaultID: UUID? = null,
    val antiVaultStatus: String = "locked",
    val antiVaultAutoUnlockPolicyData: ByteArray? = null,
    val antiVaultThreatDetectionSettingsData: ByteArray? = null,
    val antiVaultLastIntelReportID: UUID? = null,
    val antiVaultLastUnlockedAt: Date? = null,
    val antiVaultCreatedAt: Date? = null,
    val encryptionKeyData: ByteArray? = null,
    val isEncrypted: Boolean = true,
    val isZeroKnowledge: Boolean = true,
    val ownerId: UUID? = null,
    val relationshipOfficerID: UUID? = null,
    val threatIndex: Double = 0.0,
    val threatLevel: String = "low", // "low", "medium", "high", "critical"
    val lastThreatAssessmentAt: Date? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as VaultEntity
        if (id != other.id) return false
        if (name != other.name) return false
        if (encryptionKeyData != null) {
            if (other.encryptionKeyData == null) return false
            if (!encryptionKeyData.contentEquals(other.encryptionKeyData)) return false
        } else if (other.encryptionKeyData != null) return false
        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + name.hashCode()
        result = 31 * result + (encryptionKeyData?.contentHashCode() ?: 0)
        return result
    }
}
