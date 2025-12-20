package com.khandoba.securedocs.ui.vaults

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.ui.window.Dialog
import com.khandoba.securedocs.data.entity.DocumentEntity
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.viewmodel.AuthenticationViewModel
import com.khandoba.securedocs.viewmodel.DocumentViewModel
import com.khandoba.securedocs.viewmodel.NomineeViewModel
import com.khandoba.securedocs.viewmodel.VaultViewModel
import com.khandoba.securedocs.ui.sharing.NomineeManagementView
import com.khandoba.securedocs.ui.sharing.NomineeInvitationView
import com.khandoba.securedocs.ui.emergency.EmergencyAccessView
import com.khandoba.securedocs.ui.emergency.EmergencyAccessUnlockView
import com.khandoba.securedocs.ui.emergency.EmergencyApprovalView
import com.khandoba.securedocs.service.EmergencyApprovalService
import com.khandoba.securedocs.ui.documents.DocumentSearchView
import com.khandoba.securedocs.ui.documents.DocumentFilter
import com.khandoba.securedocs.ui.documents.BulkOperationsView
import com.khandoba.securedocs.ui.documents.DocumentVersionHistoryView
import com.khandoba.securedocs.ui.documents.URLDownloadView
import java.util.UUID

@Composable
fun VaultDetailView(
    vaultId: UUID,
    vaultViewModel: VaultViewModel,
    documentViewModel: DocumentViewModel,
    nomineeViewModel: NomineeViewModel? = null,
    authViewModel: AuthenticationViewModel? = null,
    vaultTransferService: VaultTransferService? = null,
    onBack: () -> Unit,
    onNavigateToDocument: (UUID) -> Unit = {}
) {
    val vaults by vaultViewModel.vaults.collectAsState()
    val vault = vaults.firstOrNull { it.id == vaultId }
    val documents by documentViewModel.documents.collectAsState()
    val isLoading by documentViewModel.isLoading.collectAsState()
    
    var showUploadDialog by remember { mutableStateOf(false) }
    var showUnlockDialog by remember { mutableStateOf(false) }
    var showNomineeManagement by remember { mutableStateOf(false) }
    var showNomineeInvitation by remember { mutableStateOf(false) }
    var showEmergencyAccess by remember { mutableStateOf(false) }
    var showEmergencyUnlock by remember { mutableStateOf(false) }
    var showEmergencyApproval by remember { mutableStateOf(false) }
    var showTransferOwnership by remember { mutableStateOf(false) }
    var showAcceptTransfer by remember { mutableStateOf(false) }
    var showDocumentSearch by remember { mutableStateOf(false) }
    var showBulkOperations by remember { mutableStateOf(false) }
    var showURLDownload by remember { mutableStateOf(false) }
    var selectedDocumentForVersions by remember { mutableStateOf<DocumentEntity?>(null) }
    var selectedDocumentIds by remember { mutableStateOf<Set<UUID>>(emptySet()) }
    var documentFilter by remember { mutableStateOf(DocumentFilter()) }
    
    val activeSessions by vaultViewModel.activeSessions.collectAsState()
    val hasActiveSession = activeSessions.containsKey(vaultId)
    
    // Get current user ID from auth
    val currentUser by authViewModel?.currentUser?.collectAsState() ?: remember { mutableStateOf(null) }
    val currentUserId = currentUser?.id
    
    // Load documents when vault is unlocked
    LaunchedEffect(vaultId, hasActiveSession) {
        if (hasActiveSession && vault != null) {
            documentViewModel.loadDocuments(vaultId)
        }
    }
    
    // Document picker
    val documentPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: android.net.Uri? ->
        uri?.let {
            val fileName = it.lastPathSegment ?: "document"
            documentViewModel.uploadDocument(
                vaultId = vaultId,
                uri = it,
                name = fileName,
                uploadedByUserID = currentUserId ?: UUID.randomUUID()
            ) { result ->
                result.onSuccess {
                    documentViewModel.loadDocuments(vaultId)
                }.onFailure {
                    // Handle error
                }
            }
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(vault?.name ?: "Vault") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    if (hasActiveSession) {
                        IconButton(onClick = { showDocumentSearch = true }) {
                            Icon(Icons.Default.Search, contentDescription = "Search")
                        }
                        IconButton(onClick = { showBulkOperations = true }) {
                            Icon(Icons.Default.CheckCircle, contentDescription = "Bulk Operations")
                        }
                        IconButton(onClick = { showURLDownload = true }) {
                            Icon(Icons.Default.Download, contentDescription = "Download from URL")
                        }
                        IconButton(onClick = { showUploadDialog = true }) {
                            Icon(Icons.Default.Add, contentDescription = "Upload")
                        }
                        IconButton(onClick = { showNomineeManagement = true }) {
                            Icon(Icons.Default.People, contentDescription = "Nominees")
                        }
                        if (vault?.ownerId == currentUserId && vaultTransferService != null) {
                            IconButton(onClick = { showTransferOwnership = true }) {
                                Icon(Icons.Default.SwapHoriz, contentDescription = "Transfer Ownership")
                            }
                        }
                    }
                }
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when {
                vault == null -> {
                    Text(
                        "Vault not found",
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                !hasActiveSession -> {
                    UnlockVaultView(
                        vault = vault,
                        vaultViewModel = vaultViewModel,
                        onUnlocked = {
                            showUnlockDialog = false
                            documentViewModel.loadDocuments(vaultId)
                        }
                    )
                }
                isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                documents.isEmpty() -> {
                    EmptyDocumentsView(
                        onUploadClick = { showUploadDialog = true }
                    )
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        item {
                            VaultInfoCard(vault = vault)
                        }
                        
                        item {
                            Text(
                                "Documents (${documents.size})",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(vertical = 8.dp)
                            )
                        }
                        
                        items(documents) { document ->
                            DocumentCard(
                                document = document,
                                onClick = {
                                    onNavigateToDocument(document.id)
                                },
                                onDelete = {
                                    documentViewModel.deleteDocument(document) { result ->
                                        result.onSuccess {
                                            documentViewModel.loadDocuments(vaultId)
                                        }
                                    }
                                },
                                onShowVersions = {
                                    selectedDocumentForVersions = document
                                }
                            )
                        }
                    }
                }
            }
            
            // Upload dialog
            if (showUploadDialog) {
                AlertDialog(
                    onDismissRequest = { showUploadDialog = false },
                    title = { Text("Upload Document") },
                    text = {
                        Column {
                            Text("Select a file to upload to this vault")
                        }
                    },
                    confirmButton = {
                        TextButton(
                            onClick = {
                                showUploadDialog = false
                                documentPickerLauncher.launch("*/*")
                            }
                        ) {
                            Text("Choose File")
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { showUploadDialog = false }) {
                            Text("Cancel")
                        }
                    }
                )
            }
            
            // Nominee Management Dialog (using AlertDialog for simplicity)
            if (showNomineeManagement && nomineeViewModel != null && vault != null) {
                androidx.compose.ui.window.Dialog(onDismissRequest = { showNomineeManagement = false }) {
                    Surface(
                        modifier = Modifier.fillMaxHeight(0.9f),
                        shape = MaterialTheme.shapes.large
                    ) {
                        NomineeManagementView(
                            vault = vault,
                            nomineeViewModel = nomineeViewModel,
                            onDismiss = { showNomineeManagement = false },
                            onInviteNominee = {
                                showNomineeManagement = false
                                showNomineeInvitation = true
                            }
                        )
                    }
                }
            }
            
            // Nominee Invitation Dialog
            if (showNomineeInvitation && nomineeViewModel != null && vault != null) {
                androidx.compose.ui.window.Dialog(onDismissRequest = { showNomineeInvitation = false }) {
                    Surface(
                        modifier = Modifier.fillMaxHeight(0.9f),
                        shape = MaterialTheme.shapes.large
                    ) {
                        NomineeInvitationView(
                            vault = vault,
                            nomineeViewModel = nomineeViewModel,
                            vaultViewModel = vaultViewModel,
                            onDismiss = { showNomineeInvitation = false },
                            onInviteSuccess = {
                                showNomineeInvitation = false
                                showNomineeManagement = true
                            }
                        )
                    }
                }
            }
            
            // Document Search Dialog
            if (showDocumentSearch) {
                androidx.compose.ui.window.Dialog(onDismissRequest = { showDocumentSearch = false }) {
                    Surface(
                        modifier = Modifier.fillMaxSize(0.9f),
                        shape = MaterialTheme.shapes.large
                    ) {
                        DocumentSearchView(
                            documents = documents,
                            filter = documentFilter,
                            onFilterChange = { documentFilter = it },
                            onDocumentClick = { docId ->
                                showDocumentSearch = false
                                onNavigateToDocument(docId)
                            }
                        )
                    }
                }
            }
            
            // Bulk Operations Dialog
            if (showBulkOperations) {
                androidx.compose.ui.window.Dialog(onDismissRequest = { showBulkOperations = false }) {
                    Surface(
                        modifier = Modifier.fillMaxSize(0.9f),
                        shape = MaterialTheme.shapes.large
                    ) {
                        BulkOperationsView(
                            documents = documents,
                            selectedDocumentIds = selectedDocumentIds,
                            onSelectionChange = { selectedDocumentIds = it },
                            onBulkDelete = { ids ->
                                documentViewModel.bulkDeleteDocuments(ids) { result ->
                                    result.onSuccess {
                                        documentViewModel.loadDocuments(vaultId)
                                        selectedDocumentIds = emptySet()
                                    }
                                }
                            },
                            onBulkArchive = { ids ->
                                documentViewModel.bulkArchiveDocuments(ids) { result ->
                                    result.onSuccess {
                                        documentViewModel.loadDocuments(vaultId)
                                        selectedDocumentIds = emptySet()
                                    }
                                }
                            },
                            onDismiss = { showBulkOperations = false }
                        )
                    }
                }
            }
            
            // URL Download Dialog
            if (showURLDownload) {
                androidx.compose.ui.window.Dialog(onDismissRequest = { showURLDownload = false }) {
                    Surface(
                        modifier = Modifier.fillMaxWidth(0.9f),
                        shape = MaterialTheme.shapes.large
                    ) {
                        URLDownloadView(
                            vaultId = vaultId,
                            onDownload = { url, vid ->
                                // TODO: Implement URL download in DocumentService
                                showURLDownload = false
                            },
                            onDismiss = { showURLDownload = false }
                        )
                    }
                }
            }
            
            // Document Version History Dialog
            if (selectedDocumentForVersions != null) {
                androidx.compose.ui.window.Dialog(onDismissRequest = { selectedDocumentForVersions = null }) {
                    Surface(
                        modifier = Modifier.fillMaxSize(0.9f),
                        shape = MaterialTheme.shapes.large
                    ) {
                        // TODO: Load versions for document
                        DocumentVersionHistoryView(
                            document = selectedDocumentForVersions!!,
                            versions = emptyList(), // TODO: Load from service
                            onVersionClick = { version ->
                                // TODO: Download/restore version
                            },
                            onBack = { selectedDocumentForVersions = null }
                        )
                    }
                }
            }
            
            // Transfer Ownership Dialog
            if (showTransferOwnership && vaultTransferService != null && vault != null) {
                androidx.compose.ui.window.Dialog(onDismissRequest = { showTransferOwnership = false }) {
                    Surface(
                        modifier = Modifier.fillMaxSize(0.9f),
                        shape = MaterialTheme.shapes.large
                    ) {
                        TransferOwnershipView(
                            vault = vault,
                            vaultTransferService = vaultTransferService,
                            onTransferRequested = { token ->
                                showTransferOwnership = false
                                // Could show token in dialog
                            },
                            onDismiss = { showTransferOwnership = false }
                        )
                    }
                }
            }
            
            // Accept Transfer Dialog
            if (showAcceptTransfer && vaultTransferService != null) {
                androidx.compose.ui.window.Dialog(onDismissRequest = { showAcceptTransfer = false }) {
                    Surface(
                        modifier = Modifier.fillMaxSize(0.9f),
                        shape = MaterialTheme.shapes.large
                    ) {
                        AcceptTransferView(
                            transferToken = null, // Could be passed from deep link
                            vaultTransferService = vaultTransferService,
                            onTransferAccepted = {
                                showAcceptTransfer = false
                                // Reload vaults
                            },
                            onDismiss = { showAcceptTransfer = false }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun VaultInfoCard(vault: VaultEntity) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = vault.name,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold
            )
            
            if (!vault.vaultDescription.isNullOrEmpty()) {
                Text(
                    text = vault.vaultDescription!!,
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Status: ${vault.status}",
                    fontSize = 12.sp
                )
                Text(
                    text = "Type: ${vault.keyType}",
                    fontSize = 12.sp
                )
            }
        }
    }
}

@Composable
private fun DocumentCard(
    document: DocumentEntity,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    onShowVersions: (() -> Unit)? = null
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
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Document type icon
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
                }
            }
            
            if (onShowVersions != null) {
                IconButton(onClick = onShowVersions) {
                    Icon(Icons.Default.History, contentDescription = "Version History")
                }
            }
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Delete")
            }
        }
    }
}

@Composable
private fun EmptyDocumentsView(
    onUploadClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Description,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "No Documents",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "Upload your first document to get started",
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Button(onClick = onUploadClick) {
            Text("Upload Document")
        }
    }
}

@Composable
private fun UnlockVaultView(
    vault: VaultEntity,
    vaultViewModel: VaultViewModel,
    onUnlocked: () -> Unit
) {
    var password by remember { mutableStateOf("") }
    var isUnlocking by remember { mutableStateOf(false) }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Lock,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "Vault Locked",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = vault.name,
            fontSize = 16.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password (Optional)") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            visualTransformation = androidx.compose.ui.text.input.PasswordVisualTransformation
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Button(
            onClick = {
                isUnlocking = true
                vaultViewModel.unlockVault(
                    vaultId = vault.id,
                    password = password.ifEmpty { null }
                ) { result ->
                    isUnlocking = false
                    result.onSuccess {
                        onUnlocked()
                    }.onFailure {
                        // Handle error
                    }
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = !isUnlocking
        ) {
            if (isUnlocking) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = MaterialTheme.colorScheme.onPrimary
                )
            } else {
                Text("Unlock Vault")
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
