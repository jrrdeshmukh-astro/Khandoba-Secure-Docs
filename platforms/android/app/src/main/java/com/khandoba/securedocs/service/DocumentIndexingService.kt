package com.khandoba.securedocs.service

import android.graphics.Bitmap
import android.util.Log
import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.nl.entityextraction.EntityExtraction
import com.google.mlkit.nl.entityextraction.EntityExtractor
import com.google.mlkit.nl.entityextraction.EntityExtractorOptions
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.khandoba.securedocs.data.entity.DocumentEntity
import kotlinx.coroutines.tasks.await

class DocumentIndexingService {
    private val textRecognizer = Text.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    private val entityExtractor = EntityExtraction.getClient(
        EntityExtractorOptions.Builder(EntityExtractorOptions.ENGLISH)
            .build()
    )
    
    suspend fun indexDocument(document: DocumentEntity, imageBitmap: Bitmap? = null): DocumentEntity {
        return try {
            var updatedDocument = document
            var extractedText = document.extractedText
            
            // Extract text from image if available
            if (imageBitmap != null && document.documentType == "image") {
                extractedText = extractTextFromImage(imageBitmap)
                updatedDocument = updatedDocument.copy(extractedText = extractedText)
            }
            
            // Extract entities from text
            if (extractedText != null && extractedText.isNotBlank()) {
                val entities = extractEntities(extractedText)
                val tags = generateTags(entities, extractedText)
                
                // Generate intelligent name based on content
                val intelligentName = generateIntelligentName(
                    extractedText = extractedText,
                    entities = entities,
                    currentName = document.name,
                    mimeType = document.mimeType
                )
                
                updatedDocument = updatedDocument.copy(
                    aiTags = tags,
                    name = intelligentName
                )
            }
            
            updatedDocument
        } catch (e: Exception) {
            Log.e("DocumentIndexingService", "Indexing failed: ${e.message}")
            document
        }
    }
    
    /**
     * Generate intelligent document name based on content analysis
     * Similar to Apple's NLPTaggingService.generateDocumentName
     */
    private suspend fun generateIntelligentName(
        extractedText: String,
        entities: List<String>,
        currentName: String,
        mimeType: String?
    ): String {
        val text = extractedText.lowercase()
        
        // Try to extract document type from content
        val documentType = when {
            text.contains("invoice") || text.contains("bill") -> "Invoice"
            text.contains("receipt") -> "Receipt"
            text.contains("medical") || text.contains("patient") || text.contains("prescription") -> "Medical"
            text.contains("contract") || text.contains("agreement") -> "Contract"
            text.contains("tax") || text.contains("w-2") || text.contains("1099") -> "Tax"
            text.contains("license") || text.contains("permit") -> "License"
            text.contains("insurance") || text.contains("policy") -> "Insurance"
            text.contains("bank") || text.contains("statement") -> "Bank_Statement"
            text.contains("passport") || text.contains("visa") -> "Travel_Document"
            text.contains("diploma") || text.contains("certificate") -> "Certificate"
            else -> null
        }
        
        // Extract key dates
        val datePattern = Regex("""\d{1,2}[/-]\d{1,2}[/-]\d{2,4}""")
        val dates = datePattern.findAll(text).map { it.value }.toList()
        
        // Use entities for naming (prioritize person names, locations, organizations)
        val nameParts = mutableListOf<String>()
        
        // Add document type
        if (documentType != null) {
            nameParts.add(documentType)
        }
        
        // Add relevant entities (limit to 2-3 most relevant)
        entities.take(2).forEach { entity ->
            // Clean entity name (capitalize first letter of each word)
            val cleaned = entity.split(" ").joinToString(" ") { word ->
                word.lowercase().replaceFirstChar { it.uppercase() }
            }
            if (cleaned.length > 3 && cleaned.length < 30) { // Reasonable length
                nameParts.add(cleaned)
            }
        }
        
        // Add date if found
        if (dates.isNotEmpty()) {
            val firstDate = dates.first().replace("/", "-").replace("\\", "-")
            nameParts.add(firstDate)
        }
        
        // Generate name
        val suggestedName = if (nameParts.isNotEmpty()) {
            val baseName = nameParts.joinToString("_")
            // Add file extension
            val extension = mimeType?.let { getFileExtension(it) } ?: getFileExtensionFromName(currentName)
            if (extension.isNotEmpty()) {
                "$baseName.$extension"
            } else {
                baseName
            }
        } else {
            // Fallback: use first meaningful words from text
            val words = text.split("\\s+".toRegex())
                .filter { it.length > 4 && !it.matches(Regex("[^a-zA-Z]+")) }
                .take(3)
                .joinToString("_") { it.replaceFirstChar { char -> char.uppercase() } }
            
            if (words.isNotEmpty()) {
                val extension = mimeType?.let { getFileExtension(it) } ?: getFileExtensionFromName(currentName)
                if (extension.isNotEmpty()) {
                    "$words.$extension"
                } else {
                    words
                }
            } else {
                // Final fallback: use original name
                currentName
            }
        }
        
        // Ensure name is not too long (max 100 chars)
        return if (suggestedName.length > 100) {
            suggestedName.take(97) + "..."
        } else {
            suggestedName
        }
    }
    
    private fun getFileExtension(mimeType: String): String {
        return when {
            mimeType.contains("pdf") -> "pdf"
            mimeType.contains("jpeg") || mimeType.contains("jpg") -> "jpg"
            mimeType.contains("png") -> "png"
            mimeType.contains("heic") -> "heic"
            mimeType.contains("gif") -> "gif"
            mimeType.contains("text") -> "txt"
            mimeType.contains("word") || mimeType.contains("document") -> "docx"
            mimeType.contains("excel") || mimeType.contains("spreadsheet") -> "xlsx"
            mimeType.contains("powerpoint") || mimeType.contains("presentation") -> "pptx"
            else -> ""
        }
    }
    
    private fun getFileExtensionFromName(filename: String): String {
        val lastDot = filename.lastIndexOf('.')
        return if (lastDot > 0 && lastDot < filename.length - 1) {
            filename.substring(lastDot + 1).lowercase()
        } else {
            ""
        }
    }
    
    private suspend fun extractTextFromImage(bitmap: Bitmap): String {
        val image = InputImage.fromBitmap(bitmap, 0)
        val result = textRecognizer.process(image).await()
        return result.text
    }
    
    private suspend fun extractEntities(text: String): List<String> {
        return try {
            // Download model if needed
            entityExtractor.downloadModelIfNeeded(DownloadConditions.Builder().build()).await()
            
            // Extract entities
            val annotations = entityExtractor.annotate(text).await()
            annotations.mapNotNull { annotation ->
                annotation.entities.firstOrNull()?.text
            }
        } catch (e: Exception) {
            Log.e("DocumentIndexingService", "Entity extraction failed: ${e.message}")
            emptyList()
        }
    }
    
    private fun generateTags(entities: List<String>, text: String): List<String> {
        val tags = mutableListOf<String>()
        
        // Add entity-based tags
        entities.forEach { entity ->
            tags.add(entity.lowercase())
        }
        
        // Add document type tag
        // Add topic-based tags (simple keyword matching)
        val keywords = listOf("contract", "invoice", "receipt", "legal", "medical", "financial")
        keywords.forEach { keyword ->
            if (text.lowercase().contains(keyword)) {
                tags.add(keyword)
            }
        }
        
        return tags.distinct()
    }
}
