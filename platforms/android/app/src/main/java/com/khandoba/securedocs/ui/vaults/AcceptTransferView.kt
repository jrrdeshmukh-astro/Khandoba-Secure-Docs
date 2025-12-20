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
import com.khandoba.securedocs.service.VaultTransferService

@Composable
fun AcceptTransferView(
    transferToken: String?,
    vaultTransferService: VaultTransferService,
    onTransferAccepted: () -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    var tokenInput by remember { mutableStateOf(transferToken ?: "") }
    var isAccepting by remember { mutableStateOf(false) }
    var showSuccessDialog by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Accept Ownership Transfer") },
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
                        text = "Enter the transfer token provided by the vault owner to accept ownership.",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
            
            // Transfer Token Input
            OutlinedTextField(
                value = tokenInput,
                onValueChange = { tokenInput = it },
                label = { Text("Transfer Token *") },
                leadingIcon = {
                    Icon(Icons.Default.Key, contentDescription = null)
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                placeholder = { Text("Enter transfer token") }
            )
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Accept Button
            Button(
                onClick = {
                    if (tokenInput.isBlank()) {
                        // Show error
                        return@Button
                    }
                    
                    isAccepting = true
                    kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main).launch {
                        val result = vaultTransferService.acceptOwnershipTransfer(tokenInput.trim())
                        
                        isAccepting = false
                        result.onSuccess {
                            showSuccessDialog = true
                        }.onFailure {
                            // Show error dialog
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = !isAccepting && tokenInput.isNotBlank()
            ) {
                if (isAccepting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Icon(Icons.Default.CheckCircle, contentDescription = null)
                    Spacer(Modifier.width(8.dp))
                    Text("Accept Ownership", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
    
    // Success Dialog
    if (showSuccessDialog) {
        AlertDialog(
            onDismissRequest = {
                showSuccessDialog = false
                onTransferAccepted()
            },
            title = { Text("Transfer Accepted") },
            text = { Text("You are now the owner of this vault.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showSuccessDialog = false
                        onTransferAccepted()
                    }
                ) {
                    Text("OK")
                }
            }
        )
    }
}
