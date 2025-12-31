# Index Calculation Guide

## Overview

The Index Calculation System provides real-time calculation of three key security and compliance indexes.

## Indexes

### 1. Threat Index (0-100)

Measures real-time threat level:
- **Anomaly Score** (40%): From ThreatMonitoringService
- **Recent Threat Events** (30%): Recent security events
- **Access Pattern Anomalies** (20%): Unusual access patterns
- **Failed Authentication** (10%): Failed login attempts

### 2. Compliance Index (0-100)

Measures compliance status:
- **Framework Status** (50%): Overall compliance status
- **Control Implementation** (30%): Implementation rate
- **Risk Score Inverse** (10%): Inverse of average risk
- **Audit Findings** (10%): Critical findings impact

### 3. Triage Criticality (0-100)

Measures urgency of issues:
- **Threat Criticality** (35%): Current threat level
- **Compliance Violations** (30%): Non-compliance status
- **Pending Actions** (20%): Unresolved items
- **Risk Exposure** (15%): Average risk score

## Calculation

Indexes are calculated every 30 seconds automatically. Manual refresh is also available.

## Usage

```swift
let indexes = indexService.currentIndexes
print("Threat Index: \(indexes.threatIndex)")
print("Compliance Index: \(indexes.complianceIndex)")
print("Triage Criticality: \(indexes.triageCriticality)")
```

## Integration

Integrates with:
- **ThreatMonitoringService**: For threat data
- **ComplianceEngineService**: For compliance data
- **RiskAssessmentService**: For risk data
- **VaultAccessLog**: For access pattern analysis

## Views

- **IndexDashboardView**: Real-time index display with visualizations

