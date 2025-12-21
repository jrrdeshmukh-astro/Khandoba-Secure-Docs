package com.khandoba.securedocs.data.model

import java.util.*

/**
 * 10-level granular threat classification
 */
enum class GranularThreatLevel(val displayName: String, val numericValue: Int, val scoreRange: ClosedFloatingPointRange<Double>) {
    MINIMAL("Minimal", 1, 0.0..10.0),
    VERY_LOW("Very Low", 2, 10.1..20.0),
    LOW("Low", 3, 20.1..30.0),
    LOW_MEDIUM("Low-Medium", 4, 30.1..40.0),
    MEDIUM("Medium", 5, 40.1..50.0),
    MEDIUM_HIGH("Medium-High", 6, 50.1..60.0),
    HIGH("High", 7, 60.1..70.0),
    HIGH_CRITICAL("High-Critical", 8, 70.1..80.0),
    CRITICAL("Critical", 9, 80.1..90.0),
    EXTREME("Extreme", 10, 90.1..100.0);
    
    val requiresAction: Boolean
        get() = numericValue >= 6 // Medium-High and above
    
    val requiresImmediateAction: Boolean
        get() = numericValue >= 8 // High-Critical and above
    
    companion object {
        fun fromScore(score: Double): GranularThreatLevel {
            return when {
                score < 10.1 -> MINIMAL
                score < 20.1 -> VERY_LOW
                score < 30.1 -> LOW
                score < 40.1 -> LOW_MEDIUM
                score < 50.1 -> MEDIUM
                score < 60.1 -> MEDIUM_HIGH
                score < 70.1 -> HIGH
                score < 80.1 -> HIGH_CRITICAL
                score < 90.1 -> CRITICAL
                else -> EXTREME
            }
        }
    }
}

/**
 * Logic component scores (7 logic types)
 */
data class LogicComponentScores(
    val deductiveScore: Double,
    val inductiveScore: Double,
    val abductiveScore: Double,
    val statisticalScore: Double,
    val analogicalScore: Double,
    val temporalScore: Double,
    val modalScore: Double
)

/**
 * Threat category scores (7 categories)
 */
data class ThreatCategoryScores(
    val accessPatternScore: Double,
    val geographicScore: Double,
    val documentContentScore: Double,
    val behavioralScore: Double,
    val externalThreatScore: Double,
    val complianceScore: Double,
    val dataExfiltrationScore: Double
)

/**
 * Granular threat scores with component breakdowns
 */
data class GranularThreatScores(
    val compositeScore: Double, // 0-100, 2 decimal precision
    val logicScores: LogicComponentScores,
    val categoryScores: ThreatCategoryScores,
    val inferenceContributions: List<InferenceContribution>,
    val scoreDelta: Double? = null, // Change from last assessment
    val scoreVelocity: Double? = null // Rate of change
)

/**
 * Extension function to get threat level color
 */
fun getThreatLevelColor(level: GranularThreatLevel): androidx.compose.ui.graphics.Color {
    return when (level.numericValue) {
        in 9..10 -> androidx.compose.ui.graphics.Color(0xFFFF3B30) // Critical/Extreme - Red
        in 7..8 -> androidx.compose.ui.graphics.Color(0xFFFF9500) // High/High-Critical - Orange
        in 5..6 -> androidx.compose.ui.graphics.Color(0xFFFFCC00) // Medium/Medium-High - Yellow
        in 3..4 -> androidx.compose.ui.graphics.Color(0xFFFFF100) // Low/Low-Medium - Light Yellow
        else -> androidx.compose.ui.graphics.Color(0xFF34C759) // Minimal/Very Low - Green
    }
}

/**
 * Threat category enum
 */
enum class ThreatCategory(val description: String) {
    ACCESS_PATTERN("Access Pattern"),
    GEOGRAPHIC("Geographic"),
    DOCUMENT_CONTENT("Document Content"),
    BEHAVIORAL("Behavioral"),
    EXTERNAL_THREAT("External Threat"),
    COMPLIANCE("Compliance"),
    DATA_EXFILTRATION("Data Exfiltration")
}

/**
 * Threat impact level
 */
enum class ThreatImpact {
    LOW,       // 0-25 contribution
    MEDIUM,    // 26-50 contribution
    HIGH,      // 51-75 contribution
    CRITICAL   // 76-100 contribution
}

/**
 * Urgency level for recommendations
 */
enum class UrgencyLevel(val displayName: String) {
    IMMEDIATE("Immediate"),      // Act within 1 hour
    URGENT("Urgent"),           // Act within 24 hours
    IMPORTANT("Important"),     // Act within 1 week
    ROUTINE("Routine")          // Act within 1 month
}

/**
 * Inference contribution to threat score
 */
data class InferenceContribution(
    val inferenceID: UUID,
    val logicType: String, // LogicType enum as string
    val category: ThreatCategory,
    val contributionScore: Double, // 0-100
    val confidence: Double,
    val impact: ThreatImpact,
    val conclusion: String
)

/**
 * Threat recommendation with priority and urgency
 */
data class ThreatRecommendation(
    val priority: Int, // 1-10 (1 = highest priority)
    val category: ThreatCategory,
    val action: String,
    val rationale: String,
    val expectedImpact: Double, // Expected score reduction if action taken
    val urgency: UrgencyLevel
)

/**
 * Threat score snapshot for history tracking
 */
data class ThreatScoreSnapshot(
    val timestamp: Date,
    val compositeScore: Double,
    val categoryScores: ThreatCategoryScores,
    val logicScores: LogicComponentScores
)

/**
 * Complete threat inference result
 */
data class ThreatInferenceResult(
    val vaultID: UUID,
    val granularScores: GranularThreatScores,
    val threatLevel: GranularThreatLevel,
    val threatInferences: List<LogicalInference>,
    val categoryBreakdown: ThreatCategoryScores,
    val logicBreakdown: LogicComponentScores,
    val inferenceContributions: List<InferenceContribution>,
    val recommendations: List<ThreatRecommendation>,
    val calculatedAt: Date,
    val scoreHistory: List<ThreatScoreSnapshot>? = null
)

/**
 * Logical inference from formal logic engine
 */
data class LogicalInference(
    val id: UUID,
    val type: String, // LogicType enum as string
    val method: String,
    val premise: String,
    val observation: String,
    val conclusion: String,
    val confidence: Double,
    val actionable: String? = null
)

