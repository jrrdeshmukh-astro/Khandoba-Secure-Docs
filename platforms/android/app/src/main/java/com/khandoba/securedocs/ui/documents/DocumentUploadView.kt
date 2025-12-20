package com.khandoba.securedocs.ui.documents

import android.content.Context
import android.net.Uri
import android.os.Environment
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.viewmodel.DocumentViewModel
import java.io.File
import java.util.UUID

@Composable
fun DocumentUploadView(
    vault: VaultEntity,
    documentViewModel: DocumentViewModel,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    var selectedUri by remember { mutableStateOf<Uri?>(null) }
    var documentName by remember { mutableStateOf("") }
    var cameraImageUri by remember { mutableStateOf<Uri?>(null) }
    val uploadProgress by documentViewModel.uploadProgress.collectAsState()
    val isLoading by documentViewModel.isLoading.collectAsState()
    
    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            selectedUri = it
            documentName = getFileNameFromUri(context, it) ?: "Document"
        }
    }
    
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture()
    ) { success ->
        if (success && cameraImageUri != null) {
            selectedUri = cameraImageUri
            documentName = getFileNameFromUri(context, cameraImageUri!!) ?: "Photo_${System.currentTimeMillis()}.jpg"
        }
    }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Upload Document") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Upload options
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Camera
                    Button(
                        onClick = {
                            // Create a temporary file for the camera image
                            val photoFile = File(context.getExternalFilesDir(Environment.DIRECTORY_PICTURES), "temp_photo_${System.currentTimeMillis()}.jpg")
                            val photoUri = FileProvider.getUriForFile(
                                context,
                                "${context.packageName}.fileprovider",
                                photoFile
                            )
                            cameraImageUri = photoUri
                            cameraLauncher.launch(photoUri)
                        },
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(Icons.Default.Camera, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Camera")
                    }
                    
                    // File picker
                    Button(
                        onClick = { filePickerLauncher.launch("*/*") },
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(Icons.Default.Folder, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Files")
                    }
                }
                
                // Selected file
                if (selectedUri != null) {
                    OutlinedTextField(
                        value = documentName,
                        onValueChange = { documentName = it },
                        label = { Text("Document Name") },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                
                // Upload progress
                if (isLoading) {
                    LinearProgressIndicator(
                        progress = uploadProgress.toFloat(),
                        modifier = Modifier.fillMaxWidth()
                    )
                    Text(
                        text = "Uploading... ${(uploadProgress * 100).toInt()}%",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    selectedUri?.let { uri ->
                        // Note: uploadedByUserID should be passed from parent, using vault owner for now
                        documentViewModel.uploadDocument(
                            vaultId = vault.id,
                            uri = uri,
                            name = documentName.ifEmpty { "Document" },
                            uploadedByUserID = vault.ownerId // TODO: Get from auth
                        ) { result ->
                            result.onSuccess {
                                onDismiss()
                            }.onFailure {
                                // Handle error
                            }
                        }
                    }
                },
                enabled = selectedUri != null && !isLoading
            ) {
                Text("Upload")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

private fun getFileNameFromUri(context: Context, uri: Uri): String? {
    return try {
        when (uri.scheme) {
            "content" -> {
                // Use ContentResolver to get filename
                context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (nameIndex >= 0 && cursor.moveToFirst()) {
                        cursor.getString(nameIndex)
                    } else {
                        null
                    }
                }
            }
            "file" -> {
                // File URI - extract from path
                uri.path?.let { path ->
                    File(path).name
                }
            }
            else -> {
                // Try to extract from last path segment
                uri.lastPathSegment
            }
        }
    } catch (e: Exception) {
        android.util.Log.e("DocumentUploadView", "Error extracting filename: ${e.message}")
        null
    }
}
