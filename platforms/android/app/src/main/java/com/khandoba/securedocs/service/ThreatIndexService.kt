package com.khandoba.securedocs.service

import android.util.Log
import com.khandoba.securedocs.data.supabase.SupabaseService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.*

/**
 * Service for managing real-time threat index updates and history
 */
class ThreatIndexService(
    private val supabaseService: SupabaseService
) {
    // Map of vault ID to threat index history
    private val _threatIndexHistory = MutableStateFlow<Map<UUID, List<ThreatIndexDataPoint>>>(emptyMap())
    val threatIndexHistory: StateFlow<Map<UUID, List<ThreatIndexDataPoint>>> = _threatIndexHistory.asStateFlow()
    
    // Current threat indices by vault ID
    private val _currentThreatIndices = MutableStateFlow<Map<UUID, Double>>(emptyMap())
    val currentThreatIndices: StateFlow<Map<UUID, Double>> = _currentThreatIndices.asStateFlow()
    
    /**
     * Initialize threat index monitoring for a vault
     * Sets up real-time subscription and loads historical data
     */
    suspend fun initializeThreatIndexMonitoring(vaultId: UUID) {
        try {
            // Load initial threat index from vault
            val vault = supabaseService.fetch<com.khandoba.securedocs.data.supabase.SupabaseVault>(
                table = "vaults",
                id = vaultId
            )
            
            vault.threat_index?.let { index ->
                updateThreatIndex(vaultId, index, vault.threat_level ?: "low")
            }
            
            Log.d("ThreatIndexService", "Initialized threat index monitoring for vault $vaultId")
        } catch (e: Exception) {
            Log.e("ThreatIndexService", "Failed to initialize threat index monitoring: ${e.message}")
        }
    }
    
    /**
     * Update threat index for a vault (called from real-time subscription)
     */
    fun updateThreatIndex(vaultId: UUID, threatIndex: Double, threatLevel: String) {
        val timestamp = Date()
        val dataPoint = ThreatIndexDataPoint(
            timestamp = timestamp,
            threatIndex = threatIndex,
            threatLevel = threatLevel
        )
        
        // Update current threat index
        _currentThreatIndices.value = _currentThreatIndices.value.toMutableMap().apply {
            put(vaultId, threatIndex)
        }
        
        // Add to history (keep last 100 data points per vault)
        val currentHistory = _threatIndexHistory.value.getOrDefault(vaultId, emptyList())
        val updatedHistory = (currentHistory + dataPoint).takeLast(100)
        
        _threatIndexHistory.value = _threatIndexHistory.value.toMutableMap().apply {
            put(vaultId, updatedHistory)
        }
        
        Log.d("ThreatIndexService", "Updated threat index for vault $vaultId: $threatIndex ($threatLevel)")
    }
    
    /**
     * Get threat index history for a specific vault
     */
    fun getThreatIndexHistory(vaultId: UUID): List<ThreatIndexDataPoint> {
        return _threatIndexHistory.value.getOrDefault(vaultId, emptyList())
    }
    
    /**
     * Get current threat index for a specific vault
     */
    fun getCurrentThreatIndex(vaultId: UUID): Double? {
        return _currentThreatIndices.value[vaultId]
    }
}

data class ThreatIndexDataPoint(
    val timestamp: Date,
    val threatIndex: Double,
    val threatLevel: String // "low", "medium", "high", "critical"
)
