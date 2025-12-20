package com.khandoba.securedocs.data.repository

import android.util.Log
import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.dao.DocumentDao
import com.khandoba.securedocs.data.entity.DocumentEntity
import com.khandoba.securedocs.data.supabase.SupabaseService
import com.khandoba.securedocs.data.supabase.SupabaseDocument
import kotlinx.coroutines.flow.Flow
import org.json.JSONObject
import java.util.Base64
import java.util.Date
import java.util.UUID

class DocumentRepository(
    private val documentDao: DocumentDao,
    private val supabaseService: SupabaseService?
) {
    fun getDocumentsByVault(vaultId: UUID): Flow<List<DocumentEntity>> {
        return documentDao.getDocumentsByVault(vaultId)
    }
    
    suspend fun insertDocument(document: DocumentEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseDocument = convertToSupabase(document)
                supabaseService.insert("documents", supabaseDocument)
            } catch (e: Exception) {
                documentDao.insertDocument(document)
            }
        } else {
            documentDao.insertDocument(document)
        }
    }
    
    suspend fun updateDocument(document: DocumentEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseDocument = convertToSupabase(document)
                supabaseService.update("documents", document.id, supabaseDocument)
            } catch (e: Exception) {
                documentDao.updateDocument(document)
            }
        } else {
            documentDao.updateDocument(document)
        }
    }
    
    suspend fun deleteDocument(document: DocumentEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                supabaseService.delete("documents", document.id)
            } catch (e: Exception) {
                documentDao.deleteDocument(document)
            }
        } else {
            documentDao.deleteDocument(document)
        }
    }
    
    private suspend fun convertToSupabase(entity: DocumentEntity): SupabaseDocument {
        // Upload encrypted file data to Supabase Storage if available
        var storagePath: String? = null
        if (entity.encryptedFileData != null && supabaseService != null) {
            try {
                val filePath = "${entity.vaultId}/${entity.id}${entity.fileExtension?.let { ".$it" } ?: ""}"
                supabaseService.uploadFile(
                    bucket = AppConfig.ENCRYPTED_DOCUMENTS_BUCKET,
                    path = filePath,
                    data = entity.encryptedFileData
                )
                storagePath = filePath
                Log.d("DocumentRepository", "✅ Uploaded document to storage: $filePath")
            } catch (e: Exception) {
                Log.e("DocumentRepository", "❌ Failed to upload document to storage: ${e.message}")
                // Continue without storage path - document will still be saved in database
            }
        }
        
        // Convert metadata JSON string to Map
        val metadataMap: Map<String, String>? = entity.metadata?.let { metadataJson ->
            try {
                val jsonObject = JSONObject(metadataJson)
                val map = mutableMapOf<String, String>()
                jsonObject.keys().forEach { key ->
                    map[key] = jsonObject.getString(key)
                }
                map
            } catch (e: Exception) {
                Log.e("DocumentRepository", "Failed to parse metadata JSON: ${e.message}")
                null
            }
        }
        
        return SupabaseDocument(
            id = entity.id,
            vault_id = entity.vaultId ?: UUID.randomUUID(),
            name = entity.name,
            file_extension = entity.fileExtension,
            mime_type = entity.mimeType,
            file_size = entity.fileSize,
            storage_path = storagePath,
            created_at = entity.createdAt.toISOString(),
            uploaded_at = entity.uploadedAt.toISOString(),
            last_modified_at = entity.lastModifiedAt?.toISOString(),
            encryption_key_data = entity.encryptionKeyData?.let {
                Base64.getEncoder().encodeToString(it)
            },
            is_encrypted = entity.isEncrypted,
            document_type = entity.documentType,
            source_sink_type = entity.sourceSinkType,
            is_archived = entity.isArchived,
            is_redacted = entity.isRedacted,
            status = entity.status,
            extracted_text = entity.extractedText,
            ai_tags = entity.aiTags,
            file_hash = entity.fileHash,
            metadata = metadataMap,
            author = entity.author,
            camera_info = entity.cameraInfo,
            device_id = entity.deviceID,
            uploaded_by_user_id = entity.uploadedByUserID,
            updated_at = Date().toISOString()
        )
    }
    
    private fun convertFromSupabase(supabase: SupabaseDocument): DocumentEntity {
        return DocumentEntity(
            id = supabase.id,
            name = supabase.name,
            fileExtension = supabase.file_extension,
            mimeType = supabase.mime_type,
            fileSize = supabase.file_size,
            createdAt = supabase.created_at.toDate(),
            uploadedAt = supabase.uploaded_at.toDate(),
            lastModifiedAt = supabase.last_modified_at?.toDate(),
            encryptionKeyData = supabase.encryption_key_data?.let {
                Base64.getDecoder().decode(it)
            },
            isEncrypted = supabase.is_encrypted,
            documentType = supabase.document_type,
            sourceSinkType = supabase.source_sink_type,
            isArchived = supabase.is_archived,
            isRedacted = supabase.is_redacted,
            status = supabase.status,
            extractedText = supabase.extracted_text,
            aiTags = supabase.ai_tags,
            fileHash = supabase.file_hash,
            author = supabase.author,
            cameraInfo = supabase.camera_info,
            deviceID = supabase.device_id,
            vaultId = supabase.vault_id,
            uploadedByUserID = supabase.uploaded_by_user_id
        )
    }
    
    private fun Date.toISOString(): String {
        return java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.format(this)
    }
    
    private fun String.toDate(): Date {
        return java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.parse(this) ?: Date()
    }
}

