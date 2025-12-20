package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "document_versions",
    foreignKeys = [
        ForeignKey(
            entity = DocumentEntity::class,
            parentColumns = ["id"],
            childColumns = ["documentId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["documentId"])]
)
data class DocumentVersionEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val versionNumber: Int = 1,
    val createdAt: Date = Date(),
    val fileSize: Long = 0,
    val encryptedFileData: ByteArray? = null,
    val changes: String? = null,
    val documentId: UUID? = null
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as DocumentVersionEntity
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
