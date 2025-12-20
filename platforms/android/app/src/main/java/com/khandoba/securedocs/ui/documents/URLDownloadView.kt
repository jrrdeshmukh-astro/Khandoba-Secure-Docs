package com.khandoba.securedocs.ui.documents

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.UUID

@Composable
fun URLDownloadView(
    vaultId: UUID,
    onDownload: (String, UUID) -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    var urlText by remember { mutableStateOf("") }
    var fileName by remember { mutableStateOf("") }
    var isDownloading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Download from URL") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Info Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        Icons.Default.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "Enter a URL to download a file. Supported formats: Images, PDFs, Documents",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
            
            // URL Input
            OutlinedTextField(
                value = urlText,
                onValueChange = {
                    urlText = it
                    error = null
                },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("URL") },
                placeholder = { Text("https://example.com/file.pdf") },
                leadingIcon = {
                    Icon(Icons.Default.Link, contentDescription = null)
                },
                singleLine = true,
                isError = error != null
            )
            
            if (error != null) {
                Text(
                    text = error!!,
                    color = MaterialTheme.colorScheme.error,
                    fontSize = 12.sp
                )
            }
            
            // File Name Input (Optional)
            OutlinedTextField(
                value = fileName,
                onValueChange = { fileName = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("File Name (Optional)") },
                placeholder = { Text("Leave empty to use URL filename") },
                leadingIcon = {
                    Icon(Icons.Default.Description, contentDescription = null)
                },
                singleLine = true
            )
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Download Button
            Button(
                onClick = {
                    if (urlText.isBlank()) {
                        error = "Please enter a URL"
                        return@Button
                    }
                    
                    if (!isValidUrl(urlText)) {
                        error = "Please enter a valid URL"
                        return@Button
                    }
                    
                    isDownloading = true
                    error = null
                    
                    val finalFileName = fileName.ifBlank {
                        extractFileNameFromUrl(urlText) ?: "downloaded_file"
                    }
                    
                    onDownload(urlText, vaultId)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = !isDownloading && urlText.isNotBlank()
            ) {
                if (isDownloading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Icon(Icons.Default.Download, contentDescription = null)
                    Spacer(Modifier.width(8.dp))
                    Text("Download", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

private fun isValidUrl(url: String): Boolean {
    return try {
        java.net.URL(url)
        true
    } catch (e: Exception) {
        false
    }
}

private fun extractFileNameFromUrl(url: String): String? {
    return try {
        val urlObj = java.net.URL(url)
        val path = urlObj.path
        if (path.isNotEmpty()) {
            path.substringAfterLast("/").takeIf { it.isNotEmpty() }
        } else {
            null
        }
    } catch (e: Exception) {
        null
    }
}
