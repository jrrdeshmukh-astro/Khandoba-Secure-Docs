package com.khandoba.securedocs.service

import android.util.Log
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.data.supabase.SupabaseService
import com.khandoba.securedocs.data.supabase.SupabaseAntiVault
import com.khandoba.securedocs.data.supabase.SupabaseThreatEvent
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonPrimitive
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

@Serializable
data class AutoUnlockPolicy(
    var unlockOnSessionNomination: Boolean = true,
    var unlockOnSubsetNomination: Boolean = true,
    var requireApproval: Boolean = false,
    var approvalUserIDs: List<UUID> = emptyList()
)

@Serializable
data class ThreatDetectionSettings(
    var detectContentDiscrepancies: Boolean = true,
    var detectMetadataMismatches: Boolean = true,
    var detectAccessPatternAnomalies: Boolean = true,
    var detectGeographicInconsistencies: Boolean = true,
    var detectEditHistoryDiscrepancies: Boolean = true,
    var minThreatSeverity: String = "medium" // "low", "medium", "high", "critical"
)

data class AntiVault(
    val id: UUID,
    val vaultID: UUID,
    val monitoredVaultID: UUID,
    val ownerID: UUID,
    var status: String = "locked", // "locked", "active", "archived"
    val autoUnlockPolicy: AutoUnlockPolicy = AutoUnlockPolicy(),
    val threatDetectionSettings: ThreatDetectionSettings = ThreatDetectionSettings(),
    val lastIntelReportID: UUID? = null,
    val createdAt: Date = Date(),
    var updatedAt: Date = Date(),
    var lastUnlockedAt: Date? = null
)

data class ThreatDetection(
    val id: String,
    val detectedAt: Date,
    val type: String,
    val severity: String, // "low", "medium", "high", "critical"
    val description: String,
    val vaultID: UUID? = null
)

class AntiVaultService(
    private val supabaseService: SupabaseService,
    private val currentUserID: UUID
) {
    private val _antiVaults = MutableStateFlow<List<AntiVault>>(emptyList())
    val antiVaults: StateFlow<List<AntiVault>> = _antiVaults.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _detectedThreats = MutableStateFlow<List<ThreatDetection>>(emptyList())
    val detectedThreats: StateFlow<List<ThreatDetection>> = _detectedThreats.asStateFlow()
    
    private val json = Json { ignoreUnknownKeys = true }
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
    
    suspend fun createAntiVault(
        monitoredVault: VaultEntity,
        ownerID: UUID,
        settings: ThreatDetectionSettings? = null
    ): AntiVault {
        Log.d("AntiVaultService", "Creating anti-vault for vault: ${monitoredVault.name}")
        
        val antiVaultID = UUID.randomUUID()
        
        // Check if anti-vault already exists
        val existingVault = try {
            supabaseService.fetchAll<SupabaseAntiVault>(
                "anti_vaults",
                filters = mapOf("monitored_vault_id" to monitoredVault.id.toString())
            ).firstOrNull()
        } catch (e: Exception) {
            null
        }
        
        val antiVault = if (existingVault != null) {
            // Update existing
            AntiVault(
                id = existingVault.id,
                vaultID = existingVault.vault_id,
                monitoredVaultID = existingVault.monitored_vault_id,
                ownerID = existingVault.owner_id,
                status = existingVault.status,
                autoUnlockPolicy = decodeAutoUnlockPolicy(existingVault.auto_unlock_policy),
                threatDetectionSettings = settings ?: decodeThreatDetectionSettings(existingVault.threat_detection_settings),
                lastIntelReportID = existingVault.last_intel_report_id,
                createdAt = existingVault.created_at,
                updatedAt = Date(),
                lastUnlockedAt = existingVault.last_unlocked_at
            )
        } else {
            // Create new
            AntiVault(
                id = antiVaultID,
                vaultID = monitoredVault.id,
                monitoredVaultID = monitoredVault.id,
                ownerID = ownerID,
                status = "locked",
                autoUnlockPolicy = AutoUnlockPolicy(),
                threatDetectionSettings = settings ?: ThreatDetectionSettings(),
                createdAt = Date(),
                updatedAt = Date()
            )
        }
        
        // Save to Supabase
        val supabaseAntiVault = SupabaseAntiVault(
            id = antiVault.id,
            vault_id = antiVault.vaultID,
            monitored_vault_id = antiVault.monitoredVaultID,
            owner_id = antiVault.ownerID,
            status = antiVault.status,
            auto_unlock_policy = encodeAutoUnlockPolicyToJson(antiVault.autoUnlockPolicy),
            threat_detection_settings = encodeThreatDetectionSettingsToJson(antiVault.threatDetectionSettings),
            last_intel_report_id = antiVault.lastIntelReportID,
            created_at = dateFormat.format(antiVault.createdAt),
            updated_at = dateFormat.format(antiVault.updatedAt),
            last_unlocked_at = antiVault.lastUnlockedAt?.let { dateFormat.format(it) }
        )
        
        try {
            if (existingVault != null) {
                supabaseService.update("anti_vaults", antiVault.id, supabaseAntiVault)
            } else {
                supabaseService.insert("anti_vaults", supabaseAntiVault)
            }
            
            // Update vault with anti-vault ID - fetch current vault first
            val currentVault = supabaseService.fetch<com.khandoba.securedocs.data.supabase.SupabaseVault>(
                "vaults",
                monitoredVault.id
            )
            val updatedVault = currentVault.copy(
                anti_vault_id = antiVault.id,
                is_anti_vault = false // The monitored vault is not the anti-vault itself
            )
            supabaseService.update("vaults", monitoredVault.id, updatedVault)
            
            Log.d("AntiVaultService", "✅ Anti-vault created/updated: ${antiVault.id}")
        } catch (e: Exception) {
            Log.e("AntiVaultService", "Error saving anti-vault", e)
            throw e
        }
        
        loadAntiVaults()
        return antiVault
    }
    
    suspend fun loadAntiVaults() {
        _isLoading.value = true
        try {
            val supabaseAntiVaults = supabaseService.fetchAll<SupabaseAntiVault>(
                "anti_vaults",
                filters = mapOf("owner_id" to currentUserID.toString())
            )
            
            _antiVaults.value = supabaseAntiVaults.map { convertFromSupabase(it) }
        } catch (e: Exception) {
            Log.e("AntiVaultService", "Error loading anti-vaults", e)
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun unlockAntiVault(antiVault: AntiVault, vaultID: UUID) {
        Log.d("AntiVaultService", "Unlocking anti-vault: ${antiVault.id}")
        
        val updatedAntiVault = antiVault.copy(
            status = "active",
            lastUnlockedAt = Date(),
            updatedAt = Date()
        )
        
        val supabaseAntiVault = SupabaseAntiVault(
            id = updatedAntiVault.id,
            vault_id = updatedAntiVault.vaultID,
            monitored_vault_id = updatedAntiVault.monitoredVaultID,
            owner_id = updatedAntiVault.ownerID,
            status = updatedAntiVault.status,
            auto_unlock_policy = encodeAutoUnlockPolicyToJson(updatedAntiVault.autoUnlockPolicy),
            threat_detection_settings = encodeThreatDetectionSettingsToJson(updatedAntiVault.threatDetectionSettings),
            last_intel_report_id = updatedAntiVault.lastIntelReportID,
            created_at = dateFormat.format(updatedAntiVault.createdAt),
            updated_at = dateFormat.format(updatedAntiVault.updatedAt),
            last_unlocked_at = updatedAntiVault.lastUnlockedAt?.let { dateFormat.format(it) }
        )
        
        try {
            supabaseService.update("anti_vaults", updatedAntiVault.id, supabaseAntiVault)
            loadAntiVaults()
        } catch (e: Exception) {
            Log.e("AntiVaultService", "Error unlocking anti-vault", e)
            throw e
        }
    }
    
    suspend fun loadThreatsForAntiVault(antiVaultID: UUID) {
        try {
            // Load the anti-vault to get monitored vault ID
            val antiVault = _antiVaults.value.firstOrNull { it.id == antiVaultID }
            if (antiVault == null) {
                _detectedThreats.value = emptyList()
                return
            }

            // Load threat events from database for the monitored vault
            // Note: fetchAll doesn't support IS NULL filters, so we filter in code
            val allThreatEvents = supabaseService.fetchAll<SupabaseThreatEvent>(
                table = "threat_events",
                filters = mapOf("vault_id" to antiVault.monitoredVaultID.toString()),
                orderBy = "detected_at",
                ascending = false,
                limit = 100 // Get more than needed, then filter
            )
            
            // Filter for unresolved threats only
            val threatEvents = allThreatEvents.filter { it.resolved_at == null }

            val threats = threatEvents.map { evt ->
                ThreatDetection(
                    id = evt.id.toString(),
                    detectedAt = parseDate(evt.detected_at) ?: Date(),
                    type = evt.event_type,
                    severity = evt.severity,
                    description = evt.description ?: evt.event_type,
                    vaultID = evt.vault_id
                )
            }

            _detectedThreats.value = threats
        } catch (e: Exception) {
            Log.e("AntiVaultService", "Error loading threats", e)
            _detectedThreats.value = emptyList()
        }
    }
    
    private fun convertFromSupabase(supabase: SupabaseAntiVault): AntiVault {
        return AntiVault(
            id = supabase.id,
            vaultID = supabase.vault_id,
            monitoredVaultID = supabase.monitored_vault_id,
            ownerID = supabase.owner_id,
            status = supabase.status,
            autoUnlockPolicy = decodeAutoUnlockPolicyFromJson(supabase.auto_unlock_policy),
            threatDetectionSettings = decodeThreatDetectionSettingsFromJson(supabase.threat_detection_settings),
            lastIntelReportID = supabase.last_intel_report_id,
            createdAt = parseDate(supabase.created_at) ?: Date(),
            updatedAt = parseDate(supabase.updated_at) ?: Date(),
            lastUnlockedAt = supabase.last_unlocked_at?.let { parseDate(it) }
        )
    }
    
    private fun parseDate(dateString: String?): Date? {
        if (dateString == null) return null
        return try {
            dateFormat.parse(dateString)
        } catch (e: Exception) {
            try {
                // Try alternative format without milliseconds
                val altFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
                altFormat.parse(dateString)
            } catch (e2: Exception) {
                Log.e("AntiVaultService", "Error parsing date: $dateString", e2)
                null
            }
        }
    }
    
    private fun encodeAutoUnlockPolicyToJson(policy: AutoUnlockPolicy): Map<String, JsonElement>? {
        return try {
            val jsonString = json.encodeToString(
                AutoUnlockPolicy.serializer(),
                policy
            )
            json.parseToJsonElement(jsonString).jsonObject
        } catch (e: Exception) {
            // Fallback to manual encoding
            mapOf(
                "unlockOnSessionNomination" to Json.parseToJsonElement(policy.unlockOnSessionNomination.toString()),
                "unlockOnSubsetNomination" to Json.parseToJsonElement(policy.unlockOnSubsetNomination.toString()),
                "requireApproval" to Json.parseToJsonElement(policy.requireApproval.toString()),
                "approvalUserIDs" to Json.parseToJsonElement(policy.approvalUserIDs.map { it.toString() }.toString())
            )
        }
    }
    
    private fun decodeAutoUnlockPolicyFromJson(data: Map<String, JsonElement>?): AutoUnlockPolicy {
        if (data == null) return AutoUnlockPolicy()
        return try {
            val jsonString = Json.encodeToString(JsonObject(data))
            json.decodeFromString(AutoUnlockPolicy.serializer(), jsonString)
        } catch (e: Exception) {
            // Fallback to manual decoding
            AutoUnlockPolicy(
                unlockOnSessionNomination = data["unlockOnSessionNomination"]?.jsonPrimitive?.content?.toBoolean() ?: true,
                unlockOnSubsetNomination = data["unlockOnSubsetNomination"]?.jsonPrimitive?.content?.toBoolean() ?: true,
                requireApproval = data["requireApproval"]?.jsonPrimitive?.content?.toBoolean() ?: false,
                approvalUserIDs = (data["approvalUserIDs"]?.jsonArray?.mapNotNull { 
                    try { UUID.fromString(it.jsonPrimitive.content) } catch (e: Exception) { null }
                }) ?: emptyList()
            )
        }
    }
    
    private fun encodeThreatDetectionSettingsToJson(settings: ThreatDetectionSettings): Map<String, JsonElement>? {
        return try {
            val jsonString = json.encodeToString(
                ThreatDetectionSettings.serializer(),
                settings
            )
            json.parseToJsonElement(jsonString).jsonObject
        } catch (e: Exception) {
            // Fallback to manual encoding
            mapOf(
                "detectContentDiscrepancies" to Json.parseToJsonElement(settings.detectContentDiscrepancies.toString()),
                "detectMetadataMismatches" to Json.parseToJsonElement(settings.detectMetadataMismatches.toString()),
                "detectAccessPatternAnomalies" to Json.parseToJsonElement(settings.detectAccessPatternAnomalies.toString()),
                "detectGeographicInconsistencies" to Json.parseToJsonElement(settings.detectGeographicInconsistencies.toString()),
                "detectEditHistoryDiscrepancies" to Json.parseToJsonElement(settings.detectEditHistoryDiscrepancies.toString()),
                "minThreatSeverity" to Json.parseToJsonElement(settings.minThreatSeverity)
            )
        }
    }
    
    private fun decodeThreatDetectionSettingsFromJson(data: Map<String, JsonElement>?): ThreatDetectionSettings {
        if (data == null) return ThreatDetectionSettings()
        return try {
            val jsonString = Json.encodeToString(JsonObject(data))
            json.decodeFromString(ThreatDetectionSettings.serializer(), jsonString)
        } catch (e: Exception) {
            // Fallback to manual decoding
            ThreatDetectionSettings(
                detectContentDiscrepancies = data["detectContentDiscrepancies"]?.jsonPrimitive?.content?.toBoolean() ?: true,
                detectMetadataMismatches = data["detectMetadataMismatches"]?.jsonPrimitive?.content?.toBoolean() ?: true,
                detectAccessPatternAnomalies = data["detectAccessPatternAnomalies"]?.jsonPrimitive?.content?.toBoolean() ?: true,
                detectGeographicInconsistencies = data["detectGeographicInconsistencies"]?.jsonPrimitive?.content?.toBoolean() ?: true,
                detectEditHistoryDiscrepancies = data["detectEditHistoryDiscrepancies"]?.jsonPrimitive?.content?.toBoolean() ?: true,
                minThreatSeverity = data["minThreatSeverity"]?.jsonPrimitive?.content ?: "medium"
            )
        }
    }
}
