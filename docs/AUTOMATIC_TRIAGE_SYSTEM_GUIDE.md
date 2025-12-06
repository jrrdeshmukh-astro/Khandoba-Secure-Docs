# Automatic Triage System - Complete Guide

## ✅ **Feature Complete**

Fully automated threat triage system that analyzes threats, asks pertinent questions, and guides users through remediation without requiring admin intervention.

---

## 🎯 **Overview**

The Automatic Triage System:

- ✅ **Automatically Detects Threats**: Screens all vaults for security issues
- ✅ **Asks Pertinent Questions**: Guides users to understand root causes
- ✅ **Suggests Specific Actions**: Recommends exact remediation steps
- ✅ **Executes Auto-Actions**: Takes immediate action for critical threats
- ✅ **Guided Remediation Flow**: Interactive wizard walks users through fixes
- ✅ **No Admin Required**: Fully automated, no human intervention needed

---

## 🔍 **Threat Detection**

### **1. Screen Monitoring Detection**

**Trigger**: `UIScreen.main.isCaptured == true`

**Automatic Actions:**
- ✅ Close all vaults immediately
- ✅ Record monitoring IP address
- ✅ Revoke all active sessions
- ✅ Start guided remediation flow

**Questions Asked:**
- "Are you aware that screen recording is active?"
- "Did you intentionally start screen recording?"
- "Are you in a secure location?"

**Recommended Actions:**
- Close all vaults
- Record monitoring IP
- Revoke all sessions
- Change all passwords

### **2. Compromised Nominees**

**Detection Criteria:**
- Nominee accessed from >3 unique locations
- Unusual access patterns for nominee
- Geographic anomalies in nominee access

**Questions Asked:**
- "Do you recognize all access locations for these nominees?"
- "Have you authorized access from these locations?"
- "Should these nominees still have access?"

**Recommended Actions:**
- Revoke compromised nominees
- Review access logs
- Enable dual-key protection

### **3. Sensitive Documents Requiring Redaction**

**Detection Criteria:**
- Documents with PHI-related tags (medical, health, patient, SSN, etc.)
- Documents not yet redacted
- Documents shared with nominees

**Questions Asked:**
- "Do these documents contain PHI or sensitive personal information?"
- "Should these documents be redacted for HIPAA compliance?"
- "Are these documents shared with nominees?"

**Recommended Actions:**
- Redact sensitive documents
- Restrict document access
- Review document sharing

### **4. Data Leak Indicators**

**Detection Criteria:**
- Geographic risk score > 0.7
- Access pattern risk score > 0.7
- Exfiltration risk > 0.6

**Automatic Actions:**
- ✅ Lock affected vault

**Questions Asked:**
- "Have you noticed unusual activity in this vault?"
- "Are all access locations authorized?"
- "Have you shared vault access with anyone recently?"
- "Do you recognize all document uploads?"

**Recommended Actions:**
- Lock vault
- Review all access logs
- Revoke all nominees
- Enable enhanced monitoring
- Change vault password

### **5. Brute Force Attacks**

**Detection Criteria:**
- Rapid access patterns detected
- Threat level = High or Critical
- Multiple rapid access attempts

**Automatic Actions:**
- ✅ Lock vault
- ✅ Revoke all sessions

**Questions Asked:**
- "Are you making these rapid access attempts?"
- "Have you shared your vault password?"
- "Do you recognize the access locations?"

**Recommended Actions:**
- Lock vault
- Change vault password
- Revoke all sessions
- Enable dual-key protection
- Review access logs

---

## 🤖 **Automatic Actions**

### **When Auto-Actions Execute**

Auto-actions execute immediately when:
- Threat severity is **Critical**
- Screen monitoring is detected
- Brute force attack detected
- Data leak indicators are high

### **Auto-Action Types**

1. **Close All Vaults**
   - Locks all vaults
   - Ends all active sessions
   - Prevents further access

2. **Lock Vault**
   - Locks specific affected vault
   - Ends vault sessions
   - Requires password to reopen

3. **Record Monitoring IP**
   - Records device identifier/IP
   - Logs in VaultAccessLog
   - Creates security alert entry

4. **Revoke All Sessions**
   - Ends all active vault sessions
   - Forces re-authentication
   - Prevents continued access

---

## 🧭 **Guided Remediation Flow**

### **Flow Structure**

1. **Threat Summary**
   - Shows threat details
   - Displays affected entities
   - Shows severity and priority

2. **Progress Indicator**
   - Shows current step
   - Displays completion percentage
   - Visual progress bar

3. **Questions Phase**
   - One question at a time
   - User types answer
   - System analyzes answer
   - Determines next actions

4. **Actions Phase**
   - Shows recommended actions
   - User can execute actions
   - Confirmation dialogs for destructive actions
   - Tracks completed actions

### **Question-Based Logic**

The system uses answers to determine next steps:

**Example 1: Compromised Nominees**
- Q: "Do you recognize all access locations?"
- A: "No" → Action: Revoke all nominees
- A: "Yes" → Action: Review access logs only

**Example 2: Sensitive Documents**
- Q: "Do these documents contain PHI?"
- A: "Yes" → Action: Redact documents
- A: "No" → Action: Review document sharing

**Example 3: Screen Monitoring**
- Q: "Did you intentionally start recording?"
- A: "No" → Action: Close all vaults, change passwords
- A: "Yes" → Action: Record IP, continue with caution

---

## 📋 **Remediation Actions**

### **Available Actions**

1. **Close All Vaults**
   - Immediately locks all vaults
   - Ends all sessions
   - Requires passwords to reopen

2. **Lock Vault** (specific vault)
   - Locks affected vault
   - Ends vault sessions
   - Prevents access

3. **Revoke Nominees**
   - Revokes specific nominees
   - Sets status to "inactive"
   - Removes vault access

4. **Revoke All Nominees**
   - Revokes all nominees across all vaults
   - Sets all to "inactive"
   - Complete access removal

5. **Revoke All Sessions**
   - Ends all active vault sessions
   - Forces re-authentication
   - Prevents continued access

6. **Redact Documents**
   - Marks documents for redaction
   - Archives redacted documents
   - Permanent action

7. **Restrict Document Access**
   - Archives documents
   - Restricts access
   - Can be restored later

8. **Change Vault Password**
   - Requires new password
   - Updates encryption keys
   - Invalidates old sessions

9. **Change All Passwords**
   - Requires new passwords for all vaults
   - Updates all encryption keys
   - Complete security reset

10. **Record Monitoring IP**
    - Records IP/device identifier
    - Logs in access logs
    - Creates security alert

11. **Review Access Logs**
    - Navigates to access logs view
    - Shows recent activity
    - Helps identify threats

12. **Review Document Sharing**
    - Navigates to sharing settings
    - Shows document sharing status
    - Helps identify leaks

13. **Enable Dual-Key Protection**
    - Enables dual-key for all vaults
    - Requires two approvals
    - Enhanced security

14. **Enable Enhanced Monitoring**
    - Already enabled via TriageView
    - Continuous threat monitoring
    - Real-time alerts

---

## 🔄 **Real-Time Monitoring**

### **Continuous Checks**

- **Threat Analysis**: Every 30 seconds
- **Screen Monitoring**: Every 1 second
- **Automatic Triage**: On threat detection
- **Auto-Actions**: Immediate for critical threats

### **Screen Monitoring**

- Checks `UIScreen.isCaptured` continuously
- Listens to `UIScreen.capturedDidChangeNotification`
- Triggers automatic triage when detected
- Executes auto-actions immediately

---

## 🎯 **User Workflow**

### **When Threat Detected**

1. **Automatic Detection**
   - System detects threat
   - Creates TriageResult
   - Executes auto-actions (if critical)

2. **Notification**
   - Push notification sent
   - TriageView shows threat
   - Guided remediation starts

3. **Guided Questions**
   - User answers questions
   - System determines actions
   - Recommendations updated

4. **Action Execution**
   - User reviews actions
   - Confirms execution
   - Actions performed

5. **Verification**
   - System verifies fixes
   - Threat marked resolved
   - Monitoring continues

### **Example: Screen Monitoring**

1. **Detection**: Screen recording starts
2. **Auto-Action**: All vaults closed immediately
3. **Notification**: "Screen monitoring detected"
4. **Guided Flow Starts**:
   - Q: "Are you aware screen recording is active?"
   - User: "No"
   - Action: Change all passwords recommended
5. **Execution**: User executes password change
6. **Resolution**: Threat resolved, monitoring continues

---

## 📊 **Triage Results Display**

### **TriageView Integration**

- Shows automatic triage results
- Displays threat severity
- Shows affected entities
- "Start Remediation" button
- Integrates with existing threats/leaks

### **Result Card Shows**

- Threat type icon
- Threat title and severity
- Description
- Affected entities (nominees, documents)
- Vault name
- Detection timestamp
- Action button

---

## 🔐 **Security Features**

### **Automatic Protection**

- ✅ **Immediate Response**: Auto-actions for critical threats
- ✅ **Zero Delay**: No waiting for user input
- ✅ **Complete Audit**: All actions logged
- ✅ **IP Recording**: Monitoring IPs tracked
- ✅ **Session Revocation**: Prevents continued access

### **Guided Remediation**

- ✅ **Context-Aware**: Questions based on threat type
- ✅ **Actionable**: Specific, executable recommendations
- ✅ **Safe**: Confirmation for destructive actions
- ✅ **Tracked**: All actions logged and verified

---

## 📝 **Implementation Details**

### **Services**

- `AutomaticTriageService` - Core triage logic
- `ThreatMonitoringService` - Threat detection
- `MLThreatAnalysisService` - ML-based analysis
- `VaultService` - Vault management
- `DocumentService` - Document operations
- `NomineeService` - Nominee management

### **Views**

- `TriageView` - Main triage interface
- `GuidedRemediationWizard` - Interactive remediation flow
- `AutomaticTriageResultsSection` - Results display
- `AutomaticTriageResultRow` - Individual result card

### **Models**

- `TriageResult` - Threat analysis result
- `RemediationFlow` - Guided remediation state
- `RemediationAction` - Executable actions
- `TriageResultType` - Threat categories

---

## 🧪 **Testing**

### **Test Screen Monitoring**

1. Open TriageView
2. Start screen recording (Control Center)
3. Verify:
   - All vaults close automatically
   - Monitoring IP recorded
   - Guided remediation starts
   - Questions appear

### **Test Compromised Nominees**

1. Create nominee with unusual access
2. Open TriageView
3. Verify:
   - Compromised nominee detected
   - Questions about access locations
   - Revoke action recommended

### **Test Sensitive Documents**

1. Upload document with PHI tags
2. Open TriageView
3. Verify:
   - Sensitive document detected
   - Questions about PHI
   - Redaction action recommended

### **Test Brute Force**

1. Rapidly access vault multiple times
2. Open TriageView
3. Verify:
   - Brute force detected
   - Vault locked automatically
   - Sessions revoked
   - Password change recommended

---

## ✅ **Benefits**

### **For Users**

- ✅ **Automatic Protection**: Threats handled automatically
- ✅ **Clear Guidance**: Step-by-step remediation
- ✅ **No Admin Needed**: Self-service security
- ✅ **Immediate Response**: Critical threats handled instantly
- ✅ **Peace of Mind**: System watches 24/7

### **For Security**

- ✅ **Zero-Knowledge**: All analysis on-device
- ✅ **Complete Audit**: All actions logged
- ✅ **Proactive**: Detects threats before damage
- ✅ **Comprehensive**: Multiple detection methods
- ✅ **Actionable**: Specific remediation steps

---

## 📋 **Remediation Examples**

### **Example 1: Screen Monitoring**

**Detection:**
- Screen recording detected
- IP: Device-ABC12345

**Auto-Actions:**
- ✅ Closed all vaults
- ✅ Recorded monitoring IP
- ✅ Revoked all sessions

**Questions:**
1. "Are you aware screen recording is active?"
   - Answer: "No"
   - Action: Change all passwords

2. "Are you in a secure location?"
   - Answer: "Yes"
   - Action: Review access logs

**Result:**
- All vaults secured
- Passwords changed
- Monitoring IP logged
- Threat resolved

### **Example 2: Compromised Nominee**

**Detection:**
- Nominee "John Doe" accessed from 5 locations
- Unusual access pattern

**Questions:**
1. "Do you recognize all access locations?"
   - Answer: "No"
   - Action: Revoke nominee

2. "Should this nominee still have access?"
   - Answer: "No"
   - Action: Remove nominee

**Result:**
- Nominee revoked
- Access removed
- Vault secured
- Threat resolved

### **Example 3: Sensitive Documents**

**Detection:**
- 3 documents with PHI tags
- Not redacted
- Shared with nominees

**Questions:**
1. "Do these documents contain PHI?"
   - Answer: "Yes"
   - Action: Redact documents

2. "Should these be redacted for HIPAA?"
   - Answer: "Yes"
   - Action: Execute redaction

**Result:**
- Documents redacted
- PHI removed
- HIPAA compliant
- Threat resolved

---

## 🔄 **Integration Points**

### **TriageView**

- Runs automatic triage on appear
- Monitors screen capture continuously
- Displays triage results
- Starts guided remediation
- Executes auto-actions

### **SecureNomineeChatView**

- Detects screen monitoring
- Blocks input when recording
- Shows security warnings
- Integrates with triage system

### **VaultService**

- Provides vault data
- Executes lock/close actions
- Manages sessions
- Handles password changes

### **DocumentService**

- Provides document data
- Executes redaction
- Manages document access
- Handles archiving

### **NomineeService**

- Provides nominee data
- Executes revocation
- Manages nominee status
- Handles access removal

---

## 📊 **Monitoring & Logging**

### **All Actions Logged**

- Threat detection events
- Auto-action executions
- User answers to questions
- Remediation actions taken
- Threat resolutions

### **Access Logs**

- Screen monitoring events
- IP addresses recorded
- Security alerts created
- Vault lock events
- Session revocations

---

## 🎯 **Key Features**

### **Automatic**

- ✅ Threat detection
- ✅ Risk assessment
- ✅ Action recommendations
- ✅ Critical threat handling
- ✅ IP recording

### **Guided**

- ✅ Question-based analysis
- ✅ Context-aware recommendations
- ✅ Step-by-step remediation
- ✅ Action confirmation
- ✅ Progress tracking

### **Comprehensive**

- ✅ Multiple threat types
- ✅ Various detection methods
- ✅ Multiple action types
- ✅ Complete audit trail
- ✅ Real-time monitoring

---

**Last Updated**: December 2024  
**Status**: ✅ Fully Implemented  
**Admin Required**: ❌ None - Fully Automated  
**Location**: `Services/AutomaticTriageService.swift`, `Views/Security/GuidedRemediationWizard.swift`
