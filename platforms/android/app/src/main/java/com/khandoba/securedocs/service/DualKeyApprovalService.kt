package com.khandoba.securedocs.service

import android.util.Log
import com.khandoba.securedocs.data.entity.DualKeyRequestEntity
import com.khandoba.securedocs.data.entity.VaultAccessLogEntity
import com.khandoba.securedocs.data.entity.VaultEntity
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

enum class DualKeyDecision {
    Approved,
    Denied
}

class DualKeyApprovalService(
    private val threatMonitoringService: ThreatMonitoringService
) {
    private val _pendingRequests = MutableStateFlow<List<DualKeyRequestEntity>>(emptyList())
    val pendingRequests: StateFlow<List<DualKeyRequestEntity>> = _pendingRequests.asStateFlow()
    
    private val _isProcessing = MutableStateFlow(false)
    val isProcessing: StateFlow<Boolean> = _isProcessing.asStateFlow()
    
    // ML thresholds
    private val autoApproveThreshold = 50.0 // Score below 50 = approve
    private val maxDistanceKm = 100.0
    private val impossibleTravelThreshold = 500.0 // km in 1 hour
    
    suspend fun processDualKeyRequest(
        request: DualKeyRequestEntity,
        vault: VaultEntity,
        accessLogs: List<VaultAccessLogEntity>
    ): DualKeyDecision {
        _isProcessing.value = true
        
        try {
            // Calculate threat score
            val threatLevel = threatMonitoringService.analyzeThreatLevel(vault, accessLogs)
            val threatScore = when (threatLevel) {
                com.khandoba.securedocs.service.ThreatLevel.Low -> 20.0
                com.khandoba.securedocs.service.ThreatLevel.Medium -> 50.0
                com.khandoba.securedocs.service.ThreatLevel.High -> 80.0
            }
            
            // Calculate geospatial risk
            val geoRisk = calculateGeospatialRisk(accessLogs)
            
            // Behavioral analysis
            val behaviorScore = analyzeBehavior(accessLogs)
            
            // Combined ML score
            val mlScore = calculateCombinedMLScore(
                threatScore = threatScore,
                geoRisk = geoRisk,
                behaviorScore = behaviorScore
            )
            
            Log.d("DualKeyApproval", "ML Score: $mlScore | Threat: $threatScore | Geo: $geoRisk | Behavior: $behaviorScore")
            
            // Make decision
            val decision = if (mlScore < autoApproveThreshold) {
                DualKeyDecision.Approved
            } else {
                DualKeyDecision.Denied
            }
            
            // Update request
            val updatedRequest = request.copy(
                status = when (decision) {
                    DualKeyDecision.Approved -> "approved"
                    DualKeyDecision.Denied -> "denied"
                },
                mlScore = mlScore,
                decisionMethod = "ml_auto",
                approvedAt = if (decision == DualKeyDecision.Approved) java.util.Date() else null,
                deniedAt = if (decision == DualKeyDecision.Denied) java.util.Date() else null
            )
            
            _pendingRequests.value = _pendingRequests.value.filter { it.id != request.id }
            
            return decision
        } finally {
            _isProcessing.value = false
        }
    }
    
    private fun calculateGeospatialRisk(logs: List<VaultAccessLogEntity>): Double {
        if (logs.size < 2) return 0.0
        
        val locations = logs.filter { 
            it.locationLatitude != null && it.locationLongitude != null 
        }
        
        if (locations.size < 2) return 0.0
        
        var risk = 0.0
        
        // Check for impossible travel
        for (i in 0 until locations.size - 1) {
            val loc1 = locations[i]
            val loc2 = locations[i + 1]
            
            val distance = calculateDistance(
                loc1.locationLatitude!!, loc1.locationLongitude!!,
                loc2.locationLatitude!!, loc2.locationLongitude!!
            )
            
            val timeDiff = (loc1.timestamp.time - loc2.timestamp.time) / (1000.0 * 60.0 * 60.0) // hours
            
            if (timeDiff < 1.0 && distance > impossibleTravelThreshold) {
                risk += 30.0
            }
        }
        
        return risk.coerceAtMost(100.0)
    }
    
    private fun analyzeBehavior(logs: List<VaultAccessLogEntity>): Double {
        if (logs.isEmpty()) return 0.0
        
        var behaviorScore = 0.0
        
        // Check for rapid access
        if (logs.size > 10) {
            val recentLogs = logs.take(10)
            val timeWindow = recentLogs.first().timestamp.time - recentLogs.last().timestamp.time
            if (timeWindow < 60000) { // Less than 1 minute
                behaviorScore += 20.0
            }
        }
        
        // Check for unusual deletion patterns
        val deletionCount = logs.count { it.accessType == "deleted" }
        if (logs.isNotEmpty() && (deletionCount.toDouble() / logs.size) > 0.3) {
            behaviorScore += 25.0
        }
        
        return behaviorScore.coerceAtMost(100.0)
    }
    
    private fun calculateCombinedMLScore(
        threatScore: Double,
        geoRisk: Double,
        behaviorScore: Double
    ): Double {
        // Weighted average
        return (threatScore * 0.4 + geoRisk * 0.35 + behaviorScore * 0.25).coerceIn(0.0, 100.0)
    }
    
    private fun calculateDistance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ): Double {
        val earthRadius = 6371.0 // km
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2)
        val c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
        return earthRadius * c
    }
}
