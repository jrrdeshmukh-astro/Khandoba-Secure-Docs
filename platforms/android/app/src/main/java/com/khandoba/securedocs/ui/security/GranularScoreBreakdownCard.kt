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
import com.khandoba.securedocs.data.model.ThreatInferenceResult
import com.khandoba.securedocs.data.model.getThreatLevelColor

/**
 * Card displaying granular score breakdowns (logic types and categories)
 */
@Composable
fun GranularScoreBreakdownCard(
    result: ThreatInferenceResult,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Granular Score Breakdown",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            
            Divider()
            
            // Logic Type Scores
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Logic Type Scores",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                LogicScoreRow(
                    label = "Deductive",
                    score = result.logicBreakdown.deductiveScore,
                    icon = "✓"
                )
                
                LogicScoreRow(
                    label = "Inductive",
                    score = result.logicBreakdown.inductiveScore,
                    icon = "📊"
                )
                
                LogicScoreRow(
                    label = "Abductive",
                    score = result.logicBreakdown.abductiveScore,
                    icon = "💡"
                )
                
                LogicScoreRow(
                    label = "Statistical",
                    score = result.logicBreakdown.statisticalScore,
                    icon = "📈"
                )
                
                LogicScoreRow(
                    label = "Analogical",
                    score = result.logicBreakdown.analogicalScore,
                    icon = "🔄"
                )
                
                LogicScoreRow(
                    label = "Temporal",
                    score = result.logicBreakdown.temporalScore,
                    icon = "🕐"
                )
                
                LogicScoreRow(
                    label = "Modal",
                    score = result.logicBreakdown.modalScore,
                    icon = "👁"
                )
            }
            
            Divider()
            
            // Category Scores
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Category Scores",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                CategoryScoreRow(
                    label = "Access Pattern",
                    score = result.categoryBreakdown.accessPatternScore
                )
                
                CategoryScoreRow(
                    label = "Geographic",
                    score = result.categoryBreakdown.geographicScore
                )
                
                CategoryScoreRow(
                    label = "Document Content",
                    score = result.categoryBreakdown.documentContentScore
                )
                
                CategoryScoreRow(
                    label = "Behavioral",
                    score = result.categoryBreakdown.behavioralScore
                )
                
                CategoryScoreRow(
                    label = "External Threat",
                    score = result.categoryBreakdown.externalThreatScore
                )
                
                CategoryScoreRow(
                    label = "Compliance",
                    score = result.categoryBreakdown.complianceScore
                )
                
                CategoryScoreRow(
                    label = "Data Exfiltration",
                    score = result.categoryBreakdown.dataExfiltrationScore
                )
            }
        }
    }
}

@Composable
private fun LogicScoreRow(
    label: String,
    score: Double,
    icon: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = icon,
            fontSize = 20.sp,
            modifier = Modifier.width(24.dp)
        )
        
        Text(
            text = label,
            fontSize = 14.sp,
            modifier = Modifier.weight(1f)
        )
        
        Text(
            text = String.format("%.2f", score),
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        // Progress bar
        LinearProgressIndicator(
            progress = { (score / 100.0).toFloat() },
            modifier = Modifier
                .width(60.dp)
                .height(4.dp),
            color = getScoreColor(score),
            trackColor = MaterialTheme.colorScheme.surfaceVariant
        )
    }
}

@Composable
private fun CategoryScoreRow(
    label: String,
    score: Double
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = label,
            fontSize = 14.sp,
            modifier = Modifier.weight(1f)
        )
        
        Text(
            text = String.format("%.2f", score),
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        // Progress bar
        LinearProgressIndicator(
            progress = { (score / 100.0).toFloat() },
            modifier = Modifier
                .width(80.dp)
                .height(4.dp),
            color = getScoreColor(score),
            trackColor = MaterialTheme.colorScheme.surfaceVariant
        )
    }
}

@Composable
private fun getScoreColor(score: Double): Color {
    return when {
        score >= 75 -> Color(0xFFFF3B30) // Red
        score >= 50 -> Color(0xFFFF9500) // Orange
        score >= 25 -> Color(0xFFFFCC00) // Yellow
        else -> Color(0xFF34C759) // Green
    }
}

