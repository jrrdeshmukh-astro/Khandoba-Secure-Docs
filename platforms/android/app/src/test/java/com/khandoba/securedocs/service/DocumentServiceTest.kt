package com.khandoba.securedocs.service

import android.content.Context
import android.net.Uri
import com.khandoba.securedocs.data.entity.DocumentEntity
import com.khandoba.securedocs.data.repository.DocumentRepository
import com.khandoba.securedocs.data.supabase.SupabaseService
import io.mockk.*
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.*

class DocumentServiceTest {
    private lateinit var mockContext: Context
    private lateinit var mockRepository: DocumentRepository
    private lateinit var mockSupabaseService: SupabaseService
    private lateinit var mockEncryptionService: EncryptionService
    private lateinit var documentService: DocumentService
    
    @Before
    fun setup() {
        mockContext = mockk(relaxed = true)
        mockRepository = mockk(relaxed = true)
        mockSupabaseService = mockk(relaxed = true)
        mockEncryptionService = mockk(relaxed = true)
        
        documentService = DocumentService(
            context = mockContext,
            documentRepository = mockRepository,
            supabaseService = mockSupabaseService,
            encryptionService = mockEncryptionService
        )
    }
    
    @Test
    fun `test upload document`() = runTest {
        val vaultId = UUID.randomUUID()
        val userId = UUID.randomUUID()
        val documentId = UUID.randomUUID()
        val mockUri = mockk<Uri>(relaxed = true)
        val fileName = "test.pdf"
        val fileData = "test data".toByteArray()
        
        every { mockContext.contentResolver.openInputStream(mockUri) } returns
            fileData.inputStream().buffered()
        every { mockContext.contentResolver.getType(mockUri) } returns "application/pdf"
        every { mockEncryptionService.encrypt(any()) } returns fileData
        every { mockEncryptionService.generateKey() } returns ByteArray(32)
        coEvery { mockRepository.insertDocument(any()) } just Runs
        
        val result = documentService.uploadDocument(vaultId, mockUri, fileName, userId)
        
        assertTrue("Document upload should succeed", result.isSuccess)
        coVerify { mockRepository.insertDocument(any()) }
    }
    
    @Test
    fun `test download document`() = runTest {
        val documentId = UUID.randomUUID()
        val fileData = "test data".toByteArray()
        val encryptedData = "encrypted".toByteArray()
        val encryptionKey = ByteArray(32)
        
        val document = DocumentEntity(
            id = documentId,
            name = "test.pdf",
            encryptedFileData = encryptedData,
            encryptionKeyData = encryptionKey,
            isEncrypted = true
        )
        
        every { mockEncryptionService.decrypt(encryptedData, encryptionKey) } returns fileData
        
        val result = documentService.downloadDocument(document)
        
        assertTrue("Document download should succeed", result.isSuccess)
        assertArrayEquals("Downloaded data should match", fileData, result.getOrNull())
    }
    
    @Test
    fun `test load documents for vault`() = runTest {
        val vaultId = UUID.randomUUID()
        val documents = listOf(
            DocumentEntity(id = UUID.randomUUID(), name = "doc1.pdf", vaultId = vaultId),
            DocumentEntity(id = UUID.randomUUID(), name = "doc2.pdf", vaultId = vaultId)
        )
        
        coEvery { mockRepository.getDocumentsByVault(vaultId) } returns
            kotlinx.coroutines.flow.flowOf(documents)
        
        documentService.loadDocuments(vaultId)
        
        val loadedDocuments = documentService.documents.first()
        assertTrue("Should load documents for vault", loadedDocuments.isNotEmpty())
    }
}
