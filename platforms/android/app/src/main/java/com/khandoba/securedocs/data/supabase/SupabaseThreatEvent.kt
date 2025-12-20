package com.khandoba.securedocs.data.supabase

import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class SupabaseThreatEvent(
    val id: UUID,
    val vault_id: UUID? = null,
    val user_id: UUID? = null,
    val event_type: String, // 'access_anomaly', 'transfer_request', 'ownership_change', 'deletion_spike', etc.
    val severity: String = "low", // 'low', 'medium', 'high', 'critical'
    val description: String? = null,
    val metadata: Map<String, kotlinx.serialization.json.JsonElement>? = null, // JSONB
    val detected_at: String, // ISO 8601 date string
    val resolved_at: String? = null,
    val resolved_by_user_id: UUID? = null, // Database column name is resolved_by_user_id
    val threat_score: Double = 0.0, // Threat score (0-100)
    val created_at: String
    // Note: Database schema doesn't have updated_at column for threat_events
)
