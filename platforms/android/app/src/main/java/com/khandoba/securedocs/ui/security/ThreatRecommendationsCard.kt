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
import com.khandoba.securedocs.data.model.ThreatRecommendation
import com.khandoba.securedocs.data.model.UrgencyLevel

/**
 * Card displaying prioritized threat recommendations
 */
@Composable
fun ThreatRecommendationsCard(
    recommendations: List<ThreatRecommendation>,
    modifier: Modifier = Modifier
) {
    if (recommendations.isEmpty()) return
    
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
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "📋",
                    fontSize = 24.sp
                )
                
                Text(
                    text = "Recommended Actions",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
            }
            
            Divider()
            
            recommendations.forEachIndexed { index, recommendation ->
                RecommendationRow(
                    recommendation = recommendation,
                    index = index + 1
                )
                
                if (index < recommendations.size - 1) {
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

@Composable
private fun RecommendationRow(
    recommendation: ThreatRecommendation,
    index: Int
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Row(
            verticalAlignment = Alignment.Top,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Priority number
            Surface(
                color = getUrgencyColor(recommendation.urgency),
                shape = MaterialTheme.shapes.extraSmall,
                modifier = Modifier.size(24.dp)
            ) {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Text(
                        text = "$index",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }
            
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = recommendation.action,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold
                )
                
                Text(
                    text = recommendation.rationale,
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Urgency badge
                    Surface(
                        color = getUrgencyColor(recommendation.urgency),
                        shape = MaterialTheme.shapes.extraSmall
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = getUrgencyIcon(recommendation.urgency),
                                fontSize = 10.sp
                            )
                            
                            Text(
                                text = recommendation.urgency.displayName,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }
                    
                    // Expected impact
                    Text(
                        text = "Expected impact: -${String.format("%.1f", recommendation.expectedImpact)}",
                        fontSize = 10.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun getUrgencyColor(urgency: UrgencyLevel): Color {
    return when (urgency) {
        UrgencyLevel.IMMEDIATE -> Color(0xFFFF3B30) // Red
        UrgencyLevel.URGENT -> Color(0xFFFF9500) // Orange
        UrgencyLevel.IMPORTANT -> Color(0xFFFFCC00) // Yellow
        UrgencyLevel.ROUTINE -> Color(0xFF34C759) // Green
    }
}

@Composable
private fun getUrgencyIcon(urgency: UrgencyLevel): String {
    return when (urgency) {
        UrgencyLevel.IMMEDIATE -> "⚡"
        UrgencyLevel.URGENT -> "⚠"
        UrgencyLevel.IMPORTANT -> "ℹ"
        UrgencyLevel.ROUTINE -> "🕐"
    }
}

