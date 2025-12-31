# Compliance System Guide

## Overview

The Compliance Engine provides comprehensive compliance tracking and assessment for multiple frameworks including SOC 2, HIPAA, NIST 800-53, ISO 27001, DFARS, and FINRA.

## Architecture

### Models

- **ComplianceRecord**: Tracks compliance status for a framework
- **ComplianceControl**: Individual control implementation status
- **AuditFinding**: Compliance violations and findings

### Service

**ComplianceEngineService** provides:
- Framework initialization
- Control checking
- Compliance assessment
- Audit finding management
- Status calculation

## Usage

### Initialize Compliance Records

```swift
try complianceService.initializeComplianceRecords()
```

### Assess Compliance

```swift
try await complianceService.assessCompliance(for: .hipaa)
```

### Add Audit Finding

```swift
try complianceService.addAuditFinding(
    to: .hipaa,
    title: "PHI Exposure",
    description: "PHI detected in unencrypted document",
    severity: "High"
)
```

## Integration

The compliance engine integrates with:
- **ThreatMonitoringService**: For security event tracking
- **RiskAssessmentService**: For risk scoring
- **IndexCalculationService**: For compliance index calculation

## Frameworks Supported

1. **SOC 2**: Service Organization Control 2
2. **HIPAA**: Health Insurance Portability and Accountability Act
3. **NIST 800-53**: National Institute of Standards and Technology
4. **ISO 27001**: Information Security Management
5. **DFARS**: Defense Federal Acquisition Regulation Supplement
6. **FINRA**: Financial Industry Regulatory Authority

## Views

- **ComplianceDashboardView**: Overview of all frameworks
- **ComplianceFrameworkDetailView**: Framework-specific details
- **ComplianceControlView**: Individual control status

