package com.khandoba.securedocs.service

import android.content.Context
import android.net.Uri
import android.util.Log
import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.entity.DocumentEntity
import com.khandoba.securedocs.data.repository.DocumentRepository
import com.khandoba.securedocs.data.supabase.SupabaseService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.File
import java.io.FileInputStream
import java.util.Date
import java.util.UUID

class DocumentService(
    private val context: Context,
    private val documentRepository: DocumentRepository,
    private val supabaseService: SupabaseService,
    private val encryptionService: EncryptionService,
    private val documentIndexingService: DocumentIndexingService? = null
) {
    private val _documents = MutableStateFlow<List<DocumentEntity>>(emptyList())
    val documents: StateFlow<List<DocumentEntity>> = _documents.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _uploadProgress = MutableStateFlow(0.0)
    val uploadProgress: StateFlow<Double> = _uploadProgress.asStateFlow()
    
    suspend fun loadDocuments(vaultId: UUID) {
        _isLoading.value = true
        try {
            documentRepository.getDocumentsByVault(vaultId).collect { documentList ->
                _documents.value = documentList.filter { it.status == "active" && !it.isArchived }
            }
        } catch (e: Exception) {
            Log.e("DocumentService", "Error loading documents: ${e.message}")
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun uploadDocument(
        vaultId: UUID,
        uri: Uri,
        name: String,
        uploadedByUserID: UUID
    ): Result<DocumentEntity> {
        _isLoading.value = true
        _uploadProgress.value = 0.0
        
        return try {
            // Read file
            val inputStream = context.contentResolver.openInputStream(uri)
                ?: return Result.failure(Exception("Cannot open file"))
            
            val fileData = inputStream.readBytes()
            inputStream.close()
            
            _uploadProgress.value = 0.3
            
            // Encrypt file
            val encryptedData = encryptionService.encrypt(fileData)
            val encryptionKey = encryptionService.generateKey()
            
            _uploadProgress.value = 0.6
            
            // Determine file type
            val mimeType = context.contentResolver.getType(uri) ?: "application/octet-stream"
            val fileExtension = name.substringAfterLast(".", "")
            val documentType = when {
                mimeType.startsWith("image/") -> "image"
                mimeType.startsWith("video/") -> "video"
                mimeType.startsWith("audio/") -> "audio"
                mimeType == "application/pdf" -> "pdf"
                mimeType.startsWith("text/") -> "text"
                else -> "other"
            }
            
            // Create initial document entity for indexing (before encryption)
            var documentName = name
            var aiTags = emptyList<String>()
            var extractedText: String? = null
            
            // Index document and generate intelligent name/tags (on unencrypted data)
            if (documentIndexingService != null && documentType == "image") {
                try {
                    // For images, we need to create a bitmap for OCR
                    val inputStream = context.contentResolver.openInputStream(uri)
                    val bitmap = android.graphics.BitmapFactory.decodeStream(inputStream)
                    inputStream?.close()
                    
                    if (bitmap != null) {
                        // Index document to extract text and generate tags/name
                        val indexedDoc = documentIndexingService.indexDocument(
                            document = DocumentEntity(
                                id = UUID.randomUUID(),
                                name = name,
                                fileExtension = fileExtension,
                                mimeType = mimeType,
                                documentType = documentType,
                                extractedText = null,
                                aiTags = emptyList()
                            ),
                            imageBitmap = bitmap
                        )
                        
                        documentName = indexedDoc.name
                        aiTags = indexedDoc.aiTags
                        extractedText = indexedDoc.extractedText
                        
                        bitmap.recycle()
                    }
                } catch (e: Exception) {
                    Log.e("DocumentService", "Indexing failed, using original name: ${e.message}")
                    // Continue with original name if indexing fails
                }
            }
            
            _uploadProgress.value = 0.5
            
            // Upload to Supabase Storage if enabled
            var storagePath: String? = null
            if (AppConfig.USE_SUPABASE) {
                try {
                    storagePath = "${vaultId}/${UUID.randomUUID()}.encrypted"
                    supabaseService.uploadFile(
                        bucket = AppConfig.ENCRYPTED_DOCUMENTS_BUCKET,
                        path = storagePath,
                        data = encryptedData
                    )
                    _uploadProgress.value = 0.8
                } catch (e: Exception) {
                    Log.e("DocumentService", "Failed to upload to Supabase Storage: ${e.message}")
                    // Continue with local storage
                }
            }
            
            // Create document entity with intelligent name and tags
            val document = DocumentEntity(
                id = UUID.randomUUID(),
                name = documentName, // Use intelligent name from indexing
                fileExtension = fileExtension,
                mimeType = mimeType,
                fileSize = fileData.size.toLong(),
                createdAt = Date(),
                uploadedAt = Date(),
                encryptedFileData = if (storagePath == null) encryptedData else null,
                encryptionKeyData = encryptionKey,
                isEncrypted = true,
                documentType = documentType,
                status = "active",
                vaultId = vaultId,
                uploadedByUserID = uploadedByUserID,
                aiTags = aiTags, // Use tags from indexing
                extractedText = extractedText // Store extracted text for search
            )
            
            // Save to database
            documentRepository.insertDocument(document)
            
            _uploadProgress.value = 1.0
            _isLoading.value = false
            
            Log.d("DocumentService", "✅ Document uploaded: ${document.name}")
            Result.success(document)
        } catch (e: Exception) {
            _isLoading.value = false
            _uploadProgress.value = 0.0
            Log.e("DocumentService", "Upload failed: ${e.message}")
            Result.failure(e)
        }
    }
    
    suspend fun downloadDocument(document: DocumentEntity): Result<ByteArray> {
        _isLoading.value = true
        return try {
            val encryptedData = if (document.encryptedFileData != null) {
                document.encryptedFileData!!
            } else if (AppConfig.USE_SUPABASE && document.id != null) {
                // Download from Supabase Storage
                val storagePath = "${document.vaultId}/${document.id}.encrypted"
                supabaseService.downloadFile(
                    bucket = AppConfig.ENCRYPTED_DOCUMENTS_BUCKET,
                    path = storagePath
                )
            } else {
                return Result.failure(Exception("Document data not available"))
            }
            
            // Decrypt
            val decryptedData = encryptionService.decrypt(encryptedData)
            
            _isLoading.value = false
            Result.success(decryptedData)
        } catch (e: Exception) {
            _isLoading.value = false
            Log.e("DocumentService", "Download failed: ${e.message}")
            Result.failure(e)
        }
    }
    
    suspend fun deleteDocument(document: DocumentEntity): Result<Unit> {
        _isLoading.value = true
        return try {
            // Delete from Supabase Storage if stored there
            if (AppConfig.USE_SUPABASE) {
                try {
                    val storagePath = "${document.vaultId}/${document.id}.encrypted"
                    supabaseService.deleteFile(
                        bucket = AppConfig.ENCRYPTED_DOCUMENTS_BUCKET,
                        path = storagePath
                    )
                } catch (e: Exception) {
                    Log.w("DocumentService", "Failed to delete from storage: ${e.message}")
                }
            }
            
            // Update status to deleted
            val updatedDocument = document.copy(status = "deleted")
            documentRepository.updateDocument(updatedDocument)
            
            _isLoading.value = false
            Result.success(Unit)
        } catch (e: Exception) {
            _isLoading.value = false
            Result.failure(e)
        }
    }
    
    suspend fun archiveDocument(document: DocumentEntity): Result<Unit> {
        return try {
            val updatedDocument = document.copy(isArchived = true)
            documentRepository.updateDocument(updatedDocument)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun bulkDeleteDocuments(documentIds: List<UUID>): Result<Unit> {
        _isLoading.value = true
        return try {
            val documents = _documents.value.filter { it.id in documentIds }
            documents.forEach { document ->
                deleteDocument(document)
            }
            _isLoading.value = false
            Result.success(Unit)
        } catch (e: Exception) {
            _isLoading.value = false
            Result.failure(e)
        }
    }
    
    suspend fun bulkArchiveDocuments(documentIds: List<UUID>): Result<Unit> {
        _isLoading.value = true
        return try {
            val documents = _documents.value.filter { it.id in documentIds }
            documents.forEach { document ->
                archiveDocument(document)
            }
            _isLoading.value = false
            Result.success(Unit)
        } catch (e: Exception) {
            _isLoading.value = false
            Result.failure(e)
        }
    }
}
