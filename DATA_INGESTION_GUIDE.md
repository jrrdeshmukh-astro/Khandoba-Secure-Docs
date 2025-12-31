# Data Ingestion Guide

## Overview

The Intelligent Ingestion System automatically ingests documents from multiple sources into vaults based on topic configuration and relevance scoring.

## Architecture

### Models

- **VaultTopic**: Topic configuration for a vault
  - Keywords
  - Categories
  - Compliance frameworks
  - Data sources

### Services

**IntelligentIngestionService**:
- Topic configuration
- Multi-source ingestion
- Relevance calculation
- Progress tracking

**LearningAgentService**:
- Case-based reasoning
- Formal logic application
- Source recommendations
- Learning from outcomes

## Usage

### Configure Topic

```swift
try ingestionService.configureTopic(
    vaultID: vault.id,
    topicName: "Medical Records",
    topicDescription: "HIPAA-protected medical documents",
    keywords: ["patient", "diagnosis", "treatment"],
    categories: ["medical", "healthcare"],
    complianceFrameworks: [.hipaa],
    dataSources: ["gmail", "google_drive"]
)
```

### Start Ingestion

```swift
try await ingestionService.startIngestion(for: vault.id)
```

### Get Recommendations

```swift
let recommendations = await learningAgent.getRecommendedSources(for: vault.id)
```

## Relevance Calculation

The system uses three methods:
1. **Case-Based Reasoning** (40%): Similar past cases
2. **Formal Logic** (40%): Keyword and category matching
3. **Generate and Test** (20%): Hypothesis testing

## Integration

Integrates with:
- **EmailIntegrationService**: For email ingestion
- **CloudStorageService**: For cloud storage ingestion
- **DocumentService**: For document storage
- **ComplianceEngineService**: For compliance-aware processing

## Views

- **IngestionConfigurationView**: Configure topics and sources
- **IngestionDashboardView**: Monitor ingestion progress
- **SourceRecommendationsView**: AI-suggested sources

