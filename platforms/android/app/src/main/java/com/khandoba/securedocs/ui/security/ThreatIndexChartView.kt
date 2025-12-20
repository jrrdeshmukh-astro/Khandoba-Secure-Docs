package com.khandoba.securedocs.ui.security

import android.graphics.Color
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.data.LineData
import com.github.mikephil.charting.data.LineDataSet
import com.github.mikephil.charting.formatter.ValueFormatter
import java.text.SimpleDateFormat
import java.util.*
import com.khandoba.securedocs.service.ThreatIndexDataPoint

// ThreatIndexDataPoint moved to ThreatIndexService.kt

@Composable
fun ThreatIndexChartView(
    threatIndexHistory: List<ThreatIndexDataPoint>,
    currentThreatIndex: Double? = null,
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
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
            ) {
                Text(
                    text = "Threat Index Trend",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )
                
                currentThreatIndex?.let { index ->
                    ThreatIndexBadge(threatIndex = index)
                }
            }
            
            // Chart
            if (threatIndexHistory.isNotEmpty()) {
                AndroidView(
                    factory = { context ->
                        LineChart(context).apply {
                            description.isEnabled = false
                            setTouchEnabled(true)
                            setDragEnabled(true)
                            setScaleEnabled(true)
                            setPinchZoom(true)
                            
                            // X Axis
                            xAxis.apply {
                                position = XAxis.XAxisPosition.BOTTOM
                                setDrawGridLines(false)
                                granularity = 1f
                                valueFormatter = object : ValueFormatter() {
                                    private val dateFormat = SimpleDateFormat("MM/dd", Locale.getDefault())
                                    override fun getFormattedValue(value: Float): String {
                                        val index = value.toInt()
                                        if (index >= 0 && index < threatIndexHistory.size) {
                                            return dateFormat.format(threatIndexHistory[index].timestamp)
                                        }
                                        return ""
                                    }
                                }
                            }
                            
                            // Y Axis
                            axisLeft.apply {
                                axisMinimum = 0f
                                axisMaximum = 100f
                                setDrawGridLines(true)
                                granularity = 20f
                            }
                            axisRight.isEnabled = false
                            
                            // Data
                            val entries = threatIndexHistory.mapIndexed { index, dataPoint ->
                                Entry(index.toFloat(), dataPoint.threatIndex.toFloat())
                            }
                            
                            val dataSet = LineDataSet(entries, "Threat Index").apply {
                                color = getThreatColor(threatIndexHistory.lastOrNull()?.threatLevel ?: "low")
                                setCircleColor(getThreatColor(threatIndexHistory.lastOrNull()?.threatLevel ?: "low"))
                                lineWidth = 2f
                                circleRadius = 4f
                                setDrawCircleHole(false)
                                setDrawValues(false)
                                mode = LineDataSet.Mode.CUBIC_BEZIER
                                cubicIntensity = 0.2f
                            }
                            
                            data = LineData(dataSet)
                            animateX(1000)
                            invalidate()
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp)
                )
            } else {
                // Empty state
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp),
                    contentAlignment = androidx.compose.ui.Alignment.Center
                ) {
                    Text(
                        text = "No threat index data available",
                        fontSize = 14.sp,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                }
            }
            
            // Legend/Info
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                ThreatLevelIndicator("Low", 0.0, Color.GREEN)
                ThreatLevelIndicator("Medium", 25.0, Color.YELLOW)
                ThreatLevelIndicator("High", 50.0, Color.parseColor("#FF9800"))
                ThreatLevelIndicator("Critical", 75.0, Color.RED)
            }
        }
    }
}

@Composable
private fun ThreatIndexBadge(threatIndex: Double) {
    val (color, level) = when {
        threatIndex >= 75 -> androidx.compose.ui.graphics.Color(0xFFF44336) to "CRITICAL"
        threatIndex >= 50 -> androidx.compose.ui.graphics.Color(0xFFFF9800) to "HIGH"
        threatIndex >= 25 -> androidx.compose.ui.graphics.Color(0xFFFFEB3B) to "MEDIUM"
        else -> androidx.compose.ui.graphics.Color(0xFF4CAF50) to "LOW"
    }
    
    Surface(
        color = color.copy(alpha = 0.2f),
        shape = MaterialTheme.shapes.small
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
        ) {
            Text(
                text = "${threatIndex.toInt()}",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = color
            )
            Text(
                text = level,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                color = color
            )
        }
    }
}

@Composable
private fun ThreatLevelIndicator(
    label: String,
    threshold: Double,
    color: Int
) {
    Row(
        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Box(
            modifier = Modifier
                .size(12.dp)
                .background(
                    androidx.compose.ui.graphics.Color(color),
                    shape = androidx.compose.foundation.shape.CircleShape
                )
        )
        Text(
            text = label,
            fontSize = 10.sp,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
        )
    }
}

private fun getThreatColor(level: String): Int {
    return when (level.lowercase()) {
        "critical" -> Color.RED
        "high" -> Color.parseColor("#FF9800") // Orange
        "medium" -> Color.YELLOW
        else -> Color.GREEN
    }
}
