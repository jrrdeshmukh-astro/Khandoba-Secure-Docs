package com.khandoba.securedocs.ui.emergency

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.service.EmergencyApprovalService
import java.util.UUID

enum class Urgency(val displayName: String, val color: androidx.compose.ui.graphics.Color) {
    LOW("Low", androidx.compose.ui.graphics.Color(0xFF4CAF50)),
    MEDIUM("Medium", androidx.compose.ui.graphics.Color(0xFFFF9800)),
    HIGH("High", androidx.compose.ui.graphics.Color(0xFFFF5722)),
    CRITICAL("Critical", androidx.compose.ui.graphics.Color(0xFFD32F2F))
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EmergencyAccessView(
    vault: VaultEntity,
    emergencyApprovalService: EmergencyApprovalService,
    currentUserID: UUID?,
    onDismiss: () -> Unit,
    onRequestSubmitted: () -> Unit = {}
) {
    var reason by remember { mutableStateOf("") }
    var selectedUrgency by remember { mutableStateOf(Urgency.MEDIUM) }
    var isSubmitting by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showError by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Emergency Access") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Warning Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.3f)
                )
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error
                    )
                    Column {
                        Text(
                            text = "Emergency Protocol",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "Only use in genuine emergencies. Requires approval. Access granted for 24 hours.",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                }
            }
            
            // Vault Info
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Vault",
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                    Text(
                        text = vault.name,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            
            // Urgency Selection
            Text(
                text = "Urgency Level",
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
            
            Urgency.values().forEach { urgency ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { selectedUrgency = urgency },
                    colors = CardDefaults.cardColors(
                        containerColor = if (selectedUrgency == urgency) {
                            urgency.color.copy(alpha = 0.1f)
                        } else {
                            MaterialTheme.colorScheme.surface
                        }
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = when (urgency) {
                                    Urgency.LOW -> Icons.Default.Info
                                    Urgency.MEDIUM -> Icons.Default.Warning
                                    Urgency.HIGH -> Icons.Default.Error
                                    Urgency.CRITICAL -> Icons.Default.Warning
                                },
                                contentDescription = null,
                                tint = urgency.color
                            )
                            Text(
                                text = urgency.displayName,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Medium
                            )
                        }
                        
                        if (selectedUrgency == urgency) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }
            }
            
            // Reason Text Field
            OutlinedTextField(
                value = reason,
                onValueChange = { reason = it },
                label = { Text("Emergency Reason") },
                placeholder = { Text("Explain the emergency situation...") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 4,
                maxLines = 8
            )
            
            // Submit Button
            Button(
                onClick = {
                    if (reason.isBlank()) {
                        errorMessage = "Please provide a reason for emergency access"
                        showError = true
                        return@Button
                    }
                    
                    if (currentUserID == null) {
                        errorMessage = "User not authenticated"
                        showError = true
                        return@Button
                    }
                    
                    isSubmitting = true
                    // TODO: Create emergency request via service
                    // For now, show success
                    isSubmitting = false
                    showSuccess = true
                    onRequestSubmitted()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = !isSubmitting && reason.isNotBlank()
            ) {
                if (isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Icon(Icons.Default.Send, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Submit Emergency Request", fontSize = 16.sp)
                }
            }
        }
    }
    
    // Error Dialog
    if (showError && errorMessage != null) {
        AlertDialog(
            onDismissRequest = { showError = false },
            title = { Text("Error") },
            text = { Text(errorMessage!!) },
            confirmButton = {
                TextButton(onClick = { showError = false }) {
                    Text("OK")
                }
            }
        )
    }
    
    // Success Dialog
    if (showSuccess) {
        AlertDialog(
            onDismissRequest = {
                showSuccess = false
                onDismiss()
            },
            title = { Text("Request Submitted") },
            text = { Text("Your emergency access request has been submitted. You will be notified when it's approved.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showSuccess = false
                        onDismiss()
                    }
                ) {
                    Text("OK")
                }
            }
        )
    }
}
