package com.khandoba.securedocs.ui.security

import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.khandoba.securedocs.service.ThreatIndexService
import java.util.UUID

/**
 * Composable wrapper that connects ThreatIndexChartView to ThreatIndexService
 * for real-time threat index updates
 */
@Composable
fun ThreatIndexChartComposable(
    vaultId: UUID,
    threatIndexService: ThreatIndexService,
    modifier: Modifier = Modifier
) {
    // Collect threat index history and current index from service
    val threatIndexHistory by threatIndexService.threatIndexHistory.collectAsState()
    val currentThreatIndices by threatIndexService.currentThreatIndices.collectAsState()
    
    val history = threatIndexHistory[vaultId] ?: emptyList()
    val currentIndex = currentThreatIndices[vaultId]
    
    // Initialize monitoring when composable is first created
    LaunchedEffect(vaultId) {
        threatIndexService.initializeThreatIndexMonitoring(vaultId)
    }
    
    ThreatIndexChartView(
        threatIndexHistory = history,
        currentThreatIndex = currentIndex,
        modifier = modifier
    )
}
