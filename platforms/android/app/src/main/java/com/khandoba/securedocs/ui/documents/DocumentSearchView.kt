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

data class DocumentFilter(
    val searchQuery: String = "",
    val documentType: String? = null,
    val sortBy: SortOption = SortOption.DateDescending
)

enum class SortOption {
    NameAscending,
    NameDescending,
    DateAscending,
    DateDescending,
    SizeAscending,
    SizeDescending
}

@Composable
fun DocumentSearchView(
    documents: List<DocumentEntity>,
    filter: DocumentFilter,
    onFilterChange: (DocumentFilter) -> Unit,
    onDocumentClick: (UUID) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.fillMaxSize()) {
        // Search Bar
        SearchBar(
            query = filter.searchQuery,
            onQueryChange = { newQuery ->
                onFilterChange(filter.copy(searchQuery = newQuery))
            },
            modifier = Modifier.fillMaxWidth()
        )
        
        // Filter Chips
        FilterChips(
            selectedType = filter.documentType,
            onTypeSelected = { type ->
                onFilterChange(filter.copy(documentType = type))
            },
            modifier = Modifier.fillMaxWidth()
        )
        
        // Sort Options
        SortOptions(
            selectedSort = filter.sortBy,
            onSortSelected = { sort ->
                onFilterChange(filter.copy(sortBy = sort))
            },
            modifier = Modifier.fillMaxWidth()
        )
        
        // Filtered Documents List
        val filteredDocuments = remember(filter) {
            filterDocuments(documents, filter)
        }
        
        if (filteredDocuments.isEmpty()) {
            EmptySearchResults(
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f)
            )
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    Text(
                        text = "${filteredDocuments.size} document${if (filteredDocuments.size != 1) "s" else ""} found",
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                        modifier = Modifier.padding(vertical = 8.dp)
                    )
                }
                
                items(filteredDocuments) { document ->
                    DocumentSearchResultCard(
                        document = document,
                        onClick = { onDocumentClick(document.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = modifier
            .fillMaxWidth()
            .padding(16.dp),
        label = { Text("Search documents") },
        leadingIcon = {
            Icon(Icons.Default.Search, contentDescription = null)
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Default.Clear, contentDescription = "Clear")
                }
            }
        },
        singleLine = true
    )
}

@Composable
private fun FilterChips(
    selectedType: String?,
    onTypeSelected: (String?) -> Unit,
    modifier: Modifier = Modifier
) {
    val types = listOf(
        "All" to null,
        "Images" to "image",
        "PDFs" to "pdf",
        "Videos" to "video",
        "Audio" to "audio",
        "Text" to "text"
    )
    
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        types.forEach { (label, type) ->
            FilterChip(
                selected = selectedType == type,
                onClick = { onTypeSelected(type) },
                label = { Text(label) }
            )
        }
    }
}

@Composable
private fun SortOptions(
    selectedSort: SortOption,
    onSortSelected: (SortOption) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "Sort by:",
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium
        )
        
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            val options = listOf(
                SortOption.NameAscending to "Name",
                SortOption.DateDescending to "Date",
                SortOption.SizeAscending to "Size"
            )
            
            options.forEach { (option, label) ->
                FilterChip(
                    selected = selectedSort == option,
                    onClick = { onSortSelected(option) },
                    label = { Text(label) }
                )
            }
        }
    }
}

@Composable
private fun DocumentSearchResultCard(
    document: DocumentEntity,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
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
                
                Column {
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
                    Text(
                        text = formatDate(document.createdAt),
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f),
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
            
            Icon(Icons.Default.ChevronRight, contentDescription = null)
        }
    }
}

@Composable
private fun EmptySearchResults(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.SearchOff,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "No documents found",
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "Try adjusting your search or filters",
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
    }
}

private fun filterDocuments(documents: List<DocumentEntity>, filter: DocumentFilter): List<DocumentEntity> {
    var filtered = documents
    
    // Filter by search query
    if (filter.searchQuery.isNotEmpty()) {
        val query = filter.searchQuery.lowercase()
        filtered = filtered.filter { document ->
            document.name.lowercase().contains(query) ||
            document.aiTags.any { it.lowercase().contains(query) } ||
            document.extractedText?.lowercase()?.contains(query) == true
        }
    }
    
    // Filter by document type
    if (filter.documentType != null) {
        filtered = filtered.filter { it.documentType == filter.documentType }
    }
    
    // Sort
    filtered = when (filter.sortBy) {
        SortOption.NameAscending -> filtered.sortedBy { it.name.lowercase() }
        SortOption.NameDescending -> filtered.sortedByDescending { it.name.lowercase() }
        SortOption.DateAscending -> filtered.sortedBy { it.createdAt }
        SortOption.DateDescending -> filtered.sortedByDescending { it.createdAt }
        SortOption.SizeAscending -> filtered.sortedBy { it.fileSize }
        SortOption.SizeDescending -> filtered.sortedByDescending { it.fileSize }
    }
    
    return filtered
}

private fun formatFileSize(bytes: Long): String {
    return when {
        bytes < 1024 -> "$bytes B"
        bytes < 1024 * 1024 -> "${bytes / 1024} KB"
        bytes < 1024 * 1024 * 1024 -> "${bytes / (1024 * 1024)} MB"
        else -> "${bytes / (1024 * 1024 * 1024)} GB"
    }
}

private fun formatDate(date: java.util.Date): String {
    val now = java.util.Date()
    val diff = now.time - date.time
    val days = diff / (1000 * 60 * 60 * 24)
    
    return when {
        days == 0L -> "Today"
        days == 1L -> "Yesterday"
        days < 7 -> "$days days ago"
        days < 30 -> "${days / 7} weeks ago"
        days < 365 -> "${days / 30} months ago"
        else -> "${days / 365} years ago"
    }
}
