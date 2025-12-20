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
fun NotificationsSettingsView(
    onBack: () -> Unit
) {
    var pushNotificationsEnabled by remember { mutableStateOf(true) }
    var emailNotificationsEnabled by remember { mutableStateOf(false) }
    var vaultAccessAlertsEnabled by remember { mutableStateOf(true) }
    var documentUploadAlertsEnabled by remember { mutableStateOf(true) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Notifications") },
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
            // Push Notifications
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Push Notifications",
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Text(
                            text = "Receive push notifications on your device",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                    Switch(
                        checked = pushNotificationsEnabled,
                        onCheckedChange = { pushNotificationsEnabled = it }
                    )
                }
            }
            
            // Email Notifications
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Email Notifications",
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Text(
                            text = "Receive notifications via email",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                    Switch(
                        checked = emailNotificationsEnabled,
                        onCheckedChange = { emailNotificationsEnabled = it }
                    )
                }
            }
            
            Divider()
            
            // Alert Settings
            Text(
                text = "Alert Types",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
            )
            
            // Vault Access Alerts
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Vault Access Alerts",
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Text(
                            text = "Get notified when someone accesses your vault",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                    Switch(
                        checked = vaultAccessAlertsEnabled,
                        onCheckedChange = { vaultAccessAlertsEnabled = it }
                    )
                }
            }
            
            // Document Upload Alerts
            Card(
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Document Upload Alerts",
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Text(
                            text = "Get notified when documents are uploaded",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                    Switch(
                        checked = documentUploadAlertsEnabled,
                        onCheckedChange = { documentUploadAlertsEnabled = it }
                    )
                }
            }
        }
    }
}
