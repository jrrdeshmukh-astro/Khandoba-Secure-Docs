# Database Schema Verification Guide

## Purpose
This guide helps verify that the database schema matches the application models across all platforms (Apple, Android, Windows).

## Platform-Specific User ID Mapping

The `users` table supports three platform-specific user ID columns:
- `apple_user_id` - Used by Apple platforms (iOS, macOS, watchOS, tvOS)
- `google_user_id` - Used by Android
- `microsoft_user_id` - Used by Windows

Each platform should populate only its respective column when creating users.

## Key Schema Mappings

### Users Table
- ✅ `apple_user_id` (Apple) / `google_user_id` (Android) / `microsoft_user_id` (Windows)
- ✅ All platforms: `full_name`, `email`, `profile_picture_url`
- ✅ All platforms: `is_premium_subscriber`, `subscription_expiry_date`

### Vaults Table
- ✅ All platforms: Standard fields (name, owner_id, status, key_type, etc.)
- ✅ `is_broadcast` - For broadcast vaults like "Open Street"
- ✅ `access_level` - Access control for broadcast vaults
- ✅ `threat_index`, `threat_level` - Real-time threat monitoring
- ✅ `is_anti_vault`, `monitored_vault_id`, `anti_vault_id` - Anti-vault support

### Documents Table
- ✅ `ai_tags` - Stored as TEXT[] array (PostgreSQL array type)
- ✅ `metadata` - Stored as JSONB
- ✅ `storage_path` - Path in Supabase Storage
- ✅ `encryption_key_data` - BYTEA type

### Nominees Table
- ✅ `selected_document_ids` - UUID[] array for subset access
- ✅ `access_level` - 'read', 'write', 'admin'
- ✅ `is_subset_access` - Boolean flag
- ✅ `session_expires_at` - Time-bound access

### Document Versions Table
- ✅ Unique constraint on (document_id, version_number)
- ✅ `storage_path` for versioned file storage

### Chat Messages Table
- ✅ `is_from_system` - Boolean (for LLM/system messages)
- ✅ `receiver_id` - Optional (for direct messages)
- ✅ `vault_id` - Optional (for vault-specific chat)

## Verification Checklist

### 1. Table Existence
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
```
Expected: 17 tables

### 2. Column Types
Verify critical columns match model expectations:

```sql
-- Users table platform IDs
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
AND column_name IN ('apple_user_id', 'google_user_id', 'microsoft_user_id');

-- Documents AI tags (should be array)
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_name = 'documents'
AND column_name = 'ai_tags';

-- Nominees selected document IDs (should be array)
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_name = 'nominees'
AND column_name = 'selected_document_ids';
```

### 3. Indexes
Verify indexes exist for performance:

```sql
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

### 4. Foreign Keys
Verify relationships:

```sql
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name;
```

### 5. RLS Policies
Verify security policies:

```sql
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### 6. Functions
Verify threat monitoring functions:

```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;
```
Expected: calculate_vault_threat_index, update_vault_threat_index, assess_transfer_request_threat

### 7. Triggers
Verify automatic updates:

```sql
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
ORDER BY event_object_table, trigger_name;
```

## Platform-Specific Verification

### Apple Platform
- Verify `apple_user_id` column exists and is used in user creation
- Check SupabaseUser model matches schema

### Android Platform  
- Verify `google_user_id` column exists and is used
- Check SupabaseUser model in SupabaseService.kt matches schema

### Windows Platform
- Verify `microsoft_user_id` column exists and is used
- Check SupabaseUser model in SupabaseModels.cs matches schema

## Common Issues

### Array Type Mismatches
- PostgreSQL arrays (UUID[], TEXT[]) vs JSON arrays in models
- Application layer should handle conversion (UUID array ↔ JSON)

### JSONB vs JSON
- `metadata` fields use JSONB (PostgreSQL native)
- Application should serialize/deserialize JSON objects

### Timestamp Formats
- Database uses TIMESTAMPTZ (timezone-aware)
- Application models should handle timezone conversion

### Nullable Fields
- Many fields are nullable for flexibility
- Application logic should handle NULL values appropriately

## Testing

After schema verification, test:
1. User creation (platform-specific ID)
2. Vault creation
3. Document upload
4. Nominee invitation
5. Transfer request creation
6. Threat event creation
7. Threat index calculation
