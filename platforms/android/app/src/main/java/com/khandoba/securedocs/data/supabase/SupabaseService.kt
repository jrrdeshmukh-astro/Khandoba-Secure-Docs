package com.khandoba.securedocs.data.supabase

import android.util.Log
import com.khandoba.securedocs.config.AppConfig
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.realtime.realtime
import io.github.jan.supabase.storage.storage
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.providers.oauth.Google
import io.github.jan.supabase.auth.user.UserInfo
import io.github.jan.supabase.auth.session.Session
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.Serializable
import java.util.UUID

@Serializable
data class SupabaseUser(
    val id: UUID,
    val google_user_id: String, // Android equivalent of apple_user_id
    val full_name: String,
    val email: String? = null,
    val profile_picture_url: String? = null,
    val created_at: String, // ISO 8601 date string
    val last_active_at: String,
    val is_active: Boolean = true,
    val is_premium_subscriber: Boolean = false,
    val subscription_expiry_date: String? = null,
    val updated_at: String
)

@Serializable
data class SupabaseVault(
    val id: UUID,
    val name: String,
    val vault_description: String? = null,
    val owner_id: UUID,
    val created_at: String,
    val last_accessed_at: String? = null,
    val status: String = "locked",
    val key_type: String = "single",
    val vault_type: String = "both",
    val is_system_vault: Boolean = false,
    val encryption_key_data: String? = null, // Base64 encoded
    val is_encrypted: Boolean = true,
    val is_zero_knowledge: Boolean = true,
    val relationship_officer_id: UUID? = null,
    val is_anti_vault: Boolean = false,
    val monitored_vault_id: UUID? = null,
    val anti_vault_id: UUID? = null,
    val threat_index: Double = 0.0,
    val threat_level: String = "low", // "low", "medium", "high", "critical"
    val last_threat_assessment_at: String? = null,
    val updated_at: String
)

@Serializable
data class SupabaseVaultTransferRequest(
    val id: String,
    val vault_id: String,
    val requested_by_user_id: String,
    val requested_at: String,
    val status: String,
    val reason: String? = null,
    val new_owner_id: String? = null,
    val new_owner_name: String? = null,
    val new_owner_phone: String? = null,
    val new_owner_email: String? = null,
    val transfer_token: String,
    val approved_at: String? = null,
    val approver_id: String? = null,
    val ml_score: Double? = null,
    val ml_recommendation: String? = null,
    val threat_index: Double? = null,
    val completed_at: String? = null,
    val created_at: String,
    val updated_at: String
)

@Serializable
data class SupabaseAntiVault(
    val id: UUID,
    val vault_id: UUID,
    val monitored_vault_id: UUID,
    val owner_id: UUID,
    val status: String = "locked", // "locked", "active", "archived"
    val auto_unlock_policy: Map<String, kotlinx.serialization.json.JsonElement>? = null, // JSONB
    val threat_detection_settings: Map<String, kotlinx.serialization.json.JsonElement>? = null, // JSONB
    val last_intel_report_id: UUID? = null,
    val created_at: String,
    val updated_at: String,
    val last_unlocked_at: String? = null
)

@Serializable
data class SupabaseDocument(
    val id: UUID,
    val vault_id: UUID,
    val name: String,
    val file_extension: String? = null,
    val mime_type: String? = null,
    val file_size: Long = 0,
    val storage_path: String? = null,
    val created_at: String,
    val uploaded_at: String,
    val last_modified_at: String? = null,
    val encryption_key_data: String? = null, // Base64 encoded
    val is_encrypted: Boolean = true,
    val document_type: String = "other",
    val source_sink_type: String? = null,
    val is_archived: Boolean = false,
    val is_redacted: Boolean = false,
    val status: String = "active",
    val extracted_text: String? = null,
    val ai_tags: List<String> = emptyList(),
    val file_hash: String? = null,
    val metadata: Map<String, String>? = null, // JSONB
    val author: String? = null,
    val camera_info: String? = null,
    val device_id: String? = null,
    val uploaded_by_user_id: UUID? = null,
    val updated_at: String
)

class SupabaseService {
    private var client: SupabaseClient? = null
    
    private val _isConnected = MutableStateFlow(false)
    val isConnected: StateFlow<Boolean> = _isConnected.asStateFlow()
    
    private val _currentSession = MutableStateFlow<Session?>(null)
    val currentSession: StateFlow<Session?> = _currentSession.asStateFlow()
    
    private val _error = MutableStateFlow<Throwable?>(null)
    val error: StateFlow<Throwable?> = _error.asStateFlow()
    
    // Real-time channel subscriptions
    private val realtimeChannels = mutableMapOf<String, io.github.jan.supabase.realtime.channel.RealtimeChannel>()
    
    suspend fun configure() {
        try {
            client = createSupabaseClient(
                supabaseUrl = AppConfig.SUPABASE_URL,
                supabaseKey = AppConfig.SUPABASE_ANON_KEY
            ) {
                install(io.github.jan.supabase.postgrest.Postgrest)
                install(io.github.jan.supabase.realtime.Realtime)
                install(io.github.jan.supabase.storage.Storage)
                install(io.github.jan.supabase.auth.Auth)
            }
            
            // Test connection
            try {
                client?.from("users")
                    ?.select(columns = Columns.ALL) {
                        limit = 0
                    }
                
                _isConnected.value = true
                _currentSession.value = client?.auth?.currentSessionOrNull()
                Log.d("SupabaseService", "✅ Supabase client initialized and connected")
                Log.d("SupabaseService", "   URL: ${AppConfig.SUPABASE_URL}")
            } catch (e: Exception) {
                // Auth errors are expected when not signed in - connection is still OK
                _isConnected.value = true
                _currentSession.value = client?.auth?.currentSessionOrNull()
                Log.d("SupabaseService", "✅ Supabase client initialized")
                Log.d("SupabaseService", "   Note: No active session (user not signed in)")
            }
        } catch (e: Exception) {
            _isConnected.value = false
            _error.value = e
            Log.e("SupabaseService", "❌ Supabase initialization failed: ${e.message}")
        }
    }
    
    // MARK: - Authentication
    
    suspend fun signInWithGoogle(idToken: String): Session {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        
        return try {
            // Sign in with Google OAuth
            val session = client.auth.signInWith(Google) {
                this.idToken = idToken
            }
            
            _currentSession.value = session
            _isConnected.value = true
            
            if (AppConfig.ENABLE_REALTIME) {
                setupRealtimeSubscriptions()
            }
            
            Log.d("SupabaseService", "✅ Signed in with Google")
            session
        } catch (e: Exception) {
            Log.e("SupabaseService", "Sign in failed: ${e.message}")
            _error.value = e
            throw e
        }
    }
    
    suspend fun signOut() {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        
        try {
            client.auth.signOut()
            _currentSession.value = null
            _isConnected.value = false
            unsubscribeAll()
        } catch (e: Exception) {
            _error.value = e
            throw e
        }
    }
    
    suspend fun getCurrentUser(): UserInfo? {
        val client = client ?: return null
        return try {
            client.auth.currentUserOrNull()
        } catch (e: Exception) {
            Log.e("SupabaseService", "Error getting current user: ${e.message}")
            null
        }
    }
    
    fun currentSessionOrNull(): Session? {
        return _currentSession.value
    }
    
    // MARK: - Database Queries
    
    suspend inline fun <reified T> fetch(table: String, id: UUID): T {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        return client.from(table)
            .select {
                filter {
                    eq("id", id.toString())
                }
            }
            .decodeSingle<T>()
    }
    
    suspend inline fun <reified T> fetchAll(
        table: String,
        filters: Map<String, Any>? = null,
        limit: Int? = null,
        orderBy: String? = null,
        ascending: Boolean = true
    ): List<T> {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        
        // Build query with filters
        val query = if (filters != null && filters.isNotEmpty()) {
            client.from(table).select {
                filter {
                    filters.forEach { (key, value) ->
                        when (value) {
                            is String -> eq(key, value)
                            is UUID -> eq(key, value.toString())
                            is Int -> eq(key, value)
                            is Boolean -> eq(key, value)
                            else -> eq(key, value.toString())
                        }
                    }
                }
            }
        } else {
            client.from(table).select()
        }
        
        // Apply ordering
        val orderedQuery = if (orderBy != null) {
            query.order(orderBy, ascending = ascending)
        } else if (limit != null) {
            // Default order for limit
            query.order("created_at", ascending = false)
        } else {
            query
        }
        
        // Apply limit
        val finalQuery = if (limit != null) {
            orderedQuery.limit(limit)
        } else {
            orderedQuery
        }
        
        return finalQuery.decodeList<T>()
    }
    
    suspend inline fun <reified T> insert(table: String, values: T): T {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        return client.from(table)
            .insert(values) {
                select(Columns.ALL)
            }
            .decodeSingle<T>()
    }
    
    suspend inline fun <reified T> update(table: String, id: UUID, values: T): T {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        return client.from(table)
            .update(values) {
                filter {
                    eq("id", id.toString())
                }
                select(Columns.ALL)
            }
            .decodeSingle<T>()
    }
    
    suspend fun delete(table: String, id: UUID) {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        client.from(table)
            .delete {
                filter {
                    eq("id", id.toString())
                }
            }
    }
    
    // MARK: - Storage
    
    suspend fun uploadFile(bucket: String, path: String, data: ByteArray): String {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        client.storage.from(bucket).upload(path, data)
        return path
    }
    
    suspend fun downloadFile(bucket: String, path: String): ByteArray {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        return client.storage.from(bucket).downloadAuthenticated(path)
    }
    
    suspend fun deleteFile(bucket: String, path: String) {
        val client = client ?: throw IllegalStateException("Supabase client not initialized")
        client.storage.from(bucket).delete(path)
    }
    
    // MARK: - Real-time
    
    private fun setupRealtimeSubscriptions() {
        val client = client ?: return
        
        try {
            // Subscribe to vaults channel - specifically for threat_index updates
            val vaultsChannel = client.realtime.createChannel("vaults") {
                on("postgres_changes") { event ->
                    android.util.Log.d("SupabaseService", "Vault change received: ${event.type}")
                    
                    // Extract threat_index from update events
                    if (event.type == "UPDATE") {
                        try {
                            val payload = event.payload as? Map<*, *>
                            val newRecord = payload?.get("new") as? Map<*, *>
                            val threatIndex = newRecord?.get("threat_index") as? Number
                            val threatLevel = newRecord?.get("threat_level") as? String
                            val vaultId = newRecord?.get("id") as? String
                            
                            if (threatIndex != null && vaultId != null) {
                                android.util.Log.d("SupabaseService", "Threat index updated for vault $vaultId: $threatIndex ($threatLevel)")
                                // TODO: Emit to a Flow or callback for UI updates
                            }
                        } catch (e: Exception) {
                            android.util.Log.e("SupabaseService", "Error parsing vault update: ${e.message}")
                        }
                    }
                }
            }
            // Subscribe to vaults table changes, filtering for threat_index column updates
            vaultsChannel.subscribe()
            realtimeChannels["vaults"] = vaultsChannel
            
            // Subscribe to documents channel
            val documentsChannel = client.realtime.createChannel("documents") {
                on("postgres_changes") { event ->
                    android.util.Log.d("SupabaseService", "Document change received: ${event.type}")
                    // Handle document changes (INSERT, UPDATE, DELETE)
                }
            }
            documentsChannel.subscribe()
            realtimeChannels["documents"] = documentsChannel
            
            // Subscribe to nominees channel
            val nomineesChannel = client.realtime.createChannel("nominees") {
                on("postgres_changes") { event ->
                    android.util.Log.d("SupabaseService", "Nominee change received: ${event.type}")
                }
            }
            nomineesChannel.subscribe()
            realtimeChannels["nominees"] = nomineesChannel
            
            // Subscribe to chat_messages channel
            val chatChannel = client.realtime.createChannel("chat_messages") {
                on("postgres_changes") { event ->
                    android.util.Log.d("SupabaseService", "Chat message received: ${event.type}")
                }
            }
            chatChannel.subscribe()
            realtimeChannels["chat_messages"] = chatChannel
            
            // Subscribe to vault_sessions channel
            val sessionsChannel = client.realtime.createChannel("vault_sessions") {
                on("postgres_changes") { event ->
                    android.util.Log.d("SupabaseService", "Vault session change received: ${event.type}")
                }
            }
            sessionsChannel.subscribe()
            realtimeChannels["vault_sessions"] = sessionsChannel
            
            android.util.Log.d("SupabaseService", "✅ Real-time subscriptions established for ${realtimeChannels.size} channels")
        } catch (e: Exception) {
            android.util.Log.e("SupabaseService", "❌ Failed to set up real-time subscriptions: ${e.message}")
        }
    }
    
    private fun unsubscribeAll() {
        try {
            realtimeChannels.values.forEach { channel ->
                try {
                    channel.unsubscribe()
                } catch (e: Exception) {
                    android.util.Log.e("SupabaseService", "Error unsubscribing from channel: ${e.message}")
                }
            }
            realtimeChannels.clear()
            android.util.Log.d("SupabaseService", "✅ Unsubscribed from all real-time channels")
        } catch (e: Exception) {
            android.util.Log.e("SupabaseService", "❌ Error unsubscribing from channels: ${e.message}")
        }
    }
}

