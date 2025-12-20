package com.khandoba.securedocs.ui.vaults

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
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.service.VaultTransferService
import java.util.UUID

@Composable
fun TransferOwnershipView(
    vault: VaultEntity,
    vaultTransferService: VaultTransferService,
    onTransferRequested: (String) -> Unit, // transfer token
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    var newOwnerName by remember { mutableStateOf("") }
    var newOwnerEmail by remember { mutableStateOf("") }
    var newOwnerPhone by remember { mutableStateOf("") }
    var reason by remember { mutableStateOf("") }
    var isSubmitting by remember { mutableStateOf(false) }
    var showSuccessDialog by remember { mutableStateOf(false) }
    var transferToken by remember { mutableStateOf<String?>(null) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Transfer Ownership") },
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
            // Warning Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.3f)
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        Icons.Default.Warning,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error
                    )
                    Column {
                        Text(
                            text = "Important",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Transferring ownership will remove your access to this vault. The new owner will have full control.",
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
                    if (!vault.vaultDescription.isNullOrEmpty()) {
                        Text(
                            text = vault.vaultDescription!!,
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                }
            }
            
            // New Owner Name
            OutlinedTextField(
                value = newOwnerName,
                onValueChange = { newOwnerName = it },
                label = { Text("New Owner Name *") },
                leadingIcon = {
                    Icon(Icons.Default.Person, contentDescription = null)
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // New Owner Email
            OutlinedTextField(
                value = newOwnerEmail,
                onValueChange = { newOwnerEmail = it },
                label = { Text("Email (Optional)") },
                leadingIcon = {
                    Icon(Icons.Default.Email, contentDescription = null)
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // New Owner Phone
            OutlinedTextField(
                value = newOwnerPhone,
                onValueChange = { newOwnerPhone = it },
                label = { Text("Phone (Optional)") },
                leadingIcon = {
                    Icon(Icons.Default.Phone, contentDescription = null)
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // Reason
            OutlinedTextField(
                value = reason,
                onValueChange = { reason = it },
                label = { Text("Reason for Transfer (Optional)") },
                leadingIcon = {
                    Icon(Icons.Default.Info, contentDescription = null)
                },
                modifier = Modifier.fillMaxWidth(),
                minLines = 3,
                maxLines = 5
            )
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Transfer Button
            Button(
                onClick = {
                    if (newOwnerName.isBlank()) {
                        // Show error
                        return@Button
                    }
                    
                    isSubmitting = true
                    // Request transfer
                    kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main).launch {
                        val result = vaultTransferService.requestOwnershipTransfer(
                            vault = vault,
                            newOwnerEmail = newOwnerEmail.ifBlank { null },
                            newOwnerPhone = newOwnerPhone.ifBlank { null },
                            newOwnerName = newOwnerName,
                            reason = reason.ifBlank { null }
                        )
                        
                        isSubmitting = false
                        result.onSuccess { request ->
                            transferToken = request.transferToken
                            showSuccessDialog = true
                        }.onFailure {
                            // Show error dialog
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = !isSubmitting && newOwnerName.isNotBlank(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                )
            ) {
                if (isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onError
                    )
                } else {
                    Icon(Icons.Default.ArrowForward, contentDescription = null)
                    Spacer(Modifier.width(8.dp))
                    Text("Transfer Ownership", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
    
    // Success Dialog
    if (showSuccessDialog && transferToken != null) {
        AlertDialog(
            onDismissRequest = {
                showSuccessDialog = false
                onTransferRequested(transferToken!!)
            },
            title = { Text("Transfer Request Created") },
            text = {
                Column {
                    Text("Ownership transfer request has been created. Share the transfer token with the new owner:")
                    Spacer(Modifier.height(8.dp))
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.primaryContainer
                        )
                    ) {
                        Text(
                            text = transferToken!!,
                            modifier = Modifier.padding(16.dp),
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                        )
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showSuccessDialog = false
                        onTransferRequested(transferToken!!)
                    }
                ) {
                    Text("OK")
                }
            }
        )
    }
}
