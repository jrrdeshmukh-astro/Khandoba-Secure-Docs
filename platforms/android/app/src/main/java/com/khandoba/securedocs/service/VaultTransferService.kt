package com.khandoba.securedocs.service

import android.util.Log
import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.data.entity.VaultTransferRequestEntity
import com.khandoba.securedocs.data.repository.VaultRepository
import com.khandoba.securedocs.data.supabase.SupabaseService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date
import java.util.UUID

class VaultTransferService(
    private val vaultRepository: VaultRepository,
    private val supabaseService: SupabaseService?,
    private val threatMonitoringService: ThreatMonitoringService,
    private val mlThreatAnalysisService: MLThreatAnalysisService
) {
    private val _pendingTransfers = MutableStateFlow<List<VaultTransferRequestEntity>>(emptyList())
    val pendingTransfers: StateFlow<List<VaultTransferRequestEntity>> = _pendingTransfers.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private var currentUserID: UUID? = null
    
    fun configure(userID: UUID?) {
        this.currentUserID = userID
    }
    
    suspend fun requestOwnershipTransfer(
        vault: VaultEntity,
        newOwnerEmail: String? = null,
        newOwnerPhone: String? = null,
        newOwnerName: String? = null,
        reason: String? = null
    ): Result<VaultTransferRequestEntity> {
        return try {
            // Perform ML threat assessment before creating request
            val threatAssessment = assessTransferRequestThreat(vault, newOwnerEmail, reason)
            
            val transferRequest = VaultTransferRequestEntity(
                id = UUID.randomUUID(),
                vaultId = vault.id,
                requestedByUserID = currentUserID,
                newOwnerEmail = newOwnerEmail,
                newOwnerPhone = newOwnerPhone,
                newOwnerName = newOwnerName,
                reason = reason,
                status = "pending",
                requestedAt = Date(),
                transferToken = UUID.randomUUID().toString(),
                mlScore = threatAssessment.threatScore,
                mlRecommendation = threatAssessment.recommendation,
                threatIndex = threatAssessment.threatIndex
            )
            
            if (AppConfig.USE_SUPABASE && supabaseService != null) {
                try {
                    // Insert to Supabase with ML threat assessment
                    val supabaseData = com.khandoba.securedocs.data.supabase.SupabaseVaultTransferRequest(
                        id = transferRequest.id.toString(),
                        vault_id = transferRequest.vaultId?.toString() ?: "",
                        requested_by_user_id = transferRequest.requestedByUserID?.toString() ?: "",
                        requested_at = java.time.Instant.ofEpochMilli(transferRequest.requestedAt.time).toString(),
                        status = transferRequest.status,
                        reason = transferRequest.reason,
                        new_owner_id = transferRequest.newOwnerID?.toString(),
                        new_owner_name = transferRequest.newOwnerName,
                        new_owner_phone = transferRequest.newOwnerPhone,
                        new_owner_email = transferRequest.newOwnerEmail,
                        transfer_token = transferRequest.transferToken,
                        approved_at = transferRequest.approvedAt?.let { java.time.Instant.ofEpochMilli(it.time).toString() },
                        approver_id = transferRequest.approverID?.toString(),
                        ml_score = transferRequest.mlScore,
                        ml_recommendation = transferRequest.mlRecommendation,
                        threat_index = transferRequest.threatIndex,
                        completed_at = null,
                        created_at = java.time.Instant.ofEpochMilli(transferRequest.requestedAt.time).toString(),
                        updated_at = java.time.Instant.ofEpochMilli(transferRequest.requestedAt.time).toString()
                    )
                    supabaseService.insert("vault_transfer_requests", supabaseData)
                    
                    // Create threat event if threat index is high
                    if (threatAssessment.threatIndex >= 50.0) {
                        createThreatEvent(
                            vaultId = vault.id,
                            eventType = "transfer_request",
                            severity = if (threatAssessment.threatIndex >= 70) "high" else "medium",
                            threatScore = threatAssessment.threatIndex,
                            description = "High-threat ownership transfer request detected"
                        )
                    }
                    
                    Log.d("VaultTransferService", "✅ Transfer request created with ML assessment")
                    Log.d("VaultTransferService", "   Threat Index: ${threatAssessment.threatIndex}")
                    Log.d("VaultTransferService", "   ML Recommendation: ${threatAssessment.recommendation}")
                } catch (e: Exception) {
                    Log.e("VaultTransferService", "Error inserting transfer request: ${e.message}")
                    return Result.failure(e)
                }
            }
            
            Log.d("VaultTransferService", "✅ Transfer request created: ${transferRequest.id}")
            Log.d("VaultTransferService", "   Transfer Token: ${transferRequest.transferToken}")
            Result.success(transferRequest)
        } catch (e: Exception) {
            Log.e("VaultTransferService", "Error creating transfer request: ${e.message}")
            Result.failure(e)
        }
    }
    
    suspend fun acceptOwnershipTransfer(
        transferToken: String
    ): Result<VaultEntity> {
        return try {
            if (!AppConfig.USE_SUPABASE || supabaseService == null) {
                return Result.failure(Exception("Supabase not configured"))
            }
            
            // Find transfer request by token
            val requests = supabaseService.fetchAll<com.khandoba.securedocs.data.supabase.SupabaseVaultTransferRequest>(
                table = "vault_transfer_requests",
                filters = mapOf("transfer_token" to transferToken)
            )
            
            val request = requests.firstOrNull()
                ?: return Result.failure(Exception("Transfer request not found"))
            
            if (request.status != "pending") {
                return Result.failure(Exception("Transfer request is no longer pending"))
            }
            
            // Get vault
            val vaultId = UUID.fromString(request.vault_id)
            val vault = vaultRepository.getVaultById(vaultId)
                ?: return Result.failure(Exception("Vault not found"))
            
            // Update vault ownership (this would need to be implemented in VaultRepository)
            // For now, we'll update the transfer request status
            val updateData = com.khandoba.securedocs.data.supabase.SupabaseVaultTransferRequest(
                id = request.id,
                vault_id = request.vault_id,
                requested_by_user_id = request.requested_by_user_id,
                requested_at = request.requested_at,
                status = "completed",
                reason = request.reason,
                new_owner_id = request.new_owner_id,
                new_owner_name = request.new_owner_name,
                new_owner_phone = request.new_owner_phone,
                new_owner_email = request.new_owner_email,
                transfer_token = request.transfer_token,
                approved_at = request.approved_at,
                approver_id = request.approver_id,
                ml_score = request.ml_score,
                ml_recommendation = request.ml_recommendation,
                threat_index = request.threat_index,
                completed_at = java.time.Instant.now().toString(),
                created_at = request.created_at,
                updated_at = java.time.Instant.now().toString()
            )
            supabaseService.update("vault_transfer_requests", UUID.fromString(request.id), updateData)
            
            // Create threat event for ownership change
            createThreatEvent(
                vaultId = vault.id,
                eventType = "ownership_change",
                severity = "medium",
                threatScore = request.threatIndex ?: 0.0,
                description = "Vault ownership transferred"
            )
            
            Result.success(vault)
        } catch (e: Exception) {
            Log.e("VaultTransferService", "Error accepting transfer: ${e.message}")
            Result.failure(e)
        }
    }
    
    suspend fun loadPendingTransfers(): List<VaultTransferRequestEntity> {
        _isLoading.value = true
        try {
            if (AppConfig.USE_SUPABASE && supabaseService != null) {
                val supabaseRequests = supabaseService.fetchAll<com.khandoba.securedocs.data.supabase.SupabaseVaultTransferRequest>(
                    table = "vault_transfer_requests",
                    filters = mapOf(
                        "requested_by_user_id" to (currentUserID?.toString() ?: ""),
                        "status" to "pending"
                    )
                )
                val requests = supabaseRequests.map { convertFromSupabase(it) }
                _pendingTransfers.value = requests
                return requests
            }
            return emptyList()
        } catch (e: Exception) {
            Log.e("VaultTransferService", "Error loading pending transfers: ${e.message}")
            return emptyList()
        } finally {
            _isLoading.value = false
        }
    }
    
    // ML Threat Assessment for Transfer Requests
    private suspend fun assessTransferRequestThreat(
        vault: VaultEntity,
        newOwnerEmail: String?,
        reason: String?
    ): ThreatAssessment {
        var threatScore = 0.0
        var recommendation = "approve"
        
        // 1. Check vault's current threat level
        val vaultThreatLevel = threatMonitoringService.analyzeThreatLevel(vault, emptyList())
        when (vaultThreatLevel) {
            ThreatLevel.High -> threatScore += 30.0
            ThreatLevel.Medium -> threatScore += 15.0
            else -> {}
        }
        
        // 2. Check for multiple recent transfer requests
        val recentRequests = loadRecentTransferRequests(vault.id, days = 7)
        if (recentRequests.size > 3) {
            threatScore += 20.0
            recommendation = "deny"
        }
        
        // 3. Check for unusual timing (late night requests)
        val calendar = java.util.Calendar.getInstance()
        calendar.time = Date()
        val hour = calendar.get(java.util.Calendar.HOUR_OF_DAY)
        if (hour in 0..5) {
            threatScore += 15.0
        }
        
        // 4. Check if new owner email is unknown (higher risk)
        if (newOwnerEmail != null && !isKnownUserEmail(newOwnerEmail)) {
            threatScore += 10.0
        }
        
        // 5. Check reason for suspicious keywords
        if (reason != null) {
            val suspiciousKeywords = listOf("urgent", "emergency", "hack", "compromise", "breach")
            if (suspiciousKeywords.any { reason.lowercase().contains(it) }) {
                threatScore += 25.0
                recommendation = "review"
            }
        }
        
        // Normalize threat score to 0-100
        threatScore = threatScore.coerceIn(0.0, 100.0)
        
        // Determine recommendation
        when {
            threatScore >= 70 -> recommendation = "deny"
            threatScore >= 40 -> recommendation = "review"
            else -> recommendation = "approve"
        }
        
        return ThreatAssessment(
            threatScore = threatScore,
            recommendation = recommendation,
            threatIndex = threatScore
        )
    }
    
    private suspend fun loadRecentTransferRequests(vaultId: UUID, days: Int): List<VaultTransferRequestEntity> {
        return if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseRequests = supabaseService.fetchAll<com.khandoba.securedocs.data.supabase.SupabaseVaultTransferRequest>(
                    table = "vault_transfer_requests",
                    filters = mapOf("vault_id" to vaultId.toString())
                )
                
                val cutoffDate = Date(Date().time - (days * 24 * 60 * 60 * 1000L))
                supabaseRequests
                    .filter { request ->
                        val requestDate = java.time.Instant.parse(request.requested_at).toEpochMilli()
                        requestDate >= cutoffDate.time
                    }
                    .map { convertFromSupabase(it) }
            } catch (e: Exception) {
                Log.e("VaultTransferService", "Error loading recent transfer requests: ${e.message}")
                emptyList()
            }
        } else {
            emptyList()
        }
    }
    
    private fun convertFromSupabase(supabase: com.khandoba.securedocs.data.supabase.SupabaseVaultTransferRequest): VaultTransferRequestEntity {
        return VaultTransferRequestEntity(
            id = UUID.fromString(supabase.id),
            vaultId = UUID.fromString(supabase.vault_id),
            requestedByUserID = UUID.fromString(supabase.requested_by_user_id),
            requestedAt = Date(java.time.Instant.parse(supabase.requested_at).toEpochMilli()),
            status = supabase.status,
            reason = supabase.reason,
            newOwnerID = supabase.new_owner_id?.let { UUID.fromString(it) },
            newOwnerName = supabase.new_owner_name,
            newOwnerPhone = supabase.new_owner_phone,
            newOwnerEmail = supabase.new_owner_email,
            transferToken = supabase.transfer_token,
            approvedAt = supabase.approved_at?.let { Date(java.time.Instant.parse(it).toEpochMilli()) },
            approverID = supabase.approver_id?.let { UUID.fromString(it) },
            mlScore = supabase.ml_score,
            mlRecommendation = supabase.ml_recommendation,
            threatIndex = supabase.threat_index
        )
    }
    
    private suspend fun isKnownUserEmail(email: String): Boolean {
        // Check if email exists in users table
        return if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val users = supabaseService.fetchAll<Map<String, Any>>(
                    table = "users",
                    filters = mapOf("email" to email)
                )
                users.isNotEmpty()
            } catch (e: Exception) {
                false
            }
        } else {
            false
        }
    }
    
    private suspend fun createThreatEvent(
        vaultId: UUID,
        eventType: String,
        severity: String,
        threatScore: Double,
        description: String
    ) {
        // TODO: Create SupabaseThreatEvent model and insert
        // For now, we'll log it
        Log.d("VaultTransferService", "Threat event: $eventType, severity: $severity, score: $threatScore")
    }
    
    private data class ThreatAssessment(
        val threatScore: Double,
        val recommendation: String,
        val threatIndex: Double
    )
}
