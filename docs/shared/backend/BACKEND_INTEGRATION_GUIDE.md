# Backend Integration Guide

## Overview

This guide covers the backend integration for newly implemented features including vault transfer requests, document version history, and real-time threat monitoring.

## Database Migrations

### 1. Run Migration Scripts

Execute the SQL migration scripts in order:

1. **Emergency Access and Broadcast Vaults** (if not already done):
   ```sql
   -- Run: database/add_emergency_pass_and_broadcast_vault.sql
   ```

2. **Vault Transfer Requests and Document Versions**:
   ```sql
   -- Run: database/add_vault_transfer_and_document_versions.sql
   ```

### 2. Verify Migration Success

After running migrations, verify tables and indexes:

```sql
-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN (
    'vault_transfer_requests', 
    'document_versions', 
    'threat_events',
    'emergency_access_passes'
);

-- Check columns added to vaults
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'vaults' 
AND column_name IN (
    'threat_index', 
    'last_threat_assessment_at', 
    'threat_level',
    'is_broadcast',
    'access_level'
);
```

## ML Threat Analysis Integration

### Real-Time Threat Index Calculation

The threat index is automatically calculated and updated via database triggers:

1. **Automatic Updates**: Triggers update `vaults.threat_index` when:
   - Threat events are inserted/updated
   - Transfer requests are created/updated

2. **Calculation Function**: `calculate_vault_threat_index(vault_id)`
   - Considers recent unresolved threat events
   - Factors in pending transfer requests with high threat scores
   - Returns normalized 0-100 score

3. **Threat Levels**:
   - `low`: 0-24
   - `medium`: 25-49
   - `high`: 50-79
   - `critical`: 80-100

### ML Threat Assessment for Transfer Requests

When a transfer request is created, the system automatically:

1. **Assesses Threat** using `assess_transfer_request_threat()`:
   - Checks for multiple recent requests from same user
   - Detects unusual timing (late night requests)
   - Verifies if new owner email matches existing user
   - Factors in vault's current threat index

2. **Stores Assessment** in transfer request:
   - `ml_score`: Threat score (0-100)
   - `ml_recommendation`: "approve", "deny", or "review"
   - `threat_index`: Real-time threat index

3. **Creates Threat Event** if threat index >= 50

## Automatic Triage Service

The AutomaticTriageService filters actions to only include those that can be executed in the current UI:

### Supported Actions (Automatic or User-Accessible)

- ✅ `lockVault` - User can lock vault in UI
- ✅ `revokeNominees` - User can revoke nominees in UI
- ✅ `revokeAllNominees` - User can revoke all in UI
- ✅ `closeAllVaults` - User can close vaults in UI
- ✅ `revokeAllSessions` - User can revoke sessions in UI
- ✅ `enableDualKeyProtection` - User can enable in UI
- ✅ `reviewAccessLogs` - Navigation action (always allowed)
- ✅ `reviewDocumentSharing` - Navigation action (always allowed)
- ✅ `recordMonitoringIP` - Automatic logging action
- ✅ `enableEnhancedMonitoring` - User can enable in UI

### Unsupported Actions (Filtered Out)

- ❌ `changeVaultPassword` - Not implemented in UI workflow
- ❌ `changeAllPasswords` - Not implemented in UI workflow
- ❌ `redactDocuments` - Redaction UI not yet implemented
- ❌ `restrictDocumentAccess` - Access restriction UI not yet implemented

### Action Validation

Before executing any action, the service validates:
1. Vault exists and is accessible
2. User has necessary permissions
3. Action is possible in current vault state (e.g., vault must be unlocked for document operations)
4. Action is available in UI workflow

## Real-Time Threat Dashboard

Use the `vault_threat_dashboard` view for monitoring:

```sql
SELECT * FROM vault_threat_dashboard
WHERE threat_index > 50
ORDER BY threat_index DESC;
```

This view provides:
- Vault threat index and level
- Count of unresolved threat events
- Count of pending transfer requests
- Latest threat event timestamp
- Highest current threat score

## Platform-Specific Implementation

### Android

Services are configured in `ContentView.kt`:

```kotlin
val threatMonitoringService = ThreatMonitoringService()
val mlThreatAnalysisService = MLThreatAnalysisService()
val vaultTransferService = VaultTransferService(
    vaultRepository = vaultRepository,
    supabaseService = supabaseService,
    threatMonitoringService = threatMonitoringService,
    mlThreatAnalysisService = mlThreatAnalysisService
)
```

### Windows

Services are registered in `App.xaml.cs`:

```csharp
services.AddSingleton<VaultTransferService>();
services.AddSingleton<MLThreatAnalysisService>();
services.AddSingleton<ThreatMonitoringService>();
```

## Testing

### Test Threat Index Calculation

```sql
-- Test with a specific vault
SELECT calculate_vault_threat_index('your-vault-id-here');

-- View current threat levels
SELECT id, name, threat_index, threat_level, last_threat_assessment_at
FROM vaults
ORDER BY threat_index DESC;
```

### Test Transfer Request Threat Assessment

1. Create a test transfer request
2. Check ML assessment fields are populated:
   ```sql
   SELECT id, ml_score, ml_recommendation, threat_index
   FROM vault_transfer_requests
   WHERE id = 'your-request-id';
   ```

3. Verify threat event was created (if threat_index >= 50):
   ```sql
   SELECT * FROM threat_events
   WHERE event_type = 'transfer_request'
   ORDER BY detected_at DESC;
   ```

## Monitoring and Alerts

### Set Up Real-Time Subscriptions

Use Supabase Realtime to monitor threat events:

```typescript
// Example: Subscribe to threat events
const channel = supabase
  .channel('threat-events')
  .on('postgres_changes', 
    { 
      event: 'INSERT', 
      schema: 'public', 
      table: 'threat_events' 
    },
    (payload) => {
      console.log('New threat event:', payload.new)
      // Update UI or send notification
    }
  )
  .subscribe()
```

### Alert Thresholds

Configure alerts based on threat levels:
- **Critical** (>= 80): Immediate notification, auto-lock vault
- **High** (50-79): User notification, require review
- **Medium** (25-49): Log event, optional notification
- **Low** (< 25): Silent logging only

## Best Practices

1. **Threat Index Updates**: Database triggers handle automatic updates, but you can manually recalculate if needed:
   ```sql
   UPDATE vaults 
   SET threat_index = calculate_vault_threat_index(id),
       threat_level = CASE
           WHEN calculate_vault_threat_index(id) >= 80 THEN 'critical'
           WHEN calculate_vault_threat_index(id) >= 50 THEN 'high'
           WHEN calculate_vault_threat_index(id) >= 25 THEN 'medium'
           ELSE 'low'
       END
   WHERE id = 'vault-id';
   ```

2. **ML Assessment**: Always perform ML threat assessment before creating transfer requests or other sensitive operations

3. **Triage Filtering**: Always filter triage actions through `filterValidActions()` to ensure only UI-accessible actions are shown

4. **Threat Events**: Create threat events for all security-sensitive operations to maintain audit trail

## Troubleshooting

### Threat Index Not Updating

1. Check triggers are installed:
   ```sql
   SELECT trigger_name, event_object_table
   FROM information_schema.triggers
   WHERE trigger_name LIKE '%threat_index%';
   ```

2. Manually trigger update:
   ```sql
   SELECT update_vault_threat_index();
   ```

### ML Assessment Not Running

1. Verify ML service is configured in platform code
2. Check service logs for errors
3. Ensure Supabase connection is active

### Triage Actions Not Showing

1. Check action validation logs
2. Verify vault state (must be unlocked for document operations)
3. Ensure user has necessary permissions
4. Confirm action is in supported list above
