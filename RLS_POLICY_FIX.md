# Fix RLS Policy Issues

## Problems Identified

1. **`user_roles` INSERT Policy Missing**
   - Error: `new row violates row-level security policy for table "user_roles"`
   - Issue: Users cannot insert their own role during signup
   - Fix: Add INSERT policy allowing users to insert their own role

2. **Infinite Recursion in `vaults` Policy**
   - Error: `infinite recursion detected in policy for relation "vaults"`
   - Issue: Circular dependency between `vaults` and `nominees` policies
   - Fix: Change policies to use `EXISTS` instead of `IN` subqueries

## Root Cause

The circular dependency occurs because:
- `vaults` SELECT policy checks: `id IN (SELECT vault_id FROM nominees ...)`
- `nominees` SELECT policy checks: `vault_id IN (SELECT id FROM vaults ...)`

When PostgreSQL evaluates the `vaults` policy, it needs to check `nominees`, which triggers the `nominees` policy, which checks `vaults` again → infinite loop.

## Solution

### Fix 1: Add `user_roles` INSERT Policy

```sql
CREATE POLICY "user_roles_insert_own"
ON user_roles FOR INSERT
WITH CHECK (auth.uid() = user_id);
```

### Fix 2: Break Circular Dependency Using Security Definer Functions

The issue with `EXISTS` is that it still triggers RLS policies, causing recursion. The proper solution is to use **SECURITY DEFINER functions** that bypass RLS.

**How it works:**
- Security definer functions run with the privileges of the function owner
- They can query tables without triggering RLS policies
- This breaks the circular dependency

**Functions created:**
1. `check_vault_ownership(vault_uuid)` - Checks if user owns a vault (bypasses RLS)
2. `check_nominee_access(vault_uuid)` - Checks if user is an accepted nominee (bypasses RLS)

**Policy example:**
```sql
-- Before (causes recursion):
USING (vault_id IN (SELECT id FROM vaults WHERE owner_id = auth.uid()))

-- After (no recursion):
USING (check_vault_ownership(vault_id))
```

## How to Apply

**⚠️ IMPORTANT: Use Version 2 (with security definer functions)**

1. Open Supabase Dashboard → SQL Editor
2. Copy and paste the contents of `database/fix_rls_policies_v2.sql`
3. Run the script
4. Verify functions are created:
   ```sql
   SELECT routine_name FROM information_schema.routines
   WHERE routine_schema = 'public'
   AND routine_name IN ('check_vault_ownership', 'check_nominee_access');
   ```
5. Verify policies are created:
   ```sql
   SELECT * FROM pg_policies 
   WHERE tablename IN ('user_roles', 'vaults', 'nominees');
   ```

## Expected Results

After applying the fix:
- ✅ Users can insert their own role during signup
- ✅ Vaults can be queried without recursion errors
- ✅ Dashboard data loads successfully
- ✅ Vault list loads successfully

## Testing

After applying the fix, test:
1. Sign in with a new user → Should create user role successfully
2. View dashboard → Should load without recursion errors
3. View vaults list → Should load without recursion errors
4. Create a vault → Should work correctly

---

**Status:** ✅ Use Version 2 (with security definer functions)
**File:** `database/fix_rls_policies_v2.sql`

**Note:** Version 1 (`fix_rls_policies.sql`) uses EXISTS but still causes recursion. Version 2 uses security definer functions which properly break the circular dependency.
