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
 * Card displaying formal logic threat inferences
 */
@Composable
fun FormalLogicThreatCard(
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
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "🧠",
                        fontSize = 24.sp
                    )
                    
                    Text(
                        text = "Formal Logic Threat Inferences",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                Surface(
                    color = MaterialTheme.colorScheme.surfaceVariant,
                    shape = MaterialTheme.shapes.small
                ) {
                    Text(
                        text = "${result.threatInferences.size}",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
            
            Divider()
            
            // Top contributing inferences
            if (result.inferenceContributions.isNotEmpty()) {
                Column(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Top Contributing Threats",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    result.inferenceContributions.take(5).forEach { contribution ->
                        InferenceContributionRow(contribution = contribution)
                    }
                }
            } else {
                Text(
                    text = "No threat inferences generated",
                    fontSize = 14.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 16.dp),
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                )
            }
        }
    }
}

@Composable
private fun InferenceContributionRow(
    contribution: com.khandoba.securedocs.data.model.InferenceContribution
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = getLogicTypeIcon(contribution.logicType),
                fontSize = 20.sp,
                modifier = Modifier.width(24.dp)
            )
            
            Text(
                text = contribution.conclusion,
                fontSize = 14.sp,
                modifier = Modifier.weight(1f),
                maxLines = 2
            )
            
            Text(
                text = String.format("%.1f", contribution.contributionScore),
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = getImpactColor(contribution.impact)
            )
        }
        
        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                color = MaterialTheme.colorScheme.surfaceVariant,
                shape = MaterialTheme.shapes.extraSmall
            ) {
                Text(
                    text = contribution.category.description,
                    fontSize = 10.sp,
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
            
            Text(
                text = "${String.format("%.0f", contribution.confidence * 100)}% confidence",
                fontSize = 10.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun getLogicTypeIcon(logicType: String): String {
    return when (logicType.lowercase()) {
        "deductive" -> "✓"
        "inductive" -> "📊"
        "abductive" -> "💡"
        "statistical" -> "📈"
        "analogical" -> "🔄"
        "temporal" -> "🕐"
        "modal" -> "👁"
        else -> "🔍"
    }
}

@Composable
private fun getImpactColor(impact: com.khandoba.securedocs.data.model.ThreatImpact): Color {
    return when (impact) {
        com.khandoba.securedocs.data.model.ThreatImpact.CRITICAL -> Color(0xFFFF3B30) // Red
        com.khandoba.securedocs.data.model.ThreatImpact.HIGH -> Color(0xFFFF9500) // Orange
        com.khandoba.securedocs.data.model.ThreatImpact.MEDIUM -> Color(0xFFFFCC00) // Yellow
        com.khandoba.securedocs.data.model.ThreatImpact.LOW -> Color(0xFF34C759) // Green
    }
}

