package com.khandoba.securedocs.ui.sharing

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
import com.khandoba.securedocs.data.entity.NomineeEntity
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.viewmodel.NomineeViewModel
import androidx.compose.ui.graphics.Color

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NomineeManagementView(
    vault: VaultEntity,
    nomineeViewModel: NomineeViewModel,
    onDismiss: () -> Unit,
    onInviteNominee: () -> Unit = {}
) {
    val nominees by nomineeViewModel.nominees.collectAsState()
    val isLoading by nomineeViewModel.isLoading.collectAsState()
    var showRevokeDialog by remember { mutableStateOf<NomineeEntity?>(null) }
    var isRevoking by remember { mutableStateOf(false) }
    
    // Load nominees when view appears
    LaunchedEffect(vault.id) {
        nomineeViewModel.loadNominees(vault.id)
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Nominees") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = onInviteNominee) {
                        Icon(Icons.Default.PersonAdd, contentDescription = "Invite Nominee")
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onInviteNominee) {
                Icon(Icons.Default.Add, contentDescription = "Invite Nominee")
            }
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
                nominees.isEmpty() -> {
                    EmptyNomineesView(
                        onInviteClick = onInviteNominee,
                        modifier = Modifier.fillMaxSize()
                    )
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(nominees) { nominee ->
                            NomineeCard(
                                nominee = nominee,
                                onRevoke = {
                                    showRevokeDialog = nominee
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Revoke Confirmation Dialog
    showRevokeDialog?.let { nominee ->
        AlertDialog(
            onDismissRequest = { showRevokeDialog = null },
            title = { Text("Revoke Nominee") },
            text = {
                Text("Are you sure you want to revoke access for ${nominee.name}? They will no longer be able to access this vault.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        isRevoking = true
                        nomineeViewModel.revokeNominee(nominee) { result ->
                            isRevoking = false
                            result.onSuccess {
                                showRevokeDialog = null
                                nomineeViewModel.loadNominees(vault.id)
                            }.onFailure {
                                // Handle error
                                showRevokeDialog = null
                            }
                        }
                    },
                    enabled = !isRevoking
                ) {
                    if (isRevoking) {
                        CircularProgressIndicator(modifier = Modifier.size(20.dp))
                    } else {
                        Text("Revoke", color = MaterialTheme.colorScheme.error)
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { showRevokeDialog = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun NomineeCard(
    nominee: NomineeEntity,
    onRevoke: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth()
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
                // Status Indicator
                Icon(
                    imageVector = when (nominee.statusRaw) {
                        "pending" -> Icons.Default.Schedule
                        "accepted", "active" -> Icons.Default.CheckCircle
                        "revoked", "inactive" -> Icons.Default.Cancel
                        else -> Icons.Default.Person
                    },
                    contentDescription = null,
                    tint = when (nominee.statusRaw) {
                        "pending" -> Color(0xFFFF9800) // Warning orange
                        "accepted", "active" -> Color(0xFF4CAF50) // Success green
                        "revoked", "inactive" -> MaterialTheme.colorScheme.error
                        else -> MaterialTheme.colorScheme.onSurface
                    }
                )
                
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = nominee.name.ifEmpty { "Unknown Nominee" },
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium
                    )
                    
                    if (!nominee.email.isNullOrEmpty()) {
                        Text(
                            text = nominee.email!!,
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(4.dp))
                    
                    Text(
                        text = when (nominee.statusRaw) {
                            "pending" -> "Pending acceptance"
                            "accepted" -> "Accepted"
                            "active" -> "Active"
                            "revoked" -> "Revoked"
                            "inactive" -> "Inactive"
                            else -> "Unknown status"
                        },
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }
            
            // Revoke Button
            if (nominee.statusRaw != "revoked" && nominee.statusRaw != "inactive") {
                IconButton(onClick = onRevoke) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Revoke",
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
}

@Composable
private fun EmptyNomineesView(
    onInviteClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.PersonAdd,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "No Nominees",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "Invite people to access this vault",
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Button(onClick = onInviteClick) {
            Icon(Icons.Default.Add, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Invite Nominee")
        }
    }
}

