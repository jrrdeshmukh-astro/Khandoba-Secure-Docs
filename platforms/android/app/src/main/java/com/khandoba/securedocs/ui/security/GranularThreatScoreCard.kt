package com.khandoba.securedocs.ui.security

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khandoba.securedocs.data.model.GranularThreatLevel
import com.khandoba.securedocs.data.model.ThreatInferenceResult

/**
 * Card displaying granular threat score with 10-level classification
 */
@Composable
fun GranularThreatScoreCard(
    result: ThreatInferenceResult,
    showDetails: MutableState<Boolean>,
    modifier: Modifier = Modifier
) {
    val score = result.granularScores.compositeScore
    val level = result.threatLevel
    
    Card(
        modifier = modifier.fillMaxWidth()
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
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "Threat Level",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Text(
                        text = level.displayName,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        color = getThreatLevelColor(level)
                    )
                    
                    Text(
                        text = "Score: ${String.format("%.2f", score)}/100",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                // Circular progress indicator
                CircularThreatIndicator(
                    score = score,
                    level = level,
                    modifier = Modifier.size(100.dp)
                )
            }
            
            // Score trend indicator
            result.granularScores.scoreDelta?.let { delta ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    val (icon, color) = when {
                        delta > 0 -> "↑" to Color(0xFFFF3B30) // Red
                        delta < 0 -> "↓" to Color(0xFF34C759) // Green
                        else -> "→" to MaterialTheme.colorScheme.onSurfaceVariant
                    }
                    
                    Text(
                        text = icon,
                        fontSize = 14.sp,
                        color = color
                    )
                    
                    Text(
                        text = "${String.format("%.2f", kotlin.math.abs(delta))} from last assessment",
                        fontSize = 12.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            // Details toggle
            TextButton(
                onClick = { showDetails.value = !showDetails.value },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = if (showDetails.value) "Hide Details" else "Show Details",
                    fontSize = 14.sp
                )
            }
        }
    }
}

@Composable
private fun CircularThreatIndicator(
    score: Double,
    level: GranularThreatLevel,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        // Background circle
        CircularProgressIndicator(
            progress = { 1f },
            modifier = Modifier.size(100.dp),
            color = MaterialTheme.colorScheme.surfaceVariant,
            strokeWidth = 10.dp
        )
        
        // Progress circle
        CircularProgressIndicator(
            progress = { (score / 100.0).toFloat() },
            modifier = Modifier.size(100.dp),
            color = getThreatLevelColor(level),
            strokeWidth = 10.dp
        )
        
        // Score text
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = String.format("%.2f", score),
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = getThreatLevelColor(level)
            )
            
            Text(
                text = "Score",
                fontSize = 10.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun getThreatLevelColor(level: GranularThreatLevel): Color {
    return when (level.numericValue) {
        in 9..10 -> Color(0xFFFF3B30) // Critical/Extreme - Red
        in 7..8 -> Color(0xFFFF9500) // High/High-Critical - Orange
        in 5..6 -> Color(0xFFFFCC00) // Medium/Medium-High - Yellow
        in 3..4 -> Color(0xFFFFF100) // Low/Low-Medium - Light Yellow
        else -> Color(0xFF34C759) // Minimal/Very Low - Green
    }
}

