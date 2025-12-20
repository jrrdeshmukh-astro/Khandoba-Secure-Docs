package com.khandoba.securedocs.ui.profile

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SecuritySettingsView(
    onBack: () -> Unit
) {
    var biometricAuthEnabled by remember { mutableStateOf(true) }
    var requireBiometricOnVaultOpen by remember { mutableStateOf(true) }
    var autoLockEnabled by remember { mutableStateOf(true) }
    var sessionTimeoutMinutes by remember { mutableStateOf(30) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Security") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Biometric Authentication
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Biometric Authentication",
                                style = MaterialTheme.typography.bodyLarge
                            )
                            Text(
                                text = "Use fingerprint or face recognition to unlock",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                        }
                        Switch(
                            checked = biometricAuthEnabled,
                            onCheckedChange = { biometricAuthEnabled = it }
                        )
                    }
                    
                    if (biometricAuthEnabled) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Require on Vault Open",
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                Text(
                                    text = "Require biometric authentication when opening vaults",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                                )
                            }
                            Switch(
                                checked = requireBiometricOnVaultOpen,
                                onCheckedChange = { requireBiometricOnVaultOpen = it }
                            )
                        }
                    }
                }
            }
            
            // Auto Lock
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Auto Lock",
                                style = MaterialTheme.typography.bodyLarge
                            )
                            Text(
                                text = "Automatically lock app after inactivity",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                            )
                        }
                        Switch(
                            checked = autoLockEnabled,
                            onCheckedChange = { autoLockEnabled = it }
                        )
                    }
                    
                    if (autoLockEnabled) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Session Timeout",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                            ) {
                                TextButton(onClick = { sessionTimeoutMinutes = maxOf(1, sessionTimeoutMinutes - 5) }) {
                                    Text("-")
                                }
                                Text("${sessionTimeoutMinutes} min")
                                TextButton(onClick = { sessionTimeoutMinutes = minOf(120, sessionTimeoutMinutes + 5) }) {
                                    Text("+")
                                }
                            }
                        }
                    }
                }
            }
            
            // Security Information
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Security Features",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Text(
                        text = "• AES-256-GCM encryption",
                        style = MaterialTheme.typography.bodySmall
                    )
                    Text(
                        text = "• Zero-knowledge architecture",
                        style = MaterialTheme.typography.bodySmall
                    )
                    Text(
                        text = "• ML-based threat monitoring",
                        style = MaterialTheme.typography.bodySmall
                    )
                    Text(
                        text = "• Complete audit trails",
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        }
    }
}
