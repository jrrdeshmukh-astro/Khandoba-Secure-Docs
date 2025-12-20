package com.khandoba.securedocs.ui.emergency

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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import com.khandoba.securedocs.data.entity.EmergencyAccessRequestEntity
import com.khandoba.securedocs.service.EmergencyApprovalService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EmergencyApprovalView(
    emergencyApprovalService: EmergencyApprovalService,
    currentUserID: UUID?,
    onDismiss: () -> Unit
) {
    val pendingRequests by emergencyApprovalService.pendingRequests.collectAsState()
    val isLoading by emergencyApprovalService.isLoading.collectAsState()
    var selectedRequest by remember { mutableStateOf<EmergencyAccessRequestEntity?>(null) }
    var showApproveDialog by remember { mutableStateOf(false) }
    var showDenyDialog by remember { mutableStateOf(false) }
    var isProcessing by remember { mutableStateOf(false) }
    var showPassCodeDialog by remember { mutableStateOf(false) }
    var approvedPassCode by remember { mutableStateOf<String?>(null) }
    var approvedExpiresAt by remember { mutableStateOf<Date?>(null) }
    
    // Load requests when view appears
    LaunchedEffect(Unit) {
        emergencyApprovalService.loadPendingRequests()
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Emergency Approvals") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(
                        onClick = {
                            emergencyApprovalService.loadPendingRequests()
                        }
                    ) {
                        Icon(Icons.Default.Refresh, contentDescription = "Refresh")
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
                isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                pendingRequests.isEmpty() -> {
                    EmptyEmergencyRequestsView(
                        modifier = Modifier.fillMaxSize()
                    )
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(pendingRequests) { request ->
                            EmergencyRequestCard(
                                request = request,
                                onApprove = {
                                    selectedRequest = request
                                    showApproveDialog = true
                                },
                                onDeny = {
                                    selectedRequest = request
                                    showDenyDialog = true
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Approve Confirmation Dialog
    if (showApproveDialog && selectedRequest != null && currentUserID != null) {
        AlertDialog(
            onDismissRequest = { showApproveDialog = false },
            title = { Text("Approve Emergency Access?") },
            text = {
                Text("This will grant 24-hour access to the vault. The requester will receive an identification pass code.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        isProcessing = true
                        emergencyApprovalService.approveEmergencyRequest(
                            request = selectedRequest!!,
                            approverID = currentUserID!!
                        ) { result ->
                            isProcessing = false
                            result.onSuccess { updatedRequest ->
                                showApproveDialog = false
                                approvedPassCode = updatedRequest.passCode
                                approvedExpiresAt = updatedRequest.expiresAt
                                showPassCodeDialog = true
                                emergencyApprovalService.loadPendingRequests()
                            }.onFailure {
                                showApproveDialog = false
                                // Handle error
                            }
                        }
                    },
                    enabled = !isProcessing
                ) {
                    if (isProcessing) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp))
                    } else {
                        Text("Approve")
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { showApproveDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Deny Confirmation Dialog
    if (showDenyDialog && selectedRequest != null && currentUserID != null) {
        AlertDialog(
            onDismissRequest = { showDenyDialog = false },
            title = { Text("Deny Emergency Access?") },
            text = {
                Text("This will deny the emergency access request. The requester will be notified.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        isProcessing = true
                        emergencyApprovalService.denyEmergencyRequest(
                            request = selectedRequest!!,
                            approverID = currentUserID!!
                        ) { result ->
                            isProcessing = false
                            result.onSuccess {
                                showDenyDialog = false
                                emergencyApprovalService.loadPendingRequests()
                            }.onFailure {
                                showDenyDialog = false
                                // Handle error
                            }
                        }
                    },
                    enabled = !isProcessing,
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    if (isProcessing) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp))
                    } else {
                        Text("Deny")
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { showDenyDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Pass Code Display Dialog
    if (showPassCodeDialog && approvedPassCode != null) {
        EmergencyPassCodeDisplayDialog(
            passCode = approvedPassCode!!,
            expiresAt = approvedExpiresAt ?: Date(System.currentTimeMillis() + 24 * 60 * 60 * 1000),
            onDismiss = {
                showPassCodeDialog = false
                approvedPassCode = null
                approvedExpiresAt = null
            }
        )
    }
}

@Composable
private fun EmergencyRequestCard(
    request: EmergencyAccessRequestEntity,
    onApprove: () -> Unit,
    onDeny: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Emergency Access Request",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Requested ${formatDate(request.requestedAt)}",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
                
                // Urgency Badge
                UrgencyBadge(urgency = request.urgency)
            }
            
            Divider()
            
            // Reason
            Column {
                Text(
                    text = "Reason",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                Text(
                    text = request.reason.ifEmpty { "No reason provided" },
                    fontSize = 14.sp,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
            
            Divider()
            
            // Actions
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = onDeny,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Deny")
                }
                
                Button(
                    onClick = onApprove,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Approve")
                }
            }
        }
    }
}

@Composable
private fun UrgencyBadge(urgency: String) {
    val (color, icon) = when (urgency.lowercase()) {
        "critical" -> Pair(Color(0xFFD32F2F), Icons.Default.Warning)
        "high" -> Pair(Color(0xFFFF5722), Icons.Default.Error)
        "medium" -> Pair(Color(0xFFFF9800), Icons.Default.Warning)
        "low" -> Pair(Color(0xFF4CAF50), Icons.Default.Info)
        else -> Pair(Color(0xFF9E9E9E), Icons.Default.Info)
    }
    
    Surface(
        color = color.copy(alpha = 0.2f),
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(14.dp),
                tint = color
            )
            Text(
                text = urgency.replaceFirstChar { it.uppercaseChar() },
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                color = color
            )
        }
    }
}

@Composable
private fun EmptyEmergencyRequestsView(
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "No Pending Requests",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "All emergency access requests have been processed.",
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
    }
}

@Composable
private fun EmergencyPassCodeDisplayDialog(
    passCode: String,
    expiresAt: Date,
    onDismiss: () -> Unit
) {
    var copied by remember { mutableStateOf(false) }
    val clipboardManager = LocalClipboardManager.current
    val timeRemaining = max(0, (expiresAt.time - System.currentTimeMillis()) / (1000 * 60)).toInt()
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Emergency Access Approved") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = "Share this pass code with the requester securely.",
                    fontSize = 14.sp
                )
                
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Pass Code",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                        Text(
                            text = passCode,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                        )
                        
                        Button(
                            onClick = {
                                clipboardManager.setText(AnnotatedString(passCode))
                                copied = true
                                CoroutineScope(Dispatchers.Main).launch {
                                    delay(2000)
                                    copied = false
                                }
                            },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                imageVector = if (copied) Icons.Default.CheckCircle else Icons.Default.ContentCopy,
                                contentDescription = null
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(if (copied) "Copied!" else "Copy Pass Code")
                        }
                    }
                }
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.warning
                    )
                    Text(
                        text = "Expires in $timeRemaining minutes",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close")
            }
        }
    )
}

private fun formatDate(date: Date): String {
    val format = SimpleDateFormat("MMM d, yyyy 'at' h:mm a", Locale.getDefault())
    return format.format(date)
}
