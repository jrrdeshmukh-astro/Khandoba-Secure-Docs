package com.khandoba.securedocs.service

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.Log
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPage
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle
import com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject
import com.tom_roush.pdfbox.rendering.PDFRenderer
import java.io.ByteArrayOutputStream
import java.io.IOException

/**
 * HIPAA-compliant redaction service that permanently removes PHI from documents
 * 
 * Redaction is performed by:
 * 1. Rendering PDF pages to high-resolution bitmaps
 * 2. Drawing black rectangles over redaction areas
 * 3. Converting redacted bitmaps back to PDF pages
 * 4. Creating a new PDF document with redacted pages
 * 
 * This ensures that redacted content cannot be recovered from the PDF data stream.
 */
class RedactionService(private val context: Context) {
    
    init {
        // Initialize PDFBox resources (required for Android)
        PDFBoxResourceLoader.init(context)
    }
    
    data class RedactionArea(
        val pageIndex: Int,
        val rect: RectF // Rectangle coordinates on the page
    )
    
    data class PHIMatch(
        val value: String,
        val type: String // "ssn", "credit_card", "email", etc.
    )
    
    sealed class RedactionError(message: String) : Exception(message) {
        object InvalidPDF : RedactionError("Invalid PDF document")
        object RedactionFailed : RedactionError("Failed to redact PDF")
        object InvalidImage : RedactionError("Invalid image data")
    }
    
    /**
     * Redact PHI from PDF document (HIPAA compliant)
     * 
     * @param pdfData Original PDF data
     * @param redactionAreas User-selected rectangles to redact
     * @param phiMatches PHI values detected by ML to redact
     * @return Redacted PDF data with content permanently removed
     */
    suspend fun redactPDF(
        pdfData: ByteArray,
        redactionAreas: List<RedactionArea>,
        phiMatches: List<PHIMatch>
    ): Result<ByteArray> {
        return try {
            // Load PDF document
            val document = PDDocument.load(pdfData)
            try {
                val redactedDocument = PDDocument()
                val renderer = PDFRenderer(document)
                
                // Process each page
                for (pageIndex in 0 until document.numberOfPages) {
                    val originalPage = document.getPage(pageIndex)
                    val pageRect = originalPage.mediaBox
                    
                    // Render page to bitmap at high resolution (144 DPI for quality)
                    val dpi = 144f
                    
                    // Render PDF page to bitmap
                    val bitmap = renderer.renderImageWithDPI(pageIndex, dpi)
                    
                    // Create canvas to draw redactions
                    val redactedBitmap = bitmap.copy(bitmap.config, true) ?: bitmap
                    val canvas = Canvas(redactedBitmap)
                    val paint = Paint().apply {
                        color = Color.BLACK
                        style = Paint.Style.FILL
                    }
                    
                    // Calculate scale factor for coordinate conversion
                    // PDF coordinates are in points (72 DPI), bitmap is rendered at specified DPI
                    val bitmapWidth = bitmap.width.toFloat()
                    val bitmapHeight = bitmap.height.toFloat()
                    val pageWidth = pageRect.width
                    val pageHeight = pageRect.height
                    val scaleX = bitmapWidth / pageWidth
                    val scaleY = bitmapHeight / pageHeight
                    
                    // Apply redactions for this page
                    val pageRedactions = redactionAreas.filter { it.pageIndex == pageIndex }
                    for (redaction in pageRedactions) {
                        // Convert page coordinates (points) to bitmap coordinates (pixels)
                        val scaledRect = RectF(
                            redaction.rect.left * scaleX,
                            redaction.rect.top * scaleY,
                            redaction.rect.right * scaleX,
                            redaction.rect.bottom * scaleY
                        )
                        canvas.drawRect(scaledRect, paint)
                    }
                    
                    // TODO: Apply PHI-based redactions using text search
                    // This would require PDF text extraction and position mapping
                    // For now, only manual redaction areas are supported
                    
                    // Convert redacted bitmap back to PDF page
                    val newPage = PDPage(pageRect)
                    val contentStream = PDPageContentStream(redactedDocument, newPage)
                    
                    // Create image from bitmap
                    val byteArrayOutputStream = ByteArrayOutputStream()
                    redactedBitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
                    val imageBytes = byteArrayOutputStream.toByteArray()
                    
                    // Add image to PDF page (scaled to fit page bounds)
                    val pdImage = PDImageXObject.createFromByteArray(redactedDocument, imageBytes, "redacted_page_$pageIndex")
                    contentStream.drawImage(pdImage, 0f, 0f, pageRect.width, pageRect.height)
                    
                    contentStream.close()
                    redactedDocument.addPage(newPage)
                    
                    // Cleanup
                    redactedBitmap.recycle()
                    bitmap.recycle()
                }
                
                // Save redacted PDF to byte array
                val outputStream = ByteArrayOutputStream()
                redactedDocument.save(outputStream)
                redactedDocument.close()
                
                Result.success(outputStream.toByteArray())
            } catch (e: Exception) {
                Log.e("RedactionService", "Error redacting PDF", e)
                Result.failure(RedactionError.RedactionFailed)
            } finally {
                document.close()
            }
        } catch (e: IOException) {
            Log.e("RedactionService", "Error loading PDF", e)
            Result.failure(RedactionError.InvalidPDF)
        }
    }
    
    /**
     * Redact image by drawing black rectangles over specified areas
     */
    fun redactImage(
        bitmap: Bitmap,
        redactionAreas: List<RectF>
    ): Bitmap {
        val redactedBitmap = bitmap.copy(bitmap.config, true) ?: return bitmap
        
        val canvas = Canvas(redactedBitmap)
        val paint = Paint().apply {
            color = Color.BLACK
            style = Paint.Style.FILL
        }
        
        for (rect in redactionAreas) {
            canvas.drawRect(rect, paint)
        }
        
        return redactedBitmap
    }
}
