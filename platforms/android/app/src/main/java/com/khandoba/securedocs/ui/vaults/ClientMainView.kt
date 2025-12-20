package com.khandoba.securedocs.ui.vaults

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.khandoba.securedocs.viewmodel.VaultViewModel
import com.khandoba.securedocs.viewmodel.AuthenticationViewModel
import com.khandoba.securedocs.viewmodel.DocumentViewModel

@Composable
fun ClientMainView(
    vaultViewModel: VaultViewModel,
    authViewModel: AuthenticationViewModel,
    documentViewModel: DocumentViewModel? = null,
    onVaultSelected: (java.util.UUID) -> Unit = {},
    onSignOut: () -> Unit = {},
    onNavigateToNotifications: () -> Unit = {},
    onNavigateToSecurity: () -> Unit = {},
    onNavigateToAbout: () -> Unit = {}
) {
    var selectedTab by remember { mutableStateOf(0) }
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Folder, contentDescription = "Vaults") },
                    label = { Text("Vaults") },
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Description, contentDescription = "Documents") },
                    label = { Text("Documents") },
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 }
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Person, contentDescription = "Profile") },
                    label = { Text("Profile") },
                    selected = selectedTab == 2,
                    onClick = { selectedTab = 2 }
                )
            }
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when (selectedTab) {
                0 -> VaultListView(
                    vaultViewModel = vaultViewModel,
                    onVaultSelected = onVaultSelected
                )
                1 -> DocumentsTab(documentViewModel)
                2 -> ProfileTab(
                    authViewModel = authViewModel,
                    onSignOut = onSignOut,
                    onNavigateToNotifications = onNavigateToNotifications,
                    onNavigateToSecurity = onNavigateToSecurity,
                    onNavigateToAbout = onNavigateToAbout,
                    onNavigateToAntiVaults = onNavigateToAntiVaults
                )
            }
        }
    }
}

@Composable
private fun DocumentsTab(
    documentViewModel: DocumentViewModel? = null
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = androidx.compose.ui.Alignment.Center
    ) {
        Text("Documents - Select a vault to view documents")
    }
}

@Composable
private fun ProfileTab(
    authViewModel: AuthenticationViewModel,
    onSignOut: () -> Unit,
    onNavigateToNotifications: () -> Unit = {},
    onNavigateToSecurity: () -> Unit = {},
    onNavigateToAbout: () -> Unit = {},
    onNavigateToAntiVaults: () -> Unit = {}
) {
    com.khandoba.securedocs.ui.profile.ProfileView(
        authViewModel = authViewModel,
        onSignOut = onSignOut,
        onNavigateToNotifications = onNavigateToNotifications,
        onNavigateToSecurity = onNavigateToSecurity,
        onNavigateToAbout = onNavigateToAbout,
        onNavigateToAntiVaults = onNavigateToAntiVaults
    )
}

