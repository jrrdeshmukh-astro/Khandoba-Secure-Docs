# Supabase Migration Testing Checklist

## Pre-Testing Setup

- [ ] Supabase project created
- [ ] Database schema applied (`database/schema.sql`)
- [ ] RLS policies applied (`database/rls_policies.sql`)
- [ ] Storage buckets created (encrypted-documents, voice-memos, intel-reports)
- [ ] Storage policies configured
- [ ] Apple Sign In OAuth configured in Supabase
- [ ] `SupabaseConfig.swift` updated with credentials
- [ ] `AppConfig.useSupabase = true` set

## Authentication Testing

### Sign In Flow
- [ ] New user can sign in with Apple
- [ ] User record created in Supabase `users` table
- [ ] User role created in `user_roles` table
- [ ] Session stored correctly
- [ ] Profile picture uploaded to Storage (if provided)

### Existing User
- [ ] Existing user can sign in
- [ ] User data loaded from Supabase
- [ ] Session persists across app restarts
- [ ] Sign out works correctly

### Edge Cases
- [ ] Invalid credentials handled gracefully
- [ ] Network errors handled
- [ ] Session expiry handled

## Vault Testing

### Vault Operations
- [ ] Create vault - appears in Supabase
- [ ] Load vaults - RLS filters correctly
- [ ] Update vault - changes saved
- [ ] Delete vault - removed from Supabase
- [ ] Vault owner can see their vaults
- [ ] Nominees can see shared vaults
- [ ] Users cannot see other users' vaults

### Vault Sessions
- [ ] Open vault creates session
- [ ] Session expires after 30 minutes
- [ ] Session extension works
- [ ] Close vault ends session
- [ ] Sessions visible in `vault_sessions` table

### Access Logs
- [ ] Vault access logged
- [ ] Document access logged
- [ ] Location data captured (if available)
- [ ] Logs visible in `vault_access_logs` table

## Document Testing

### Upload
- [ ] Upload document - file stored in Storage
- [ ] Document record created in `documents` table
- [ ] File encrypted before upload
- [ ] Encryption key stored in Keychain (not database)
- [ ] Storage path stored in document record
- [ ] Upload progress updates correctly
- [ ] Large files handled (>10MB)

### Download
- [ ] Download document - file retrieved from Storage
- [ ] File decrypted correctly
- [ ] Decrypted data matches original
- [ ] Download works for different file types

### Document Operations
- [ ] Delete document - file removed from Storage
- [ ] Delete document - record removed from database
- [ ] Archive document - status updated
- [ ] Rename document - name updated
- [ ] Document search works
- [ ] AI tags generated and stored

### File Types
- [ ] Images (JPG, PNG, HEIC)
- [ ] PDFs
- [ ] Videos (MP4, MOV)
- [ ] Audio (M4A, MP3)
- [ ] Documents (DOCX, XLSX)

## Nominee/Sharing Testing

### Invite Nominee
- [ ] Create nominee invitation
- [ ] Nominee record created in `nominees` table
- [ ] Invitation sent (email/SMS if implemented)
- [ ] Nominee can see invitation

### Accept Invitation
- [ ] Nominee can accept invitation
- [ ] Status updated to "accepted"
- [ ] Nominee can access shared vault
- [ ] RLS allows nominee to see vault

### Remove Nominee
- [ ] Remove nominee - status updated to "revoked"
- [ ] Nominee loses access to vault
- [ ] RLS prevents access after removal

### Access Control
- [ ] Nominee can only see shared vaults
- [ ] Nominee cannot see other vaults
- [ ] Owner can see all their vaults
- [ ] Access level (read/write/admin) enforced

## Chat Testing

### Send Message
- [ ] Send message - stored in `chat_messages` table
- [ ] Message encrypted before storage
- [ ] Encryption key in Keychain
- [ ] Message appears in conversation

### Receive Message
- [ ] Load conversations - messages retrieved
- [ ] Messages decrypted correctly
- [ ] Real-time updates work (if enabled)
- [ ] Unread counts accurate

### Encryption
- [ ] Messages encrypted end-to-end
- [ ] Server cannot decrypt messages
- [ ] Keys stored in Keychain only

## Real-time Testing

### Subscriptions
- [ ] Vault updates appear in real-time
- [ ] Document updates appear in real-time
- [ ] Nominee status changes appear in real-time
- [ ] Chat messages appear in real-time
- [ ] Connection state handled correctly

### Edge Cases
- [ ] Network disconnection handled
- [ ] Reconnection works
- [ ] Multiple devices sync correctly

## Performance Testing

### Load Testing
- [ ] Load 100+ vaults - performance acceptable
- [ ] Load 1000+ documents - performance acceptable
- [ ] Search across large dataset - fast
- [ ] RLS doesn't significantly impact performance

### Network Testing
- [ ] Works on slow network
- [ ] Offline mode handled (if implemented)
- [ ] Retry logic works for failed requests
- [ ] Timeout handling works

## Security Testing

### RLS Policies
- [ ] User can only see own data
- [ ] Nominees can only see shared vaults
- [ ] Users cannot access other users' files
- [ ] Service role key not exposed to client

### Encryption
- [ ] Files encrypted before upload
- [ ] Keys in Keychain (not database)
- [ ] Server cannot decrypt data
- [ ] Zero-knowledge architecture maintained

### Access Control
- [ ] Unauthorized access blocked
- [ ] Token expiry handled
- [ ] Session timeout works
- [ ] Audit trail complete

## Integration Testing

### End-to-End Flows
- [ ] Complete user journey: Sign in → Create vault → Upload document → Share → Access
- [ ] Nominee journey: Receive invite → Accept → Access vault → Chat
- [ ] Document lifecycle: Upload → View → Edit → Delete

### Cross-Device
- [ ] Data syncs across devices
- [ ] Real-time updates on all devices
- [ ] Conflicts handled (if applicable)

## Error Handling

### Network Errors
- [ ] Offline mode handled
- [ ] Connection timeout handled
- [ ] Server errors handled gracefully
- [ ] User-friendly error messages

### Data Errors
- [ ] Invalid data rejected
- [ ] Missing data handled
- [ ] Corrupted files handled
- [ ] Database errors handled

## Rollback Testing

### Fallback Mode
- [ ] Set `AppConfig.useSupabase = false`
- [ ] App uses SwiftData/CloudKit
- [ ] All features work in fallback mode
- [ ] No data loss when switching modes

## Production Readiness

### Before Enabling
- [ ] All tests pass
- [ ] Performance acceptable
- [ ] Security verified
- [ ] Error handling complete
- [ ] Monitoring set up (if applicable)
- [ ] Backup strategy in place

### Monitoring
- [ ] Supabase Dashboard monitoring enabled
- [ ] Error logs reviewed
- [ ] Performance metrics tracked
- [ ] User feedback collected

## Test Results Template

```
Date: ___________
Tester: ___________
Environment: [ ] Development [ ] Staging [ ] Production

Authentication: [ ] Pass [ ] Fail [ ] Notes: ___________
Vault Operations: [ ] Pass [ ] Fail [ ] Notes: ___________
Document Operations: [ ] Pass [ ] Fail [ ] Notes: ___________
Sharing: [ ] Pass [ ] Fail [ ] Notes: ___________
Chat: [ ] Pass [ ] Fail [ ] Notes: ___________
Real-time: [ ] Pass [ ] Fail [ ] Notes: ___________
Security: [ ] Pass [ ] Fail [ ] Notes: ___________
Performance: [ ] Pass [ ] Fail [ ] Notes: ___________

Overall: [ ] Ready for Production [ ] Needs Work

Issues Found:
1. ___________
2. ___________
3. ___________
```

## Next Steps After Testing

1. Fix any issues found
2. Re-test fixed issues
3. Performance optimization if needed
4. Documentation updates
5. Production deployment
