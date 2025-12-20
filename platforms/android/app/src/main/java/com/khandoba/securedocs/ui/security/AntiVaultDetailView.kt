package com.khandoba.securedocs.ui.security

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import com.khandoba.securedocs.service.ThreatDetection
import kotlinx.coroutines.launch
import java.util.UUID

@Composable
fun AntiVaultDetailView(
    antiVaultId: UUID,
    antiVaultService: AntiVaultService,
    onBack: () -> Unit,
    onUnlock: (UUID) -> Unit = {}
) {
    val antiVaults by antiVaultService.antiVaults.collectAsState()
    val detectedThreats by antiVaultService.detectedThreats.collectAsState()
    val antiVault = antiVaults.firstOrNull { it.id == antiVaultId }
    
    val scope = rememberCoroutineScope()
    
    // Load threats for this anti-vault
    LaunchedEffect(antiVaultId) {
        scope.launch {
            antiVaultService.loadThreatsForAntiVault(antiVaultId)
        }
    }
    
    if (antiVault == null) {
        // Show error or loading
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text("Anti-vault not found")
        }
        return
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Anti-Vault Details") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Status Card
            item {
                StatusCard(antiVault = antiVault)
            }
            
            // Monitored Vault Card
            item {
                MonitoredVaultCard(antiVault = antiVault)
            }
            
            // Auto-Unlock Policy Card
            item {
                AutoUnlockPolicyCard(antiVault = antiVault)
            }
            
            // Threat Detection Settings Card
            item {
                ThreatDetectionSettingsCard(antiVault = antiVault)
            }
            
            // Detected Threats Card
            if (detectedThreats.isNotEmpty()) {
                item {
                    DetectedThreatsCard(
                        threats = detectedThreats,
                        onViewAll = { /* Navigate to full threat view */ }
                    )
                }
            }
            
            // Actions
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    if (antiVault.status == "locked") {
                        Button(
                            onClick = {
                                scope.launch {
                                    antiVaultService.unlockAntiVault(antiVault, antiVault.monitoredVaultID)
                                    onUnlock(antiVault.monitoredVaultID)
                                }
                            },
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Default.LockOpen, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Unlock Anti-Vault")
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun StatusCard(antiVault: AntiVault) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Status",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
                StatusBadge(status = antiVault.status)
            }
            
            if (antiVault.lastUnlockedAt != null) {
                Text(
                    text = "Last unlocked: ${formatDate(antiVault.lastUnlockedAt)}",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
        }
    }
}

@Composable
private fun MonitoredVaultCard(antiVault: AntiVault) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Monitored Vault",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "Vault ID: ${antiVault.monitoredVaultID}",
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun AutoUnlockPolicyCard(antiVault: AntiVault) {
    val policy = antiVault.autoUnlockPolicy
    
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Auto-Unlock Policy",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            
            PolicyItem(
                label = "Unlock on Session Nomination",
                enabled = policy.unlockOnSessionNomination
            )
            PolicyItem(
                label = "Unlock on Subset Nomination",
                enabled = policy.unlockOnSubsetNomination
            )
            PolicyItem(
                label = "Require Approval",
                enabled = policy.requireApproval
            )
        }
    }
}

@Composable
private fun ThreatDetectionSettingsCard(antiVault: AntiVault) {
    val settings = antiVault.threatDetectionSettings
    
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "Threat Detection Settings",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            
            PolicyItem(
                label = "Detect Content Discrepancies",
                enabled = settings.detectContentDiscrepancies
            )
            PolicyItem(
                label = "Detect Metadata Mismatches",
                enabled = settings.detectMetadataMismatches
            )
            PolicyItem(
                label = "Detect Access Pattern Anomalies",
                enabled = settings.detectAccessPatternAnomalies
            )
            PolicyItem(
                label = "Detect Geographic Inconsistencies",
                enabled = settings.detectGeographicInconsistencies
            )
            PolicyItem(
                label = "Detect Edit History Discrepancies",
                enabled = settings.detectEditHistoryDiscrepancies
            )
            
            Divider()
            
            Text(
                text = "Minimum Threat Severity: ${settings.minThreatSeverity.uppercase()}",
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun DetectedThreatsCard(
    threats: List<ThreatDetection>,
    onViewAll: () -> Unit
) {
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
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error
                    )
                    Text(
                        text = "Detected Threats",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                TextButton(onClick = onViewAll) {
                    Text("View All")
                }
            }
            
            threats.take(3).forEach { threat ->
                ThreatRow(threat = threat)
            }
            
            if (threats.size > 3) {
                Text(
                    text = "+ ${threats.size - 3} more",
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
            }
        }
    }
}

@Composable
private fun PolicyItem(label: String, enabled: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            fontSize = 14.sp
        )
            Icon(
                imageVector = if (enabled) Icons.Default.CheckCircle else Icons.Default.Cancel,
                contentDescription = null,
                tint = if (enabled) androidx.compose.ui.graphics.Color(0xFF4CAF50) else MaterialTheme.colorScheme.outline
            )
    }
}

@Composable
private fun ThreatRow(threat: ThreatDetection) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = getSeverityIcon(threat.severity),
            contentDescription = null,
            tint = getSeverityColor(threat.severity),
            modifier = Modifier.size(20.dp)
        )
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = threat.type.replace("_", " ").replaceFirstChar { it.uppercase() },
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = threat.description,
                fontSize = 12.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                maxLines = 2
            )
        }
        
        Surface(
            color = getSeverityColor(threat.severity).copy(alpha = 0.2f),
            shape = MaterialTheme.shapes.small
        ) {
            Text(
                text = threat.severity.uppercase(),
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                color = getSeverityColor(threat.severity),
                modifier = Modifier.padding(horizontal = 6.dp, vertical = 4.dp)
            )
        }
    }
}

private fun getSeverityIcon(severity: String): androidx.compose.ui.graphics.vector.ImageVector {
    return when (severity.lowercase()) {
        "critical" -> Icons.Default.Error
        "high" -> Icons.Default.Warning
        "medium" -> Icons.Default.Info
        else -> Icons.Default.CheckCircle
    }
}

private fun getSeverityColor(severity: String): androidx.compose.ui.graphics.Color {
    return when (severity.lowercase()) {
        "critical" -> MaterialTheme.colorScheme.error
        "high" -> androidx.compose.ui.graphics.Color(0xFFFF9800) // Orange
        "medium" -> MaterialTheme.colorScheme.primary
        else -> androidx.compose.ui.graphics.Color(0xFF4CAF50) // Green
    }
}

private fun formatDate(date: java.util.Date): String {
    val format = java.text.SimpleDateFormat("MMM d, yyyy 'at' h:mm a", java.util.Locale.getDefault())
    return format.format(date)
}
