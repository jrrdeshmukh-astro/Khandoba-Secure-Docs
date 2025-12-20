package com.khandoba.securedocs.service

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.khandoba.securedocs.data.entity.DocumentEntity
import io.mockk.*
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.*

class DocumentIndexingServiceTest {
    private lateinit var documentIndexingService: DocumentIndexingService
    
    @Before
    fun setup() {
        documentIndexingService = DocumentIndexingService()
    }
    
    @Test
    fun `test index document with text`() = runTest {
        val document = DocumentEntity(
            id = UUID.randomUUID(),
            name = "test.pdf",
            documentType = "pdf",
            extractedText = "This is a test document about invoices and receipts."
        )
        
        val result = documentIndexingService.indexDocument(document)
        
        assertNotNull("Indexed document should not be null", result)
        assertNotEquals("Document name should be updated", document.name, result.name)
        assertTrue("Document should have tags", result.aiTags.isNotEmpty())
    }
    
    @Test
    fun `test generate intelligent name for invoice`() = runTest {
        val document = DocumentEntity(
            id = UUID.randomUUID(),
            name = "document.pdf",
            documentType = "pdf",
            extractedText = "Invoice number 12345 dated 12/25/2024 for ABC Company"
        )
        
        val result = documentIndexingService.indexDocument(document)
        
        assertTrue("Name should contain invoice keyword", 
            result.name.contains("Invoice", ignoreCase = true) ||
            result.name.contains("invoice", ignoreCase = true))
    }
    
    @Test
    fun `test generate intelligent name for receipt`() = runTest {
        val document = DocumentEntity(
            id = UUID.randomUUID(),
            name = "scan.jpg",
            documentType = "image",
            extractedText = "Receipt from store purchase on 12/25/2024"
        )
        
        val result = documentIndexingService.indexDocument(document)
        
        assertTrue("Name should contain receipt keyword", 
            result.name.contains("Receipt", ignoreCase = true) ||
            result.name.contains("receipt", ignoreCase = true))
    }
    
    @Test
    fun `test tag generation`() = runTest {
        val document = DocumentEntity(
            id = UUID.randomUUID(),
            name = "test.pdf",
            documentType = "pdf",
            extractedText = "Medical report for patient John Doe"
        )
        
        val result = documentIndexingService.indexDocument(document)
        
        assertTrue("Should generate tags", result.aiTags.isNotEmpty())
        assertTrue("Should include medical tag", 
            result.aiTags.any { it.contains("medical", ignoreCase = true) })
    }
}
