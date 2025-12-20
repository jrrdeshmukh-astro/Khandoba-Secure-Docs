# Backend Integration Complete

## ✅ Completed Tasks

### 1. Database Schema
- ✅ Created `vault_transfer_requests` table with ML threat assessment fields
- ✅ Created `document_versions` table for version history
- ✅ Created `threat_events` table for security event tracking
- ✅ Added threat monitoring columns to `vaults` table (threat_index, threat_level, last_threat_assessment_at)
- ✅ Implemented real-time threat index calculation via database functions and triggers

### 2. ML Threat Analysis Integration
- ✅ ML threat assessment automatically runs on transfer request creation
- ✅ Threat index calculated in real-time via database triggers
- ✅ Threat events created for high-risk operations (threat_index >= 50)
- ✅ ML recommendations (approve/deny/review) stored with transfer requests

### 3. Automatic Triage Service
- ✅ Triage actions filtered to only include UI-accessible operations
- ✅ Action validation ensures operations are possible in current vault state
- ✅ Unsupported actions (password changes, redaction) are filtered out

### 4. Platform Implementation
- ✅ Android: VaultTransferService with ML threat analysis integration
- ✅ Android: MLThreatAnalysisService for threat assessment
- ✅ Android: Supabase models and service integration
- ✅ Windows: Service structure created (backend integration pending)

## 📋 Migration Steps

### Step 1: Run Database Migrations

Execute in Supabase SQL Editor in order:

1. **Emergency Access & Broadcast Vaults** (if not already done):
   ```sql
   -- File: database/add_emergency_pass_and_broadcast_vault.sql
   ```

2. **Transfer Requests & Document Versions**:
   ```sql
   -- File: database/add_vault_transfer_and_document_versions.sql
   ```

### Step 2: Verify Installation

```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN (
    'vault_transfer_requests', 
    'document_versions', 
    'threat_events',
    'emergency_access_passes'
);

-- Check threat index function exists
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'calculate_vault_threat_index';

-- Check triggers are active
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_name LIKE '%threat_index%';
```

### Step 3: Test Threat Index Calculation

```sql
-- Test with a sample vault
SELECT calculate_vault_threat_index('your-vault-id-here');

-- View current threat levels
SELECT id, name, threat_index, threat_level, last_threat_assessment_at
FROM vaults
ORDER BY threat_index DESC
LIMIT 10;
```

## 🔍 Real-Time Threat Monitoring

### Threat Dashboard View

```sql
-- View all vaults with threat information
SELECT * FROM vault_threat_dashboard
WHERE threat_index > 50
ORDER BY threat_index DESC;
```

### Threat Levels

- **Low** (0-24): Normal operations
- **Medium** (25-49): Elevated risk, monitor
- **High** (50-79): Significant threat, requires review
- **Critical** (80-100): Immediate action required

### Automatic Updates

Threat index is automatically updated when:
- New threat events are created
- Transfer requests are created/updated
- Database triggers fire on related table changes

## 🤖 ML Threat Assessment

### Transfer Request Assessment

When a transfer request is created, the system:

1. **Assesses Threat** using multiple factors:
   - Vault's current threat level
   - Multiple recent requests from same user
   - Unusual timing (late night requests)
   - Unknown recipient email
   - Suspicious keywords in reason

2. **Stores Assessment**:
   - `ml_score`: 0-100 threat score
   - `ml_recommendation`: "approve", "deny", or "review"
   - `threat_index`: Real-time threat index

3. **Creates Threat Event** if threat_index >= 50

### Assessment Logic

```sql
-- View assessment details for a transfer request
SELECT 
    id,
    vault_id,
    new_owner_email,
    ml_score,
    ml_recommendation,
    threat_index,
    status,
    requested_at
FROM vault_transfer_requests
WHERE status = 'pending'
ORDER BY threat_index DESC;
```

## 📱 Platform-Specific Notes

### Android

- Services configured in `ContentView.kt`
- ML threat analysis runs automatically on transfer request creation
- Threat events logged for monitoring
- Supabase models created for data synchronization

### Windows

- Service structure created
- Backend integration code ready (needs Supabase client implementation)
- Follow Android patterns for consistency

## 🚨 Alert Configuration

### Recommended Alert Thresholds

- **Critical** (>= 80): 
  - Immediate notification
  - Auto-lock affected vaults
  - Admin review required

- **High** (50-79):
  - User notification
  - Require manual review
  - Flag for security team

- **Medium** (25-49):
  - Log event
  - Optional notification
  - Monitor trend

- **Low** (< 25):
  - Silent logging
  - Normal operations

## 📊 Monitoring Queries

### High-Threat Transfer Requests

```sql
SELECT 
    vtr.id,
    v.name as vault_name,
    vtr.new_owner_email,
    vtr.ml_score,
    vtr.ml_recommendation,
    vtr.threat_index,
    vtr.requested_at
FROM vault_transfer_requests vtr
JOIN vaults v ON v.id = vtr.vault_id
WHERE vtr.threat_index >= 50
  AND vtr.status = 'pending'
ORDER BY vtr.threat_index DESC;
```

### Recent Threat Events

```sql
SELECT 
    te.id,
    v.name as vault_name,
    te.event_type,
    te.severity,
    te.threat_score,
    te.description,
    te.detected_at
FROM threat_events te
LEFT JOIN vaults v ON v.id = te.vault_id
WHERE te.resolved_at IS NULL
ORDER BY te.detected_at DESC
LIMIT 50;
```

### Vault Threat Summary

```sql
SELECT 
    threat_level,
    COUNT(*) as vault_count,
    AVG(threat_index) as avg_threat_index,
    MAX(threat_index) as max_threat_index
FROM vaults
GROUP BY threat_level
ORDER BY 
    CASE threat_level
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END;
```

## 🔧 Troubleshooting

### Threat Index Not Updating

1. Check triggers are installed:
   ```sql
   SELECT trigger_name, event_object_table
   FROM information_schema.triggers
   WHERE trigger_name LIKE '%threat_index%';
   ```

2. Manually recalculate for a vault:
   ```sql
   UPDATE vaults 
   SET threat_index = calculate_vault_threat_index(id),
       threat_level = CASE
           WHEN calculate_vault_threat_index(id) >= 80 THEN 'critical'
           WHEN calculate_vault_threat_index(id) >= 50 THEN 'high'
           WHEN calculate_vault_threat_index(id) >= 25 THEN 'medium'
           ELSE 'low'
       END,
       last_threat_assessment_at = NOW()
   WHERE id = 'your-vault-id';
   ```

### ML Assessment Not Running

1. Verify service is configured in platform code
2. Check service logs for errors
3. Ensure Supabase connection is active
4. Verify RLS policies allow inserts

### Transfer Requests Not Showing

1. Check RLS policies:
   ```sql
   SELECT policyname, cmd, qual
   FROM pg_policies
   WHERE tablename = 'vault_transfer_requests';
   ```

2. Verify user has correct permissions
3. Check transfer request status filters

## 📚 Additional Resources

- **Backend Integration Guide**: `docs/shared/backend/BACKEND_INTEGRATION_GUIDE.md`
- **ML Threat Analysis Guide**: `docs/shared/security/ML_THREAT_ANALYSIS_GUIDE.md`
- **Database Migration Instructions**: `database/DB_MIGRATION_INSTRUCTIONS.md`

## ✅ Next Steps

1. Run database migrations
2. Test threat index calculation
3. Create test transfer requests to verify ML assessment
4. Set up monitoring/alerting for high-threat events
5. Configure real-time subscriptions for threat events (optional)
