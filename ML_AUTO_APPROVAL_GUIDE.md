# 🤖 ML-Based Dual-Key Auto-Approval System

## 🎯 **Overview**

Khandoba now features an **intelligent ML-based dual-key approval system** that automatically approves or denies vault access requests based on:

- ✅ **Threat metrics** (anomaly scores, access patterns)
- ✅ **Geospatial analysis** (location, impossible travel)
- ✅ **Behavioral patterns** (user history, typical hours)

**No more manual approvals for low-risk requests!** The system handles it automatically while flagging suspicious activity.

---

## 🧠 **How ML Auto-Approval Works**

### **Decision Matrix**

```
ML Score < 30  → 🟢 AUTO-APPROVE (Low Risk)
ML Score 30-70 → 🟡 MANUAL REVIEW (Medium Risk)
ML Score > 70  → 🔴 AUTO-DENY (High Risk)
```

### **Score Calculation**

The ML system combines three weighted factors:

```swift
ML Score = (Threat Score × 40%) + 
           (Geo Risk × 40%) + 
           (Behavior Score × 20%)
```

---

## 📊 **Factor 1: Threat Score (40% weight)**

### **What It Analyzes:**

| Indicator | Points Added | Trigger |
|-----------|--------------|---------|
| Vault Threat Level | 10-90 | Low=10, Medium=30, High=60, Critical=90 |
| Rapid Access Attempts | +25 | 5+ attempts in 60 seconds |
| Failed Attempts | +5 each | Any failed access |
| Night Access Frequency | +20 | >50% accesses at night (10PM-6AM) |

### **Example:**

```
Vault A:
├─ Threat Level: High (+60 points)
├─ Rapid Access: Yes (+25 points)
├─ Failed Attempts: 2 (+10 points)
└─ Night Access: 60% (+20 points)

Threat Score: 115 → Capped at 100
```

---

## 🌍 **Factor 2: Geospatial Risk (40% weight)**

### **What It Analyzes:**

| Distance from Home/Office | Risk Points |
|---------------------------|-------------|
| < 10 km | 0 (Very close) |
| 10-50 km | +10 (Nearby) |
| 50-100 km | +25 (Same region) |
| 100-500 km | +40 (Different city) |
| > 500 km | +60 (International) |

### **Additional Checks:**

- **Impossible Travel Detection:**
  - Distance > 500 km AND Time < 1 hour → +40 points
  - Example: Portland to NYC in 45 minutes

- **Location Clustering:**
  - System learns your typical locations (home, office)
  - Flags access from unusual areas

### **Example:**

```
Request Location: San Francisco
User's Typical Locations: 
  ├─ Home: New York (4,130 km away)
  └─ Office: Boston (4,200 km away)

Last Access: New York, 2 hours ago

Analysis:
├─ Distance: 4,130 km (+60 points)
├─ Travel Time: 2 hours
├─ Impossible Travel: NO (physically possible in 2 hours by plane)
└─ Geo Risk Score: 60/100
```

---

## 👤 **Factor 3: Behavior Score (20% weight)**

### **What It Analyzes:**

| Pattern | Points | Reason |
|---------|--------|--------|
| First-time access | +30 | No baseline behavior |
| Too frequent access | +20 | Multiple times/day (bot-like) |
| Dormant account active | +15 | No access for 30+ days |
| Unusual access time | +15 | Outside typical hours |

### **Typical Hours Learning:**

The system learns when each user typically accesses vaults:

```
User John's Pattern:
├─ Typical Hours: 9AM-5PM (weekdays)
├─ Current Request: 2AM Saturday
└─ Behavior Score: +15 (unusual time)
```

---

## 🎯 **Combined ML Decision**

### **Example: AUTO-APPROVE Scenario**

```
User Request: Access "Client Contracts" vault

ML Analysis:
├─ Threat Score: 15/100
│   ├─ Vault Threat Level: Low (+10)
│   ├─ Rapid Access: No (+0)
│   ├─ Failed Attempts: 0 (+0)
│   └─ Night Access: 20% (+5)
│
├─ Geo Risk: 10/100
│   ├─ Distance from home: 8 km (+0)
│   ├─ Impossible Travel: No (+0)
│   └─ Typical location: Yes (+10)
│
└─ Behavior Score: 5/100
    ├─ First-time: No (+0)
    ├─ Typical hour: Yes (+0)
    └─ Normal frequency: Yes (+5)

Combined ML Score: (15×0.4) + (10×0.4) + (5×0.2) = 11/100

Decision: ✅ AUTO-APPROVE
Reason: "Low risk score (11/100). All security metrics 
         within safe thresholds."
Confidence: 89%
```

### **Example: AUTO-DENY Scenario**

```
User Request: Access "Financial Records" vault

ML Analysis:
├─ Threat Score: 90/100
│   ├─ Vault Threat Level: Critical (+90)
│   ├─ Recent failed attempts: 5 (+25) [capped at 100]
│
├─ Geo Risk: 100/100
│   ├─ Distance: 3,200 km from typical (+60)
│   ├─ Impossible Travel: YES! (+40)
│   │   └─ NYC → LA in 30 minutes
│   └─ Unknown location (+0)
│
└─ Behavior Score: 45/100
    ├─ First-time from this user: Yes (+30)
    ├─ Access time: 3AM (+15)
    └─ Dormant account: No (+0)

Combined ML Score: (90×0.4) + (100×0.4) + (45×0.2) = 85/100

Decision: 🚫 AUTO-DENY
Reason: "High risk score (85/100). Suspicious activity detected. 
         Review security logs immediately."
Confidence: 85%
```

### **Example: MANUAL REVIEW Scenario**

```
User Request: Access "Research Documents" vault

ML Analysis:
├─ Threat Score: 30/100
│   ├─ Vault Threat Level: Medium (+30)
│
├─ Geo Risk: 40/100
│   ├─ Distance: 150 km from typical (+25)
│   ├─ Different city but feasible (+15)
│
└─ Behavior Score: 15/100
    ├─ Unusual hour: 8PM (+15)
    └─ But within weekly pattern (+0)

Combined ML Score: (30×0.4) + (40×0.4) + (15×0.2) = 31/100

Decision: ⚠️ MANUAL REVIEW REQUIRED
Reason: "Moderate risk score (31/100). Please review the 
         access details before approving."
Confidence: 50%
```

---

## 🔄 **Implementation Flow**

### **Step-by-Step Process:**

```
1. User requests dual-key vault access
         ↓
2. DualKeyApprovalService.processDualKeyRequest()
         ↓
3. Calculate Threat Score
   ├─ Analyze vault threat level
   ├─ Check recent access patterns
   ├─ Detect rapid attempts
   └─ Calculate night access %
         ↓
4. Calculate Geospatial Risk
   ├─ Get current location
   ├─ Find typical user locations
   ├─ Calculate distances
   ├─ Detect impossible travel
   └─ Assess location familiarity
         ↓
5. Analyze Behavior Patterns
   ├─ Check first-time access
   ├─ Analyze frequency patterns
   ├─ Verify typical hours
   └─ Check account dormancy
         ↓
6. Calculate Combined ML Score
   (Weighted average of 3 factors)
         ↓
7. Make ML Decision
   ├─ Score < 30  → AUTO-APPROVE ✅
   ├─ Score 30-70 → MANUAL REVIEW ⚠️
   └─ Score > 70  → AUTO-DENY 🚫
         ↓
8. Log Decision
   (Save to DualKeyDecisionLog)
         ↓
9. Execute Decision
   ├─ Update request status
   ├─ Notify user
   └─ Create access log
```

---

## 💻 **Code Usage**

### **Auto-Process Dual-Key Request:**

```swift
import SwiftUI

struct DualKeyRequestView: View {
    let request: DualKeyRequest
    let vault: Vault
    
    @StateObject private var approvalService = DualKeyApprovalService()
    @State private var decision: DualKeyDecision?
    @State private var isProcessing = false
    
    var body: some View {
        VStack {
            if let decision = decision {
                DecisionResultView(decision: decision)
            } else {
                Button("Process Request with ML") {
                    processRequest()
                }
            }
        }
    }
    
    private func processRequest() {
        isProcessing = true
        
        Task {
            do {
                let mlDecision = try await approvalService.processDualKeyRequest(
                    request,
                    vault: vault
                )
                
                await MainActor.run {
                    decision = mlDecision
                    isProcessing = false
                }
                
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
```

### **Check Decision History:**

```swift
// Query ML decision logs
let logs = try modelContext.fetch(
    FetchDescriptor<DualKeyDecisionLog>(
        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
)

for log in logs {
    print("Vault: \(log.vaultName)")
    print("ML Score: \(log.mlScore)")
    print("Action: \(log.action)")
    print("Confidence: \(log.confidence)")
}
```

---

## 📈 **ML Model Performance**

### **Accuracy Metrics:**

- **True Positives:** Correctly auto-approved safe requests
- **True Negatives:** Correctly auto-denied malicious requests
- **False Positives:** Safe request incorrectly denied (requires manual override)
- **False Negatives:** Malicious request incorrectly approved (caught by monitoring)

### **Threshold Tuning:**

Adjust thresholds based on your security posture:

```swift
// Conservative (higher security)
private let autoApproveThreshold: Double = 20.0  // Stricter
private let autoDenyThreshold: Double = 60.0     // More denials

// Balanced (default)
private let autoApproveThreshold: Double = 30.0
private let autoDenyThreshold: Double = 70.0

// Permissive (convenience)
private let autoApproveThreshold: Double = 40.0
private let autoDenyThreshold: Double = 80.0     // Fewer denials
```

---

## 🔐 **Security Benefits**

### **1. Automated Security Response**
- No human delay in threat response
- Instant denial of high-risk requests
- 24/7 monitoring without manual intervention

### **2. Reduced False Approvals**
- ML catches patterns humans miss
- Geographic anomalies detected instantly
- Impossible travel flagged automatically

### **3. User Convenience**
- Low-risk requests approved instantly
- No waiting for manual approval
- Legitimate access never delayed

### **4. Audit Trail**
- Every decision logged with reasoning
- ML confidence scores recorded
- Full transparency for compliance

---

## 🎓 **Learning & Adaptation**

### **How the System Learns:**

1. **Location Clustering:**
   - Identifies your home/office from access history
   - Updates as patterns change
   - Learns new typical locations over time

2. **Time Pattern Recognition:**
   - Learns your typical working hours
   - Adapts to schedule changes
   - Recognizes weekly/monthly patterns

3. **Behavior Baseline:**
   - Establishes normal access frequency
   - Detects deviations from baseline
   - Adapts to new normal over time

### **Continuous Improvement:**

The system gets smarter with each request:
- More data → Better clustering
- Longer history → Accurate patterns
- User feedback → Threshold tuning

---

## 🚨 **Edge Cases Handled**

### **New Users:**
- No baseline → Medium risk (manual review)
- Gradually builds profile over time

### **Travel Scenarios:**
- Legitimate travel detected vs impossible travel
- Time zones considered
- Business travel patterns learned

### **Location Spoofing:**
- Impossible travel detection
- Velocity checks
- Pattern disruption alerts

### **Account Takeover:**
- Sudden behavior changes flagged
- Multiple failed attempts blocked
- Geographic anomalies detected

---

## 📊 **Dashboard Metrics**

Track ML performance in admin dashboard:

```
ML Auto-Approval Statistics (Last 30 Days)
├─ Total Requests: 1,247
├─ Auto-Approved: 892 (71.5%)
├─ Auto-Denied: 43 (3.4%)
├─ Manual Review: 312 (25.1%)
│
├─ Average ML Score: 28.3/100
├─ Average Processing Time: 0.8 seconds
│
└─ Decision Accuracy:
    ├─ Correct Auto-Approvals: 99.2%
    ├─ Correct Auto-Denials: 100%
    └─ Manual Overrides: 2 (0.6%)
```

---

## 🎯 **Best Practices**

### **For Administrators:**

1. **Review ML Logs Weekly:**
   - Check auto-denied requests
   - Look for false positives
   - Adjust thresholds if needed

2. **Monitor Geographic Patterns:**
   - Verify typical locations are correct
   - Update for office relocations
   - Add new authorized locations

3. **Tune Sensitivity:**
   - High-security vaults: Lower auto-approve threshold
   - Convenience vaults: Higher threshold

### **For Users:**

1. **Enable Location Services:**
   - Required for geospatial analysis
   - Improves accuracy
   - Enables impossible travel detection

2. **Consistent Access Patterns:**
   - Regular usage builds better baseline
   - Sudden changes may trigger review

3. **Report False Denials:**
   - Helps improve ML accuracy
   - Threshold auto-adjusts

---

## 🔮 **Future Enhancements**

### **Planned ML Improvements:**

1. **Device Fingerprinting:**
   - Recognize authorized devices
   - Flag access from new devices

2. **Network Analysis:**
   - VPN detection
   - Corporate network recognition

3. **Biometric Confirmation:**
   - Face ID/Touch ID integration
   - Additional verification layer

4. **Collaborative Intelligence:**
   - Anonymous threat sharing
   - Industry-wide threat patterns

---

## ✅ **Summary**

The ML-based dual-key auto-approval system provides:

- ✅ **Automated security** - Instant decisions, no delays
- ✅ **Intelligent analysis** - Multi-factor risk assessment
- ✅ **Geographic awareness** - Location-based risk scoring
- ✅ **Behavioral learning** - Adapts to user patterns
- ✅ **Audit compliance** - Full decision trail
- ✅ **User convenience** - Low-risk requests auto-approved

**Result:** Enterprise-grade security with consumer-grade convenience! 🎯🔐

