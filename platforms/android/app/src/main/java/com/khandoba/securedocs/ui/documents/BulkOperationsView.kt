package com.khandoba.securedocs.ui.documents

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khandoba.securedocs.data.entity.DocumentEntity
import java.util.UUID

@Composable
fun BulkOperationsView(
    documents: List<DocumentEntity>,
    selectedDocumentIds: Set<UUID>,
    onSelectionChange: (Set<UUID>) -> Unit,
    onBulkDelete: (List<UUID>) -> Unit,
    onBulkArchive: (List<UUID>) -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    val selectedDocuments = remember(selectedDocumentIds, documents) {
        documents.filter { it.id in selectedDocumentIds }
    }
    
    Column(modifier = modifier.fillMaxSize()) {
        // Header
        TopAppBar(
            title = { 
                Text(
                    text = if (selectedDocumentIds.isEmpty()) {
                        "Select Documents"
                    } else {
                        "${selectedDocumentIds.size} selected"
                    }
                )
            },
            navigationIcon = {
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, contentDescription = "Close")
                }
            },
            actions = {
                if (selectedDocumentIds.isNotEmpty()) {
                    TextButton(onClick = { onSelectionChange(emptySet()) }) {
                        Text("Clear")
                    }
                }
            }
        )
        
        // Action Buttons (shown when items are selected)
        if (selectedDocumentIds.isNotEmpty()) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = {
                            onBulkArchive(selectedDocumentIds.toList())
                            onDismiss()
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(Icons.Default.Archive, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                        Text("Archive")
                    }
                    
                    Button(
                        onClick = {
                            onBulkDelete(selectedDocumentIds.toList())
                            onDismiss()
                        },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Icon(Icons.Default.Delete, contentDescription = null)
                        Spacer(Modifier.width(8.dp))
                        Text("Delete")
                    }
                }
            }
        }
        
        // Documents List with Checkboxes
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .weight(1f),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            item {
                // Select All / Deselect All
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable {
                            if (selectedDocumentIds.size == documents.size) {
                                onSelectionChange(emptySet())
                            } else {
                                onSelectionChange(documents.map { it.id }.toSet())
                            }
                        }
                        .padding(vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = if (selectedDocumentIds.size == documents.size) {
                            "Deselect All"
                        } else {
                            "Select All"
                        },
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium
                    )
                    
                    Checkbox(
                        checked = selectedDocumentIds.size == documents.size && documents.isNotEmpty(),
                        onCheckedChange = {
                            if (it) {
                                onSelectionChange(documents.map { doc -> doc.id }.toSet())
                            } else {
                                onSelectionChange(emptySet())
                            }
                        }
                    )
                }
                
                Divider()
            }
            
            items(documents) { document ->
                BulkOperationDocumentCard(
                    document = document,
                    isSelected = document.id in selectedDocumentIds,
                    onToggleSelection = {
                        val newSelection = if (document.id in selectedDocumentIds) {
                            selectedDocumentIds - document.id
                        } else {
                            selectedDocumentIds + document.id
                        }
                        onSelectionChange(newSelection)
                    }
                )
            }
        }
    }
}

@Composable
private fun BulkOperationDocumentCard(
    document: DocumentEntity,
    isSelected: Boolean,
    onToggleSelection: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggleSelection)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                modifier = Modifier.weight(1f),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Checkbox(
                    checked = isSelected,
                    onCheckedChange = { onToggleSelection() }
                )
                
                Icon(
                    imageVector = when (document.documentType) {
                        "image" -> Icons.Default.Image
                        "pdf" -> Icons.Default.Description
                        "video" -> Icons.Default.VideoLibrary
                        "audio" -> Icons.Default.AudioFile
                        "text" -> Icons.Default.TextFields
                        else -> Icons.Default.InsertDriveFile
                    },
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = document.name,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "${document.documentType} • ${formatFileSize(document.fileSize)}",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }
        }
    }
}

private fun formatFileSize(bytes: Long): String {
    return when {
        bytes < 1024 -> "$bytes B"
        bytes < 1024 * 1024 -> "${bytes / 1024} KB"
        bytes < 1024 * 1024 * 1024 -> "${bytes / (1024 * 1024)} MB"
        else -> "${bytes / (1024 * 1024 * 1024)} GB"
    }
}
