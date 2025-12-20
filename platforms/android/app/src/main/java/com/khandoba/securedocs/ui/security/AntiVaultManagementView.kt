package com.khandoba.securedocs.ui.security

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
import com.khandoba.securedocs.service.AntiVaultService
import com.khandoba.securedocs.service.AntiVault
import com.khandoba.securedocs.service.VaultService
import com.khandoba.securedocs.data.entity.VaultEntity
import kotlinx.coroutines.launch
import java.util.UUID

@Composable
fun AntiVaultManagementView(
    antiVaultService: AntiVaultService,
    vaultService: VaultService? = null,
    onAntiVaultSelected: (UUID) -> Unit = {},
    onCreateAntiVault: () -> Unit = {}
) {
    val antiVaults by antiVaultService.antiVaults.collectAsState()
    val isLoading by antiVaultService.isLoading.collectAsState()
    val vaults by remember(vaultService) {
        vaultService?.vaults ?: kotlinx.coroutines.flow.MutableStateFlow(emptyList<VaultEntity>())
    }.collectAsState()
    
    val scope = rememberCoroutineScope()
    
    // Load anti-vaults on first composition
    LaunchedEffect(antiVaultService) {
        scope.launch {
            antiVaultService.loadAntiVaults()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Anti-Vaults") },
                actions = {
                    IconButton(onClick = onCreateAntiVault) {
                        Icon(Icons.Default.Add, contentDescription = "Create Anti-Vault")
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
            } else if (antiVaults.isEmpty()) {
                EmptyAntiVaultsView(
                    onCreateClick = onCreateAntiVault
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(antiVaults) { antiVault ->
                        AntiVaultCard(
                            antiVault = antiVault,
                            vaultName = getVaultName(antiVault.monitoredVaultID, vaults),
                            onClick = {
                                onAntiVaultSelected(antiVault.id)
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyAntiVaultsView(
    onCreateClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Shield,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.6f)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "No Anti-Vaults",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Create an anti-vault to monitor a vault for fraud detection",
            fontSize = 14.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(onClick = onCreateClick) {
            Icon(Icons.Default.Add, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Create Anti-Vault")
        }
    }
}

@Composable
private fun AntiVaultCard(
    antiVault: AntiVault,
    vaultName: String?,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(140.dp),
        onClick = onClick
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
                Icon(
                    imageVector = Icons.Default.Shield,
                    contentDescription = "Anti-Vault",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(24.dp)
                )
                Text(
                    text = vaultName ?: "Anti-Vault",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.weight(1f))
                StatusBadge(status = antiVault.status)
            }
            
            Column {
                Text(
                    text = "Monitoring: ${vaultName ?: "Unknown Vault"}",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                Spacer(modifier = Modifier.height(4.dp))
                if (antiVault.lastUnlockedAt != null) {
                    Text(
                        text = "Last unlocked: ${formatDate(antiVault.lastUnlockedAt)}",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (antiVault.status == "active") {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.LockOpen,
                            contentDescription = "Active",
                            tint = androidx.compose.ui.graphics.Color(0xFF4CAF50), // Green
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            text = "Active",
                            fontSize = 12.sp,
                            color = androidx.compose.ui.graphics.Color(0xFF4CAF50) // Green
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun StatusBadge(status: String) {
    val (color, text) = when (status.lowercase()) {
        "active" -> androidx.compose.ui.graphics.Color(0xFF4CAF50) to "ACTIVE" // Green
        "locked" -> MaterialTheme.colorScheme.outline to "LOCKED"
        "archived" -> MaterialTheme.colorScheme.error to "ARCHIVED"
        else -> MaterialTheme.colorScheme.outline to status.uppercase()
    }
    
    Surface(
        color = color.copy(alpha = 0.2f),
        shape = MaterialTheme.shapes.small
    ) {
        Text(
            text = text,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            color = color,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

private fun getVaultName(vaultID: UUID?, vaults: List<VaultEntity>): String? {
    return vaultID?.let { id ->
        vaults.firstOrNull { it.id == id }?.name
    }
}

private fun formatDate(date: java.util.Date): String {
    val format = java.text.SimpleDateFormat("MMM d, yyyy 'at' h:mm a", java.util.Locale.getDefault())
    return format.format(date)
}
