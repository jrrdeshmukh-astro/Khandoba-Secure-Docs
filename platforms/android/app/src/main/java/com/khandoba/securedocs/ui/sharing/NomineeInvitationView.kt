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
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.viewmodel.NomineeViewModel
import com.khandoba.securedocs.viewmodel.VaultViewModel
import java.util.UUID

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NomineeInvitationView(
    vault: VaultEntity?,
    nomineeViewModel: NomineeViewModel,
    vaultViewModel: VaultViewModel,
    onDismiss: () -> Unit,
    onInviteSuccess: () -> Unit = {}
) {
    val vaults by vaultViewModel.vaults.collectAsState()
    val selectedVault = remember { mutableStateOf(vault ?: vaults.firstOrNull()) }
    var nomineeName by remember { mutableStateOf("") }
    var nomineeEmail by remember { mutableStateOf("") }
    var nomineePhone by remember { mutableStateOf("") }
    var isInviting by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showError by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Invite Nominee") },
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
            // Vault Selection
            if (vault == null && vaults.isNotEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Select Vault",
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                        
                        DropdownMenu(
                            expanded = false,
                            onDismissRequest = {}
                        ) {
                            // Vault dropdown would go here
                        }
                        
                        Text(
                            text = selectedVault.value?.name ?: "Select a vault",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            } else if (selectedVault.value != null) {
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
                            text = selectedVault.value!!.name,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold
                        )
                        if (!selectedVault.value!!.vaultDescription.isNullOrEmpty()) {
                            Text(
                                text = selectedVault.value!!.vaultDescription!!,
                                fontSize = 14.sp,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                        }
                    }
                }
            }
            
            // Nominee Name
            OutlinedTextField(
                value = nomineeName,
                onValueChange = { nomineeName = it },
                label = { Text("Nominee Name") },
                leadingIcon = {
                    Icon(Icons.Default.Person, contentDescription = null)
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // Email (optional but recommended)
            OutlinedTextField(
                value = nomineeEmail,
                onValueChange = { nomineeEmail = it },
                label = { Text("Email (optional)") },
                leadingIcon = {
                    Icon(Icons.Default.Email, contentDescription = null)
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // Phone (optional)
            OutlinedTextField(
                value = nomineePhone,
                onValueChange = { nomineePhone = it },
                label = { Text("Phone (optional)") },
                leadingIcon = {
                    Icon(Icons.Default.Phone, contentDescription = null)
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            // Info Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                )
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "The nominee will receive an invitation to access this vault. They'll need to accept the invitation to gain access.",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
                    )
                }
            }
            
            // Send Invitation Button
            Button(
                onClick = {
                    if (nomineeName.isBlank()) {
                        errorMessage = "Please enter nominee name"
                        showError = true
                        return@Button
                    }
                    
                    if (nomineeEmail.isBlank() && nomineePhone.isBlank()) {
                        errorMessage = "Please provide either email or phone number"
                        showError = true
                        return@Button
                    }
                    
                    val selected = selectedVault.value
                    if (selected == null) {
                        errorMessage = "Please select a vault"
                        showError = true
                        return@Button
                    }
                    
                    isInviting = true
                    nomineeViewModel.inviteNominee(
                        vault = selected,
                        name = nomineeName.trim(),
                        email = nomineeEmail.trim().takeIf { it.isNotBlank() },
                        phoneNumber = nomineePhone.trim().takeIf { it.isNotBlank() },
                        onResult = { result ->
                            isInviting = false
                            result.onSuccess {
                                showSuccess = true
                                onInviteSuccess()
                            }.onFailure {
                                errorMessage = it.message ?: "Failed to send invitation"
                                showError = true
                            }
                        }
                    )
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = !isInviting && nomineeName.isNotBlank()
            ) {
                if (isInviting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Icon(Icons.Default.Send, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Send Invitation", fontSize = 16.sp)
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
            title = { Text("Invitation Sent") },
            text = { Text("The invitation has been sent successfully.") },
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
