# Basic Concepts

Understand the core concepts of Khandoba Secure Docs.

---

## Core Concepts

### Vaults

**Definition**: Encrypted containers for documents

**Characteristics:**
- Each vault is independently encrypted
- Can be single-key or dual-key
- Contains multiple documents
- Has its own security settings

**Analogy**: Like a bank safe deposit box - secure, organized, access-controlled

---

### Documents

**Definition**: Files stored in vaults

**Types:**
- Photos (JPG, PNG, HEIC)
- Videos (MP4, MOV)
- PDFs
- Voice memos (M4A, MP3)
- Other file types

**Features:**
- Automatically encrypted
- AI-tagged and organized
- Searchable
- Versioned (if updated)

---

### Nominees

**Definition**: Trusted users with vault access

**Types:**
- **Full Access**: All documents in vault
- **Subset Access**: Selected documents only
- **Time-Bound**: Access expires after set time

**Status:**
- **Pending**: Invitation sent, not yet accepted
- **Accepted**: Active access
- **Inactive**: Access revoked
- **Revoked**: Permanently removed

---

### AI Intelligence

**Definition**: Automated analysis and insights

**Components:**
- **Voice Reports**: Narrated security briefings
- **Auto-Tagging**: Automatic document categorization
- **Threat Detection**: ML-based security monitoring
- **Source/Sink Classification**: Document origin tracking

---

## Security Concepts

### Encryption

**AES-256 Encryption**
- Military-grade encryption standard
- All documents encrypted before storage
- Zero-knowledge architecture (we can't decrypt)

**Key Management**
- Encryption keys stored on device
- Never transmitted to servers
- Backed up securely via CloudKit

---

### Authentication

**Biometric Authentication**
- Face ID or Touch ID
- Required for vault access
- Stored only on device

**Password Protection**
- For single-key vaults
- Strong passwords recommended
- Never stored in plain text

---

### Access Control

**Single-Key Vaults**
- Password + biometric
- Quick access
- Standard security

**Dual-Key Vaults**
- ML-based approval
- Enhanced security
- Complete audit trail

---

## AI & ML Concepts

### Machine Learning Auto-Approval

**How It Works:**
1. Access request received
2. ML analyzes:
   - User history
   - Geographic location
   - Time patterns
   - Device information
3. Decision made:
   - **Approve**: Safe access pattern
   - **Deny**: Suspicious activity
   - **Review**: Needs manual check

**Accuracy**: 99%+ automatic approval rate

---

### Source/Sink Classification

**Source Documents**
- Created by you
- Examples: Photos you took, documents you created

**Sink Documents**
- Received from others
- Examples: Emails, shared files, downloads

**Why It Matters:**
- Understand document origins
- Detect unusual patterns
- Security analysis

---

### Geographic Intelligence

**Impossible Travel Detection**
- Tracks access locations
- Detects physically impossible travel
- Example: NYC at 3 PM, LA at 3:30 PM = Auto-deny

**Location Tracking**
- GPS coordinates logged
- Shown on Access Map
- Privacy-respecting (only for security)

---

## Data Concepts

### Cloud Sync

**CloudKit Integration**
- Automatic sync across devices
- Encrypted in transit and at rest
- Apple's secure infrastructure

**Supabase Integration** (if enabled)
- Alternative cloud storage
- Same encryption standards
- Cross-platform support

---

### Data Retention

**Active Accounts**
- Data retained while account active
- Automatic backups
- Cross-device sync

**Deleted Accounts**
- Data permanently deleted within 30 days
- No recovery possible
- Complete removal from all systems

---

## Subscription Concepts

### Premium Subscription

**Required for:**
- All app features
- Unlimited storage
- AI features
- Premium security

**Plans:**
- Monthly: $9.99/month
- Yearly: $71.88/year (Save 40%)
- 7-day free trial

---

### Free Trial

**Duration**: 7 days

**Includes**: All premium features

**Cancellation**: Cancel anytime during trial (no charge)

**Conversion**: Automatically converts to paid subscription if not cancelled

---

## Workflow Concepts

### Document Upload Flow

1. **Select File**: Choose from library or camera
2. **Encrypt**: Document encrypted on device
3. **Upload**: Encrypted data uploaded to cloud
4. **Index**: AI analyzes and tags document
5. **Store**: Document stored in vault
6. **Sync**: Synced across all devices

---

### Nominee Invitation Flow

1. **Select Nominee**: Choose from contacts
2. **Set Access**: Full or subset access
3. **Send Invitation**: CloudKit share created
4. **Nominee Accepts**: Accepts invitation
5. **Access Granted**: Can now access vault
6. **Activity Logged**: All access tracked

---

### Voice Report Generation

1. **Request Report**: Tap "Generate Voice Report"
2. **Analysis**: AI analyzes vault contents
3. **Narrative**: Creates natural language summary
4. **Synthesis**: Text-to-speech conversion
5. **Save**: Voice memo saved to vault
6. **Playback**: Listen to report

---

## Best Practices

### Organization

- **Use Multiple Vaults**: Organize by purpose
- **Clear Names**: Descriptive vault names
- **Regular Cleanup**: Archive or delete unused vaults

### Security

- **Use Dual-Key**: For sensitive documents
- **Strong Passwords**: For single-key vaults
- **Regular Reviews**: Check access logs

### Sharing

- **Selective Sharing**: Only nominate trusted users
- **Subset Access**: Limit access when possible
- **Time-Bound**: Set expiration dates

---

## Next Steps

Now that you understand the concepts:
1. [Create Your First Vault](first-vault.md)
2. [Upload Documents](../user-guide/documents.md)
3. [Explore AI Features](../user-guide/ai-features.md)
4. [Learn About Security](../user-guide/security.md)

---

## Support

Questions about concepts?
- **Email**: support@khandoba.org
- **Website**: https://khandoba.org/support

---

**Ready to get started?** Continue to [Quick Start Guide](quick-start.md)
