package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "documents",
    foreignKeys = [
        ForeignKey(
            entity = VaultEntity::class,
            parentColumns = ["id"],
            childColumns = ["vaultId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["vaultId"]), Index(value = ["uploadedByUserID"])]
)
data class DocumentEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val name: String = "",
    val fileExtension: String? = null,
    val mimeType: String? = null,
    val fileSize: Long = 0,
    val createdAt: Date = Date(),
    val uploadedAt: Date = Date(),
    val lastModifiedAt: Date? = null,
    val encryptedFileData: ByteArray? = null,
    val encryptionKeyData: ByteArray? = null,
    val isEncrypted: Boolean = true,
    val documentType: String = "other", // "image", "pdf", "video", "audio", "text", "other"
    val sourceSinkType: String? = null, // "source", "sink", "both"
    val isArchived: Boolean = false,
    val isRedacted: Boolean = false,
    val status: String = "active", // "active", "archived", "deleted"
    val extractedText: String? = null,
    val aiTags: List<String> = emptyList(),
    val fileHash: String? = null,
    val metadata: String? = null, // JSON string
    val author: String? = null,
    val cameraInfo: String? = null,
    val deviceID: String? = null,
    val vaultId: UUID? = null,
    val uploadedByUserID: UUID? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as DocumentEntity
        if (id != other.id) return false
        if (encryptedFileData != null) {
            if (other.encryptedFileData == null) return false
            if (!encryptedFileData.contentEquals(other.encryptedFileData)) return false
        } else if (other.encryptedFileData != null) return false
        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + (encryptedFileData?.contentHashCode() ?: 0)
        return result
    }
}
