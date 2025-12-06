//
//  SupportChatService.swift
//  Khandoba Secure Docs
//
//  LLM-powered support chat - Replaces admin role
//  Provides app navigation help and feature explanations
//

import Foundation
import Combine

@MainActor
final class SupportChatService: ObservableObject {
    @Published var messages: [SupportMessage] = []
    @Published var isProcessing = false
    
    struct SupportMessage: Identifiable {
        let id = UUID()
        let role: MessageRole
        let content: String
        let timestamp: Date
        
        enum MessageRole {
            case user
            case assistant
        }
    }
    
    init() {
        // Welcome message
        messages.append(SupportMessage(
            role: .assistant,
            content: "Hi! I'm your AI assistant. I can help you navigate the app, explain features, and answer questions about vault security. What would you like to know?",
            timestamp: Date()
        ))
    }
    
    /// Send user message and get AI response
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        messages.append(SupportMessage(
            role: .user,
            content: text,
            timestamp: Date()
        ))
        
        isProcessing = true
        
        // Generate response
        let response = await generateResponse(to: text)
        
        // Add assistant response
        messages.append(SupportMessage(
            role: .assistant,
            content: response,
            timestamp: Date()
        ))
        
        isProcessing = false
    }
    
    /// Generate contextual AI response
    private func generateResponse(to query: String) async -> String {
        let lowercased = query.lowercased()
        
        // VAULT CREATION
        if lowercased.contains("create") && lowercased.contains("vault") {
            return """
            To create a vault:
            
            1. Tap the **Vaults** tab at the bottom
            2. Tap the **+** button (top right)
            3. Choose **Single-Key** (password) or **Dual-Key** (requires approval)
            4. Enter vault name and description
            5. Tap **Create Vault**
            
            Tip: Use dual-key for sensitive documents - it adds ML-powered security with auto-approval!
            """
        }
        
        // UPLOADING DOCUMENTS
        if lowercased.contains("upload") || (lowercased.contains("add") && lowercased.contains("document")) {
            return """
            To upload documents:
            
            1. Open a vault (tap **Unlock Vault**)
            2. Tap the **+** button
            3. Choose source:
               • **Camera** - Take photo
               • **Photo Library** - Select images
               • **Files** - Browse documents
               • **Video** - Record video
               • **Voice Memo** - Record audio
            
            Files are automatically encrypted and tagged with AI!
            """
        }
        
        // DUAL-KEY VAULTS
        if lowercased.contains("dual") || lowercased.contains("approval") {
            return """
            Dual-key vaults provide enhanced security:
            
            **How it works:**
            • Like a bank safety deposit box
            • Requires approval to open
            • ML automatically analyzes your request
            • Checks threat level, location, behavior
            • Auto-approves or denies within seconds
            
            **No manual approval needed!** Everything runs on ML autopilot.
            
            Use dual-key for: Medical records, legal documents, financial files
            """
        }
        
        // AUDIO INTEL
        if lowercased.contains("intel") || lowercased.contains("audio intel") {
            return """
            Audio Intel generates intelligence debriefs from your documents:
            
            1. Go to **Documents** tab
            2. Tap menu (⋯) → **Select for Intel Report**
            3. Select 2 or more documents (any type: photos, videos, audio, PDFs)
            4. Tap **Audio Intel** in toolbar
            5. Wait for processing (converts all media to audio → analyzes → generates debrief)
            6. Choose which vault to save to
            7. Listen to your intelligence summary!
            
            Works with images, videos, audio, and PDFs!
            """
        }
        
        // VAULT SESSIONS
        if lowercased.contains("session") || lowercased.contains("timeout") || lowercased.contains("lock") {
            return """
            Vault sessions work like a physical bank vault:
            
            **Shared Sessions:**
            • If one person opens a vault, it's open for everyone
            • If someone locks it, it's locked for all
            • Real-time notifications keep everyone informed
            
            **Auto-Lock:**
            • Vaults auto-lock after 30 minutes of inactivity
            • Any activity extends the session by 15 minutes
            • Keeps your data secure automatically
            
            **Locking:**
            • Vault owner can manually lock
            • All members get notified
            """
        }
        
        // SECURITY & THREAT MONITORING
        if lowercased.contains("security") || lowercased.contains("threat") || lowercased.contains("safe") {
            return """
            Your vaults are protected by multiple security layers:
            
            **Encryption:**
            • AES-256 encryption for all files
            • End-to-end encrypted
            • Zero-knowledge architecture
            
            **ML Threat Monitoring:**
            • Continuous analysis of access patterns
            • Geographic anomaly detection
            • Unusual behavior alerts
            • Automatic risk scoring
            
            **Access Control:**
            • Face ID / Touch ID
            • Dual-key for sensitive vaults
            • Complete audit trail
            • Auto-lock mechanisms
            
            Everything is automated - no manual security reviews needed!
            """
        }
        
        // SHARING & NOMINEES
        if lowercased.contains("share") || lowercased.contains("nominee") {
            return """
            To share a vault or add emergency access:
            
            **Nominees:**
            1. Open vault details
            2. Tap **Sharing & Collaboration**
            3. Tap **Add Nominee**
            4. Enter their details
            5. Choose access level
            
            **Emergency Access:**
            • Nominees can request emergency access
            • You control who has backup access
            • Perfect for family vaults or critical documents
            """
        }
        
        // SUBSCRIPTION
        if lowercased.contains("subscription") || lowercased.contains("premium") || lowercased.contains("pay") {
            return """
            Khandoba Secure Docs requires a premium subscription:
            
            **Why Premium?**
            • Unlimited vaults
            • Unlimited storage
            • ML threat analysis
            • Audio Intel reports
            • Priority support
            
            **Plans:**
            • Monthly: $9.99/month
            • Yearly: $99.99/year (save 17%!)
            
            Tap **Premium** tab to manage your subscription.
            """
        }
        
        // NAVIGATION
        if lowercased.contains("where") || lowercased.contains("find") || lowercased.contains("navigate") {
            return """
            App navigation:
            
            **Bottom Tabs:**
            • **Home** - Dashboard, quick actions
            • **Vaults** - All your secure vaults
            • **Documents** - Search all documents
            • **Premium** - Subscription management
            • **Profile** - Settings, help & support
            
            **Quick Actions:**
            • Create vault: Vaults → +
            • Upload file: Open vault → +
            • Audio Intel: Documents → Select → Audio Intel
            • Support chat: Profile → Help & Support (you're here!)
            """
        }
        
        // FEATURES OVERVIEW
        if lowercased.contains("what can") || lowercased.contains("features") || lowercased.contains("do") {
            return """
            Khandoba Secure Docs features:
            
            **Storage:**
            • Secure vaults with encryption
            • Documents, photos, videos, audio
            • AI-powered organization
            
            **Intelligence:**
            • Audio Intel Reports
            • Multi-media analysis
            • ML threat monitoring
            
            **Security:**
            • Dual-key protection
            • Face ID / Touch ID
            • Auto-lock mechanisms
            • Access logs
            
            **Collaboration:**
            • Shared vault sessions
            • Nominee system
            • Emergency access
            
            Everything runs on ML autopilot - no manual administration!
            """
        }
        
        // TROUBLESHOOTING
        if lowercased.contains("can't") || lowercased.contains("not working") || lowercased.contains("problem") || lowercased.contains("issue") {
            return """
            Common issues and solutions:
            
            **Can't unlock vault:**
            • Check if vault requires dual-key approval
            • ML processes approval automatically
            • Wait a few seconds for auto-approval
            • Check your internet connection
            
            **Upload failed:**
            • Ensure vault is unlocked
            • Check file size (max 100MB per file)
            • Verify sufficient storage
            
            **Session timeout:**
            • Vaults auto-lock after 30 min inactivity
            • Just unlock again
            • Activity extends session automatically
            
            **Subscription issues:**
            • Go to Premium tab
            • Tap Restore Purchases
            • Check subscription status
            
            Need more help? Describe your specific issue!
            """
        }
        
        // DEFAULT RESPONSE
        return """
        I can help you with:
        
        • Creating and managing vaults
        • Uploading documents
        • Using Audio Intel
        • Understanding security features
        • Dual-key protection
        • Vault sessions
        • Sharing and nominees
        • Troubleshooting issues
        • App navigation
        
        What would you like to know? Try asking:
        • "How do I create a vault?"
        • "What is Audio Intel?"
        • "How does security work?"
        • "How do I share a vault?"
        """
    }
    
    /// Clear chat history
    func clearChat() {
        messages.removeAll()
        // Add welcome message
        messages.append(SupportMessage(
            role: .assistant,
            content: "Hi! I'm your AI assistant. What can I help you with?",
            timestamp: Date()
        ))
    }
}

