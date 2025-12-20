package com.khandoba.securedocs.ui.emergency

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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.service.EmergencyApprovalService
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EmergencyAccessUnlockView(
    vault: VaultEntity,
    emergencyApprovalService: EmergencyApprovalService,
    onDismiss: () -> Unit,
    onUnlockSuccess: () -> Unit = {}
) {
    var passCode by remember { mutableStateOf("") }
    var isUnlocking by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showError by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    val context = LocalContext.current
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Emergency Unlock") },
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
            // Header
            Icon(
                imageVector = Icons.Default.Lock,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Text(
                text = "Emergency Access",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = "Enter your emergency access pass code",
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
            
            // Vault Info Card
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
                        text = vault.name,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            
            // Pass Code Input
            OutlinedTextField(
                value = passCode,
                onValueChange = { passCode = it },
                label = { Text("Pass Code") },
                placeholder = { Text("Enter pass code") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                visualTransformation = PasswordVisualTransformation()
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
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "Biometric verification is required even with a valid pass code.",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f)
                    )
                }
            }
            
            // Unlock Button
            Button(
                onClick = {
                    if (passCode.isBlank()) {
                        errorMessage = "Please enter pass code"
                        showError = true
                        return@Button
                    }
                    
                    isUnlocking = true
                    // Verify pass code
                    emergencyApprovalService.verifyEmergencyPass(
                        passCode = passCode.trim(),
                        vaultID = vault.id
                    )?.let { request ->
                        // Pass code is valid - trigger biometric auth
                        // TODO: Integrate biometric authentication
                        // For now, show success
                        isUnlocking = false
                        showSuccess = true
                        onUnlockSuccess()
                    } ?: run {
                        isUnlocking = false
                        errorMessage = "Invalid or expired pass code"
                        showError = true
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = !isUnlocking && passCode.isNotBlank()
            ) {
                if (isUnlocking) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = MaterialTheme.colorScheme.onPrimary
                    )
                } else {
                    Icon(Icons.Default.LockOpen, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Unlock Vault", fontSize = 16.sp)
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
            title = { Text("Access Granted") },
            text = { Text("Emergency access granted. The vault is now unlocked.") },
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
