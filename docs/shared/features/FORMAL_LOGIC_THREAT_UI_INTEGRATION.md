# Formal Logic Threat Inference UI Integration Guide

## Overview

This document describes the UI integration for the Formal Logic Threat Inference System across all platforms. The system provides granular threat scoring with 10-level classification, component breakdowns, and detailed recommendations.

## Features Integrated

### 1. Granular Threat Scoring
- **10-Level Classification**: Minimal → Very Low → Low → Low-Medium → Medium → Medium-High → High → High-Critical → Critical → Extreme
- **2 Decimal Precision**: Scores displayed as 47.83 instead of 48
- **Component Breakdowns**: 
  - Logic Type Scores (7 components: Deductive, Inductive, Abductive, Statistical, Analogical, Temporal, Modal)
  - Category Scores (7 categories: Access Pattern, Geographic, Document Content, Behavioral, External Threat, Compliance, Data Exfiltration)

### 2. Threat Inference Display
- Top contributing threat inferences
- Inference contributions with confidence levels
- Category tagging for each inference
- Impact levels (Low, Medium, High, Critical)

### 3. Recommendations
- Prioritized action items
- Urgency levels (Immediate, Urgent, Important, Routine)
- Expected impact scores
- Rationale for each recommendation

### 4. Score Trends
- Score delta (change from last assessment)
- Score velocity (rate of change)
- Historical trend visualization

## Platform-Specific Implementation

### Apple (iOS/macOS/tvOS) - SwiftUI

**File**: `platforms/apple/Khandoba Secure Docs/Views/Security/EnhancedThreatMonitorView.swift`

**Status**: ✅ Integrated

**Components Added**:
- `GranularThreatScoreCard`: Displays composite score with 10-level classification
- `GranularScoreBreakdownCard`: Shows logic type and category component scores
- `FormalLogicThreatCard`: Lists top contributing threat inferences
- `ThreatRecommendationsCard`: Displays prioritized recommendations with urgency

**Integration Points**:
1. Enhanced `analyzeThreats()` method to call `FormalLogicThreatInferenceService`
2. Updated Overall Risk Card to use granular scores when available
3. Added expandable details section for granular breakdowns
4. Integrated with existing ML threat analysis display

**Key Features**:
- Circular progress indicator with precise score display
- Expandable/collapsible detail sections
- Color-coded threat levels
- Score trend indicators (delta, velocity)
- Visual breakdown bars for component scores

### Android - Kotlin/Compose

**Status**: ⚠️ TODO

**Required Components**:
1. `GranularThreatScoreCard.kt`: Composable for displaying composite score
2. `GranularScoreBreakdownCard.kt`: Composable for component score breakdowns
3. `FormalLogicThreatCard.kt`: Composable for threat inferences
4. `ThreatRecommendationsCard.kt`: Composable for recommendations

**Integration Steps**:
1. Update `ThreatIndexChartView.kt` to display granular scores
2. Create new composables in `ui/security/` directory
3. Update threat monitoring activity/fragment to include formal logic analysis
4. Add data models matching the Swift structs

**Example Structure**:
```kotlin
@Composable
fun GranularThreatScoreCard(
    result: ThreatInferenceResult,
    showDetails: MutableState<Boolean>
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Score display
            // Level display
            // Trend indicators
            // Details toggle
        }
    }
}
```

### Windows - C#/XAML

**Status**: ⚠️ TODO

**Required Components**:
1. `GranularThreatScoreCard.xaml`: UserControl for composite score
2. `GranularScoreBreakdownCard.xaml`: UserControl for component breakdowns
3. `FormalLogicThreatCard.xaml`: UserControl for threat inferences
4. `ThreatRecommendationsCard.xaml`: UserControl for recommendations

**Integration Steps**:
1. Update `ThreatIndexChartView.xaml` to display granular scores
2. Create new UserControls in `Views/` directory
3. Update threat monitoring view model to include formal logic analysis
4. Add data models matching the Swift structs

**Example Structure**:
```xml
<UserControl x:Class="KhandobaSecureDocs.Views.GranularThreatScoreCard">
    <Border Background="LightGray" Padding="16" CornerRadius="8">
        <StackPanel Spacing="16">
            <!-- Score display -->
            <!-- Level display -->
            <!-- Trend indicators -->
            <!-- Details toggle -->
        </StackPanel>
    </Border>
</UserControl>
```

## Data Models

All platforms should implement these core data structures:

### ThreatInferenceResult
- `vaultID: UUID/String`
- `granularScores: GranularThreatScores`
- `threatLevel: GranularThreatLevel` (10-level enum)
- `threatInferences: List<LogicalInference>`
- `categoryBreakdown: ThreatCategoryScores`
- `logicBreakdown: LogicComponentScores`
- `inferenceContributions: List<InferenceContribution>`
- `recommendations: List<ThreatRecommendation>`
- `calculatedAt: DateTime`
- `scoreHistory: List<ThreatScoreSnapshot>?`

### GranularThreatScores
- `compositeScore: Double` (0-100, 2 decimal precision)
- `logicScores: LogicComponentScores`
- `categoryScores: ThreatCategoryScores`
- `inferenceContributions: List<InferenceContribution>`
- `scoreDelta: Double?` (change from last)
- `scoreVelocity: Double?` (rate of change)

### GranularThreatLevel (Enum)
- `minimal` (0.0-10.0)
- `veryLow` (10.1-20.0)
- `low` (20.1-30.0)
- `lowMedium` (30.1-40.0)
- `medium` (40.1-50.0)
- `mediumHigh` (50.1-60.0)
- `high` (60.1-70.0)
- `highCritical` (70.1-80.0)
- `critical` (80.1-90.0)
- `extreme` (90.1-100.0)

## UI Design Guidelines

### Color Coding
- **Extreme/Critical** (80.1-100.0): Red (`colors.error`)
- **High-Critical/High** (60.1-80.0): Orange
- **Medium-High/Medium** (40.1-60.0): Yellow (`colors.warning`)
- **Low-Medium/Low** (20.1-40.0): Light Yellow
- **Very Low/Minimal** (0.0-20.0): Green (`colors.success`)

### Typography
- Composite Score: Large, bold, system font (36pt on Apple, equivalent on others)
- Threat Level: Title font, bold
- Component Scores: Body font with semibold values
- Recommendations: Body font with priority indicators

### Layout
- Primary Card: Full width, contains score and level
- Breakdown Cards: Expandable sections
- Component Rows: Icon + Label + Score + Progress Bar
- Recommendations: Numbered list with urgency badges

## Testing Checklist

### Apple
- [x] Granular score card displays correctly
- [x] Component breakdowns show all 7 logic types
- [x] Category scores display properly
- [x] Recommendations show with priority and urgency
- [ ] Score trends display correctly (delta, velocity)
- [ ] Integration with existing ML threat analysis

### Android
- [ ] All UI components created
- [ ] Data models implemented
- [ ] Integration with threat monitoring service
- [ ] Theme colors match design guidelines
- [ ] Testing with various threat levels

### Windows
- [ ] All UserControls created
- [ ] Data models implemented
- [ ] Integration with threat monitoring service
- [ ] Theme colors match design guidelines
- [ ] Testing with various threat levels

## Future Enhancements

1. **Historical Charts**: Visualize score trends over time
2. **Comparison View**: Compare threat scores across multiple vaults
3. **Drill-Down**: Click on component scores to see contributing inferences
4. **Export**: Export threat reports as PDF/CSV
5. **Notifications**: Push notifications for high-threat levels
6. **A/B Testing**: Test different visualization approaches

## Notes

- All scores use 2 decimal precision for granularity
- Component scores are normalized to 0-100 range
- Threat levels map backward-compatibly to legacy 4-level system (low/medium/high/critical)
- Recommendations are prioritized by urgency and expected impact
- Score trends require historical data (minimum 2 assessments)

