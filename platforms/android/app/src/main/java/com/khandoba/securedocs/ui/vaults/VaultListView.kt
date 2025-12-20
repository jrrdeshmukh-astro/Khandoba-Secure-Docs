package com.khandoba.securedocs.ui.vaults

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import kotlinx.coroutines.launch
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.viewmodel.VaultViewModel
import com.khandoba.securedocs.service.BroadcastVaultService
import java.util.UUID

@Composable
fun VaultListView(
    vaultViewModel: VaultViewModel,
    broadcastVaultService: BroadcastVaultService? = null,
    onVaultSelected: (UUID) -> Unit = {}
) {
    val vaults by vaultViewModel.vaults.collectAsState()
    val broadcastVaultsState by remember(broadcastVaultService) {
        broadcastVaultService?.broadcastVaults ?: kotlinx.coroutines.flow.MutableStateFlow(emptyList<VaultEntity>())
    }.collectAsState()
    val broadcastVaults = broadcastVaultsState
    val isLoading by vaultViewModel.isLoading.collectAsState()
    
    var showCreateDialog by remember { mutableStateOf(false) }
    var vaultName by remember { mutableStateOf("") }
    var vaultDescription by remember { mutableStateOf("") }
    
    // Load broadcast vaults on first composition
    LaunchedEffect(broadcastVaultService) {
        broadcastVaultService?.loadBroadcastVaults()
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Vaults") },
                actions = {
                    IconButton(onClick = { showCreateDialog = true }) {
                        Icon(Icons.Default.Add, contentDescription = "Create Vault")
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
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            } else if (vaults.isEmpty()) {
                EmptyVaultsView(
                    onCreateClick = { showCreateDialog = true }
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Broadcast Vaults Section
                    if (broadcastVaults.isNotEmpty()) {
                        item {
                            Text(
                                text = "Public Vaults",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(vertical = 8.dp)
                            )
                        }
                        items(broadcastVaults) { vault ->
                            VaultCard(
                                vault = vault,
                                isBroadcast = true,
                                onClick = { 
                                    onVaultSelected(vault.id)
                                }
                            )
                        }
                        item {
                            Text(
                                text = "Your Vaults",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.padding(top = 16.dp, bottom = 8.dp)
                            )
                        }
                    }
                    
                    // User Vaults
                    items(vaults) { vault ->
                        VaultCard(
                            vault = vault,
                            isBroadcast = false,
                            onClick = { 
                                onVaultSelected(vault.id)
                            }
                        )
                    }
                }
            }
            
            // Create Vault Dialog
            if (showCreateDialog) {
                CreateVaultDialog(
                    vaultName = vaultName,
                    vaultDescription = vaultDescription,
                    onNameChange = { vaultName = it },
                    onDescriptionChange = { vaultDescription = it },
                    onDismiss = { showCreateDialog = false },
                    onCreate = {
                        vaultViewModel.createVault(
                            name = vaultName,
                            description = vaultDescription.ifEmpty { null },
                            keyType = "single"
                        ) { result ->
                            result.onSuccess {
                                showCreateDialog = false
                                vaultName = ""
                                vaultDescription = ""
                            }.onFailure {
                                // Handle error
                            }
                        }
                    }
                )
            }
        }
    }
}

@Composable
private fun VaultCard(
    vault: VaultEntity,
    isBroadcast: Boolean = false,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(120.dp),
        onClick = onClick,
        colors = if (isBroadcast) {
            CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            )
        } else {
            CardDefaults.cardColors()
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (isBroadcast) {
                    Icon(
                        imageVector = Icons.Default.Public,
                        contentDescription = "Broadcast Vault",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                }
                Text(
                    text = vault.name,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
                if (isBroadcast) {
                    Badge {
                        Text("Public")
                    }
                }
            }
            
            if (!vault.vaultDescription.isNullOrEmpty()) {
                Text(
                    text = vault.vaultDescription!!,
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = vault.status,
                    fontSize = 12.sp,
                    color = when (vault.status) {
                        "active" -> MaterialTheme.colorScheme.primary
                        "locked" -> MaterialTheme.colorScheme.error
                        else -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    }
                )
                
                Text(
                    text = vault.keyType,
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
        }
    }
}

@Composable
private fun EmptyVaultsView(
    onCreateClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "No Vaults Yet",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        Text(
            text = "Create your first vault to get started",
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(onClick = onCreateClick) {
            Text("Create Vault")
        }
    }
}

@Composable
private fun CreateVaultDialog(
    vaultName: String,
    vaultDescription: String,
    onNameChange: (String) -> Unit,
    onDescriptionChange: (String) -> Unit,
    onDismiss: () -> Unit,
    onCreate: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create New Vault") },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = vaultName,
                    onValueChange = onNameChange,
                    label = { Text("Vault Name") },
                    modifier = Modifier.fillMaxWidth()
                )
                
                OutlinedTextField(
                    value = vaultDescription,
                    onValueChange = onDescriptionChange,
                    label = { Text("Description (Optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 3
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = onCreate,
                enabled = vaultName.isNotBlank()
            ) {
                Text("Create")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

