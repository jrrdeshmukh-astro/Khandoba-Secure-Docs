package com.khandoba.securedocs.ui.security

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
import androidx.compose.ui.window.Dialog
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.service.AntiVaultService
import com.khandoba.securedocs.service.ThreatDetectionSettings
import com.khandoba.securedocs.service.AutoUnlockPolicy
import kotlinx.coroutines.launch
import java.util.UUID

@Composable
fun CreateAntiVaultView(
    antiVaultService: AntiVaultService,
    availableVaults: List<VaultEntity>,
    currentUserID: UUID,
    onDismiss: () -> Unit,
    onCreated: (UUID) -> Unit = {}
) {
    var selectedVault by remember { mutableStateOf<VaultEntity?>(null) }
    var threatSettings by remember {
        mutableStateOf(
            ThreatDetectionSettings(
                detectContentDiscrepancies = true,
                detectMetadataMismatches = true,
                detectAccessPatternAnomalies = true,
                detectGeographicInconsistencies = true,
                detectEditHistoryDiscrepancies = true,
                minThreatSeverity = "medium"
            )
        )
    }
    var autoUnlockPolicy by remember {
        mutableStateOf(
            AutoUnlockPolicy(
                unlockOnSessionNomination = true,
                unlockOnSubsetNomination = true,
                requireApproval = false,
                approvalUserIDs = emptyList()
            )
        )
    }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    val scope = rememberCoroutineScope()
    
    Dialog(onDismissRequest = onDismiss) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = 600.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Create Anti-Vault",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
                
                Divider()
                
                // Vault Selection
                Text(
                    text = "Select Vault to Monitor",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium
                )
                
                val filteredVaults = availableVaults.filter { 
                    !it.isAntiVault && !it.isSystemVault 
                }
                
                if (filteredVaults.isEmpty()) {
                    Text(
                        text = "No vaults available for monitoring",
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                } else {
                    filteredVaults.forEach { vault ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedVault?.id == vault.id,
                                onClick = { selectedVault = vault }
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = vault.name,
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Medium
                                )
                                if (!vault.vaultDescription.isNullOrEmpty()) {
                                    Text(
                                        text = vault.vaultDescription!!,
                                        fontSize = 12.sp,
                                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                                    )
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Auto-Unlock Policy
                Text(
                    text = "Auto-Unlock Policy",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium
                )
                
                SwitchWithLabel(
                    label = "Unlock on Session Nomination",
                    checked = autoUnlockPolicy.unlockOnSessionNomination,
                    onCheckedChange = {
                        autoUnlockPolicy = autoUnlockPolicy.copy(unlockOnSessionNomination = it)
                    }
                )
                
                SwitchWithLabel(
                    label = "Unlock on Subset Nomination",
                    checked = autoUnlockPolicy.unlockOnSubsetNomination,
                    onCheckedChange = {
                        autoUnlockPolicy = autoUnlockPolicy.copy(unlockOnSubsetNomination = it)
                    }
                )
                
                SwitchWithLabel(
                    label = "Require Approval",
                    checked = autoUnlockPolicy.requireApproval,
                    onCheckedChange = {
                        autoUnlockPolicy = autoUnlockPolicy.copy(requireApproval = it)
                    }
                )
                
                Divider()
                
                // Threat Detection Settings
                Text(
                    text = "Threat Detection Settings",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium
                )
                
                SwitchWithLabel(
                    label = "Detect Content Discrepancies",
                    checked = threatSettings.detectContentDiscrepancies,
                    onCheckedChange = {
                        threatSettings = threatSettings.copy(detectContentDiscrepancies = it)
                    }
                )
                
                SwitchWithLabel(
                    label = "Detect Metadata Mismatches",
                    checked = threatSettings.detectMetadataMismatches,
                    onCheckedChange = {
                        threatSettings = threatSettings.copy(detectMetadataMismatches = it)
                    }
                )
                
                SwitchWithLabel(
                    label = "Detect Access Pattern Anomalies",
                    checked = threatSettings.detectAccessPatternAnomalies,
                    onCheckedChange = {
                        threatSettings = threatSettings.copy(detectAccessPatternAnomalies = it)
                    }
                )
                
                SwitchWithLabel(
                    label = "Detect Geographic Inconsistencies",
                    checked = threatSettings.detectGeographicInconsistencies,
                    onCheckedChange = {
                        threatSettings = threatSettings.copy(detectGeographicInconsistencies = it)
                    }
                )
                
                SwitchWithLabel(
                    label = "Detect Edit History Discrepancies",
                    checked = threatSettings.detectEditHistoryDiscrepancies,
                    onCheckedChange = {
                        threatSettings = threatSettings.copy(detectEditHistoryDiscrepancies = it)
                    }
                )
                
                // Minimum Threat Severity
                var expandedSeverity by remember { mutableStateOf(false) }
                val severityOptions = listOf("low", "medium", "high", "critical")
                
                ExposedDropdownMenuBox(
                    expanded = expandedSeverity,
                    onExpandedChange = { expandedSeverity = !expandedSeverity }
                ) {
                    OutlinedTextField(
                        value = threatSettings.minThreatSeverity.uppercase(),
                        onValueChange = { },
                        readOnly = true,
                        label = { Text("Minimum Threat Severity") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expandedSeverity) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    ExposedDropdownMenu(
                        expanded = expandedSeverity,
                        onDismissRequest = { expandedSeverity = false }
                    ) {
                        severityOptions.forEach { option ->
                            DropdownMenuItem(
                                text = { Text(option.uppercase()) },
                                onClick = {
                                    threatSettings = threatSettings.copy(minThreatSeverity = option)
                                    expandedSeverity = false
                                }
                            )
                        }
                    }
                }
                
                // Error Message
                errorMessage?.let { error ->
                    Text(
                        text = error,
                        color = MaterialTheme.colorScheme.error,
                        fontSize = 12.sp
                    )
                }
                
                // Actions
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("Cancel")
                    }
                    
                    Button(
                        onClick = {
                            if (selectedVault == null) {
                                errorMessage = "Please select a vault to monitor"
                                return@Button
                            }
                            
                            isLoading = true
                            errorMessage = null
                            
                            scope.launch {
                                try {
                                    val antiVault = antiVaultService.createAntiVault(
                                        monitoredVault = selectedVault!!,
                                        ownerID = currentUserID,
                                        settings = threatSettings
                                    )
                                    // Update auto-unlock policy (would need service method to update)
                                    onCreated(antiVault.id)
                                    onDismiss()
                                } catch (e: Exception) {
                                    errorMessage = e.message ?: "Failed to create anti-vault"
                                    isLoading = false
                                }
                            }
                        },
                        modifier = Modifier.weight(1f),
                        enabled = !isLoading && selectedVault != null
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        } else {
                            Text("Create")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SwitchWithLabel(
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            fontSize = 14.sp
        )
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}
