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
            
            // Extract text from image if available
            if (imageBitmap != null && document.documentType == "image") {
                val extractedText = extractTextFromImage(imageBitmap)
                updatedDocument = updatedDocument.copy(extractedText = extractedText)
            }
            
            // Extract entities from text
            val extractedText = updatedDocument.extractedText
            if (extractedText != null) {
                val entities = extractEntities(extractedText)
                val tags = generateTags(entities, extractedText)
                updatedDocument = updatedDocument.copy(aiTags = tags)
            }
            
            updatedDocument
        } catch (e: Exception) {
            Log.e("DocumentIndexingService", "Indexing failed: ${e.message}")
            document
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
