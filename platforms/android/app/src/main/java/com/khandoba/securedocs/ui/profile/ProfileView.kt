package com.khandoba.securedocs.ui.profile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khandoba.securedocs.viewmodel.AuthenticationViewModel

@Composable
fun ProfileView(
    authViewModel: AuthenticationViewModel,
    onSignOut: () -> Unit,
    onNavigateToNotifications: () -> Unit = {},
    onNavigateToSecurity: () -> Unit = {},
    onNavigateToAbout: () -> Unit = {},
    onNavigateToAntiVaults: () -> Unit = {}
) {
    val currentUser by authViewModel.currentUser.collectAsState()
    var showSignOutDialog by remember { mutableStateOf(false) }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        // Profile Header
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Avatar
                Surface(
                    modifier = Modifier.size(80.dp),
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.primaryContainer
                ) {
                    Box(
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = null,
                            modifier = Modifier.size(40.dp),
                            tint = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }
                
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = currentUser?.fullName ?: "User",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold
                    )
                    
                    if (currentUser?.email != null) {
                        Text(
                            text = currentUser!!.email!!,
                            fontSize = 14.sp,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // User badge
                    Surface(
                        color = MaterialTheme.colorScheme.primaryContainer,
                        shape = MaterialTheme.shapes.small
                    ) {
                        Text(
                            text = "User",
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Settings Section
        Card(
            modifier = Modifier.fillMaxWidth()
        ) {
            Column {
                SettingsItem(
                    icon = Icons.Default.Notifications,
                    title = "Notifications",
                    onClick = onNavigateToNotifications
                )
                
                Divider()
                
                SettingsItem(
                    icon = Icons.Default.Security,
                    title = "Security",
                    onClick = onNavigateToSecurity
                )
                
                Divider()
                
                SettingsItem(
                    icon = Icons.Default.Shield,
                    title = "Anti-Vaults",
                    onClick = onNavigateToAntiVaults
                )
                
                Divider()
                
                SettingsItem(
                    icon = Icons.Default.Info,
                    title = "About",
                    onClick = onNavigateToAbout
                )
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Sign Out Button
        Button(
            onClick = { showSignOutDialog = true },
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.error
            )
        ) {
            Icon(Icons.Default.ExitToApp, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Sign Out")
        }
        
        // Sign Out Confirmation Dialog
        if (showSignOutDialog) {
            AlertDialog(
                onDismissRequest = { showSignOutDialog = false },
                title = { Text("Sign Out") },
                text = { Text("Are you sure you want to sign out?") },
                confirmButton = {
                    TextButton(
                        onClick = {
                            showSignOutDialog = false
                            authViewModel.signOut()
                            onSignOut()
                        }
                    ) {
                        Text("Sign Out", color = MaterialTheme.colorScheme.error)
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showSignOutDialog = false }) {
                        Text("Cancel")
                    }
                }
            )
        }
    }
}

@Composable
private fun SettingsItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Text(
                text = title,
                fontSize = 16.sp
            )
        }
        
        Icon(
            imageVector = Icons.Default.ChevronRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
        )
    }
}
