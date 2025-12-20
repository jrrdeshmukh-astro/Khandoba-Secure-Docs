package com.khandoba.securedocs.viewmodel

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.khandoba.securedocs.data.entity.DocumentEntity
import com.khandoba.securedocs.service.DocumentService
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.util.UUID

class DocumentViewModel(
    private val documentService: DocumentService
) : ViewModel() {
    
    val documents: StateFlow<List<DocumentEntity>> = documentService.documents
    val isLoading: StateFlow<Boolean> = documentService.isLoading
    val uploadProgress: StateFlow<Double> = documentService.uploadProgress
    
    fun loadDocuments(vaultId: UUID) {
        viewModelScope.launch {
            documentService.loadDocuments(vaultId)
        }
    }
    
    fun uploadDocument(
        vaultId: UUID,
        uri: Uri,
        name: String,
        uploadedByUserID: UUID,
        onResult: (Result<DocumentEntity>) -> Unit
    ) {
        viewModelScope.launch {
            val result = documentService.uploadDocument(vaultId, uri, name, uploadedByUserID)
            onResult(result)
        }
    }
    
    fun downloadDocument(
        document: DocumentEntity,
        onResult: (Result<ByteArray>) -> Unit
    ) {
        viewModelScope.launch {
            val result = documentService.downloadDocument(document)
            onResult(result)
        }
    }
    
    fun deleteDocument(
        document: DocumentEntity,
        onResult: (Result<Unit>) -> Unit
    ) {
        viewModelScope.launch {
            val result = documentService.deleteDocument(document)
            onResult(result)
        }
    }
    
    fun archiveDocument(
        document: DocumentEntity,
        onResult: (Result<Unit>) -> Unit
    ) {
        viewModelScope.launch {
            val result = documentService.archiveDocument(document)
            onResult(result)
        }
    }
    
    fun bulkDeleteDocuments(
        documentIds: List<UUID>,
        onResult: (Result<Unit>) -> Unit
    ) {
        viewModelScope.launch {
            val result = documentService.bulkDeleteDocuments(documentIds)
            onResult(result)
        }
    }
    
    fun bulkArchiveDocuments(
        documentIds: List<UUID>,
        onResult: (Result<Unit>) -> Unit
    ) {
        viewModelScope.launch {
            val result = documentService.bulkArchiveDocuments(documentIds)
            onResult(result)
        }
    }
}
