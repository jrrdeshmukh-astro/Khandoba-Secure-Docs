package com.khandoba.securedocs.ui.sharing

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
import com.khandoba.securedocs.data.entity.NomineeEntity
import com.khandoba.securedocs.viewmodel.NomineeViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AcceptNomineeInvitationView(
    inviteToken: String,
    nomineeViewModel: NomineeViewModel,
    onDismiss: () -> Unit,
    onAcceptSuccess: () -> Unit = {}
) {
    var isLoading by remember { mutableStateOf(true) }
    var nominee: NomineeEntity? by remember { mutableStateOf(null) }
    var isAccepting by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showError by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    
    // Load invitation by token
    LaunchedEffect(inviteToken) {
        // TODO: Load nominee by inviteToken from repository
        // For now, we'll accept directly with the token
        isLoading = false
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Vault Invitation") },
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
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            if (isLoading) {
                CircularProgressIndicator()
                Text("Loading invitation...")
            } else if (nominee == null) {
                // Invitation Details Card
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.PersonAdd,
                            contentDescription = null,
                            modifier = Modifier.size(64.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                        
                        Text(
                            text = "Vault Invitation",
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold
                        )
                        
                        Text(
                            text = "You've been invited to access a vault",
                            fontSize = 16.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                        
                        Divider(modifier = Modifier.padding(vertical = 8.dp))
                        
                        // Info about how it works
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                            )
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Info,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.primary
                                    )
                                    Text(
                                        text = "How It Works",
                                        fontSize = 14.sp,
                                        fontWeight = FontWeight.Semibold
                                    )
                                }
                                Text(
                                    text = "When the vault owner unlocks the vault, you'll automatically have access to view and manage documents. The vault will be shared in real-time - no documents are copied.",
                                    fontSize = 12.sp,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
                                )
                            }
                        }
                    }
                }
                
                // Accept/Decline Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Decline")
                    }
                    
                    Button(
                        onClick = {
                            isAccepting = true
                            nomineeViewModel.acceptNomineeInvitation(inviteToken) { result ->
                                isAccepting = false
                                result.onSuccess {
                                    showSuccess = true
                                    onAcceptSuccess()
                                }.onFailure {
                                    errorMessage = it.message ?: "Failed to accept invitation"
                                    showError = true
                                }
                            }
                        },
                        modifier = Modifier.weight(1f),
                        enabled = !isAccepting
                    ) {
                        if (isAccepting) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(20.dp),
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        } else {
                            Text("Accept")
                        }
                    }
                }
            } else {
                // Show nominee details if available
                // (This would show if we loaded the nominee entity)
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
            title = { Text("Invitation Accepted") },
            text = { Text("You now have access to the vault. The owner will be notified.") },
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
