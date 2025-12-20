package com.khandoba.securedocs.service

import android.util.Log
import com.khandoba.securedocs.data.entity.VaultAccessLogEntity
import com.khandoba.securedocs.data.entity.VaultEntity
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Calendar
import java.util.Date

enum class ThreatLevel {
    Low,
    Medium,
    High
}

data class ThreatEvent(
    val id: String,
    val timestamp: Date,
    val type: String,
    val severity: ThreatLevel,
    val description: String
)

class ThreatMonitoringService {
    private val _threatLevel = MutableStateFlow<ThreatLevel>(ThreatLevel.Low)
    val threatLevel: StateFlow<ThreatLevel> = _threatLevel.asStateFlow()
    
    private val _anomalyScore = MutableStateFlow(0.0)
    val anomalyScore: StateFlow<Double> = _anomalyScore.asStateFlow()
    
    private val _recentThreats = MutableStateFlow<List<ThreatEvent>>(emptyList())
    val recentThreats: StateFlow<List<ThreatEvent>> = _recentThreats.asStateFlow()
    
    suspend fun analyzeThreatLevel(
        vault: VaultEntity,
        accessLogs: List<VaultAccessLogEntity>
    ): ThreatLevel {
        val sortedLogs = accessLogs.sortedByDescending { it.timestamp }
        
        var suspiciousActivities = 0
        var anomalyPoints = 0.0
        
        // Check for rapid successive access (brute force indicator)
        if (sortedLogs.size > 10) {
            val recentLogs = sortedLogs.take(10)
            val timeWindow = recentLogs.first().timestamp.time - recentLogs.last().timestamp.time
            
            if (timeWindow < 60000) { // 10 accesses in less than 1 minute
                suspiciousActivities++
                anomalyPoints += 20.0
            }
        }
        
        // Check for unusual time patterns (night access)
        val nightAccessCount = sortedLogs.count { isNightTime(it.timestamp) }
        if (sortedLogs.isNotEmpty() && (nightAccessCount.toDouble() / sortedLogs.size) > 0.5) {
            anomalyPoints += 15.0
        }
        
        // Check for geographic anomalies
        if (hasGeographicAnomalies(sortedLogs)) {
            suspiciousActivities++
            anomalyPoints += 25.0
        }
        
        // Check for unusual deletion patterns
        val deletionCount = sortedLogs.count { it.accessType == "deleted" }
        if (sortedLogs.isNotEmpty() && (deletionCount.toDouble() / sortedLogs.size) > 0.3) {
            anomalyPoints += 30.0
        }
        
        _anomalyScore.value = anomalyPoints
        
        // Determine threat level
        val level = when {
            anomalyPoints > 50 || suspiciousActivities > 2 -> ThreatLevel.High
            anomalyPoints > 25 || suspiciousActivities > 0 -> ThreatLevel.Medium
            else -> ThreatLevel.Low
        }
        
        _threatLevel.value = level
        return level
    }
    
    private fun isNightTime(timestamp: Date): Boolean {
        val calendar = Calendar.getInstance().apply {
            time = timestamp
        }
        val hour = calendar.get(Calendar.HOUR_OF_DAY)
        return hour < 6 || hour > 22 // Night time: 10 PM - 6 AM
    }
    
    private fun hasGeographicAnomalies(logs: List<VaultAccessLogEntity>): Boolean {
        if (logs.size < 2) return false
        
        val locations = logs.filter { 
            it.locationLatitude != null && it.locationLongitude != null 
        }
        
        if (locations.size < 2) return false
        
        // Check for impossible travel (large distance in short time)
        for (i in 0 until locations.size - 1) {
            val loc1 = locations[i]
            val loc2 = locations[i + 1]
            
            val distance = calculateDistance(
                loc1.locationLatitude!!, loc1.locationLongitude!!,
                loc2.locationLatitude!!, loc2.locationLongitude!!
            )
            
            val timeDiff = (loc1.timestamp.time - loc2.timestamp.time) / (1000 * 60 * 60) // hours
            
            // Impossible travel: >500km in <1 hour
            if (timeDiff < 1.0 && distance > 500.0) {
                return true
            }
        }
        
        return false
    }
    
    private fun calculateDistance(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ): Double {
        // Haversine formula
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
