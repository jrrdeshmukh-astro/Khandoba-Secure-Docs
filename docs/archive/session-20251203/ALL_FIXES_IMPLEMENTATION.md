# 🔧 All Fixes Implementation

**Status:** ⏳ IN PROGRESS  
**Date:** December 2025

---

## ✅ FIXED SO FAR:

### 1. Access Map - Fixed Location Calculation ✅
**Problem:** Map defaulted to San Francisco instead of actual access locations

**Solution:**
- Updated `loadAccessPoints()` to call `calculateMapRegion()`
- Implemented `calculateMapRegion()` to:
  - Handle single location (tight zoom)
  - Handle multiple locations (bounding box with padding)
  - Calculate center from all coordinates
  - Add 50% padding for better visibility

**File:** `Views/Security/AccessMapView.swift`
**Status:** ✅ Complete

---

## ⏳ REMAINING FIXES:

### 2. iMessage Contact Picker - Not Working
**Problem:** Missing sheet presentations

**Solution Needed:**
```swift
// File: Views/Vaults/VaultDetailView.swift

// Add these @State variables (already added):
@State private var showContactPicker = false
@State private var showMessageComposer = false
@State private var selectedContacts: [CNContact] = []

// Add these sheet modifiers after existing sheets:
.sheet(isPresented: $showContactPicker) {
    ContactPickerView(
        vault: vault,
        onContactsSelected: { contacts in
            sendMessageToContacts(contacts)
        },
        onDismiss: {
            showContactPicker = false
        }
    )
}

.sheet(isPresented: $showMessageComposer) {
    if !selectedContacts.isEmpty {
        let phoneNumbers = selectedContacts.flatMap { contact in
            contact.phoneNumbers.compactMap { $0.value.stringValue }
        }
        MessageComposeView(
            recipients: phoneNumbers,
            message: "I'm sharing my secure vault '\(vault.name)' with you. Access it in Khandoba Secure Docs.",
            onDismiss: {
                showMessageComposer = false
                selectedContacts = []
            }
        )
    }
}
```

---

### 3. Transfer Ownership Flow - Incomplete
**Problem:** Flow not implemented

**Solution Needed:**
```swift
// File: Views/Vaults/VaultTransferView.swift (NEW)

struct VaultTransferView: View {
    let vault: Vault
    @Environment(\.dismiss) var dismiss
    @State private var selectedNominee: Nominee?
    @State private var isTransferring = false
    
    var body: some View {
        // Show list of nominees
        // Select nominee
        // Confirm transfer
        // Create VaultTransferRequest
        // Set status to "pending"
        // Show success
    }
    
    private func initiateTransfer() async {
        // Create transfer request
        let request = VaultTransferRequest(
            vault: vault,
            fromUser: currentUser,
            toUser: selectedNominee?.user,
            status: "pending"
        )
        // Save to database
        // Notify admin
    }
}
```

**Integration:**
- Add "Transfer Ownership" button to VaultDetailView
- Navigate to VaultTransferView
- Show existing pending transfer if any

---

### 4. Dual-Key Pending Request Indicator
**Problem:** Client can't see if unlock request is pending

**Solution Needed:**
```swift
// File: Views/Vaults/VaultDetailView.swift

// Check for pending dual-key requests:
private var hasPendingUnlockRequest: Bool {
    guard vault.keyType == "dual" else { return false }
    
    let pendingRequests = (vault.dualKeyRequests ?? []).filter { 
        $0.status == "pending" && 
        $0.requestType == "unlock" &&
        $0.requestedBy?.id == authService.currentUser?.id
    }
    
    return !pendingRequests.isEmpty
}

// Show indicator in UI:
if vault.keyType == "dual" && !hasActiveSession {
    if hasPendingUnlockRequest {
        // Show "Request Pending" banner
        StandardCard {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(colors.warning)
                Text("Unlock request pending admin approval")
                    .font(theme.typography.subheadline)
                Spacer()
            }
            .padding()
        }
        .padding(.horizontal)
    } else {
        // Show "Request Access" button
        StandardButton("Request Dual-Key Access") {
            requestDualKeyAccess()
        }
        .padding(.horizontal)
    }
}
```

---

### 5. Documents Tab - Intel Report Creation
**Problem:** No way to select documents and create Intel reports

**Solution Needed:**

#### Part A: Add Selection Mode to DocumentSearchView
```swift
// File: Views/Documents/DocumentSearchView.swift

@State private var isSelectionMode = false
@State private var selectedDocumentIDs: Set<UUID> = []

// Add toolbar buttons:
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        if isSelectionMode {
            Button("Cancel") {
                isSelectionMode = false
                selectedDocumentIDs.removeAll()
            }
        }
    }
    
    ToolbarItem(placement: .navigationBarTrailing) {
        if isSelectionMode {
            Button("Compile Intel Report (\(selectedDocumentIDs.count))") {
                compileIntelReport()
            }
            .disabled(selectedDocumentIDs.count < 2)
        } else {
            Menu {
                Button {
                    showFilters = true
                } label: {
                    Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                }
                
                Button {
                    isSelectionMode = true
                } label: {
                    Label("Select for Intel Report", systemImage: "checkmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

// Update document rows to show checkboxes in selection mode:
ForEach(searchResults) { document in
    HStack {
        if isSelectionMode {
            Image(systemName: selectedDocumentIDs.contains(document.id) ? 
                "checkmark.circle.fill" : "circle")
                .foregroundColor(selectedDocumentIDs.contains(document.id) ? 
                    colors.primary : colors.textTertiary)
                .font(.title2)
                .onTapGesture {
                    if selectedDocumentIDs.contains(document.id) {
                        selectedDocumentIDs.remove(document.id)
                    } else {
                        selectedDocumentIDs.insert(document.id)
                    }
                }
        }
        
        NavigationLink {
            DocumentPreviewView(document: document)
        } label: {
            DocumentRow(document: document)
        }
        .disabled(isSelectionMode)
    }
}
```

#### Part B: Compile Intel Report
```swift
// Add method to DocumentSearchView:
private func compileIntelReport() {
    let selected = searchResults.filter { selectedDocumentIDs.contains($0.id) }
    
    Task {
        do {
            let report = try await IntelReportService.shared.compileReportFromDocuments(selected)
            
            // Save to Intel Vault
            try await IntelReportService.shared.saveToIntelVault(report, for: authService.currentUser)
            
            // Show success
            isSelectionMode = false
            selectedDocumentIDs.removeAll()
            
            // Show alert
        } catch {
            // Show error
        }
    }
}
```

---

### 6. Intel Vault Pre-Loading
**Problem:** Intel Vault not automatically created

**Solution Needed:**
```swift
// File: Services/VaultService.swift

func ensureIntelVaultExists(for user: User) async throws {
    guard let modelContext = modelContext else { return }
    
    // Check if Intel Vault exists
    let descriptor = FetchDescriptor<Vault>(
        predicate: #Predicate { 
            $0.name == "Intel Vault" && 
            $0.owner?.id == user.id 
        }
    )
    
    let existing = try modelContext.fetch(descriptor)
    
    if existing.isEmpty {
        // Create Intel Vault
        let intelVault = Vault(
            name: "Intel Vault",
            vaultDescription: "AI-generated intelligence reports from cross-document analysis",
            keyType: "dual", // Always dual-key for security
            vaultType: "both"
        )
        intelVault.owner = user
        
        modelContext.insert(intelVault)
        try modelContext.save()
        
        try await loadVaults()
    }
}
```

**Integration:**
```swift
// File: Services/AuthenticationService.swift

// After successful sign-in (in signIn method):
if isAuthenticated {
    // Create Intel Vault if it doesn't exist
    Task {
        try? await vaultService.ensureIntelVaultExists(for: currentUser!)
    }
}
```

---

### 7. Intel Report Compilation Method
**Problem:** Method not implemented in IntelReportService

**Solution Needed:**
```swift
// File: Services/IntelReportService.swift

func compileReportFromDocuments(_ documents: [Document]) async throws -> String {
    var report = "# Intel Report\n"
    report += "Generated: \(Date().formatted())\n"
    report += "Documents Analyzed: \(documents.count)\n\n"
    
    // 1. Common Keywords Analysis
    let allTags = documents.flatMap { $0.aiTags }
    let tagFrequency = Dictionary(grouping: allTags, by: { $0 })
        .mapValues { $0.count }
        .sorted { $0.value > $1.value }
    
    report += "## Key Topics\n"
    for (tag, count) in tagFrequency.prefix(10) {
        report += "- **\(tag)**: \(count) occurrences\n"
    }
    report += "\n"
    
    // 2. Source vs Sink Analysis
    let sourceCount = documents.filter { $0.sourceSinkType == "source" }.count
    let sinkCount = documents.filter { $0.sourceSinkType == "sink" }.count
    
    report += "## Data Origin\n"
    report += "- Created by you (Source): \(sourceCount) documents\n"
    report += "- Received externally (Sink): \(sinkCount) documents\n\n"
    
    // 3. Temporal Patterns
    let dates = documents.map { $0.uploadDate }.sorted()
    if let earliest = dates.first, let latest = dates.last {
        let daysDiff = Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 0
        report += "## Timeline\n"
        report += "- Date Range: \(earliest.formatted(date: .abbreviated, time: .omitted)) - \(latest.formatted(date: .abbreviated, time: .omitted))\n"
        report += "- Span: \(daysDiff) days\n\n"
    }
    
    // 4. Document Types
    let typeDistribution = Dictionary(grouping: documents, by: { $0.documentType })
        .mapValues { $0.count }
        .sorted { $0.value > $1.value }
    
    report += "## Content Types\n"
    for (type, count) in typeDistribution {
        report += "- \(type.capitalized): \(count)\n"
    }
    report += "\n"
    
    // 5. Insights
    report += "## Key Insights\n"
    
    if sourceCount > sinkCount * 2 {
        report += "- You create significantly more content than you receive, suggesting an active content creation workflow.\n"
    } else if sinkCount > sourceCount * 2 {
        report += "- You receive significantly more content than you create, suggesting a content aggregation pattern.\n"
    } else {
        report += "- You maintain a balanced mix of created and received content.\n"
    }
    
    if tagFrequency.count > 0 {
        let topTag = tagFrequency.first!
        report += "- Most common topic: **\(topTag.key)** appears in \(topTag.value) documents.\n"
    }
    
    return report
}

func saveToIntelVault(_ report: String, for user: User?) async throws {
    guard let user = user,
          let modelContext = modelContext else { return }
    
    // Find Intel Vault
    let descriptor = FetchDescriptor<Vault>(
        predicate: #Predicate { 
            $0.name == "Intel Vault" && 
            $0.owner?.id == user.id 
        }
    )
    
    let vaults = try modelContext.fetch(descriptor)
    guard let intelVault = vaults.first else {
        throw IntelReportError.intelVaultNotFound
    }
    
    // Create document for report
    let reportData = report.data(using: .utf8) ?? Data()
    let fileName = "Intel_Report_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")).md"
    
    let document = Document(
        name: fileName,
        mimeType: "text/markdown",
        fileSize: Int64(reportData.count),
        documentType: "text",
        isEncrypted: true,
        isArchived: false,
        isRedacted: false,
        status: "active",
        aiTags: ["Intel Report", "AI Analysis", "Cross-Document"]
    )
    document.encryptedFileData = reportData
    document.vault = intelVault
    document.sourceSinkType = "source" // Generated by system
    
    intelVault.documents?.append(document)
    modelContext.insert(document)
    try modelContext.save()
}

enum IntelReportError: Error {
    case intelVaultNotFound
    case insufficientDocuments
}
```

---

## 📋 IMPLEMENTATION ORDER:

1. ✅ Access Map fix - DONE
2. ⏳ Complete iMessage sheets - 5 min
3. ⏳ Add dual-key pending indicator - 10 min
4. ⏳ Create Intel Vault pre-loading - 10 min
5. ⏳ Implement Intel report compilation - 20 min
6. ⏳ Add selection mode to Documents tab - 15 min
7. ⏳ Implement transfer ownership - 20 min

**Total Time:** ~80 minutes remaining

---

## 🚀 NEXT ACTIONS:

Run these implementations in order for clean integration!

