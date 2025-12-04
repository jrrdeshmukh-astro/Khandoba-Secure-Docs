# Implementation Guide: Voice Intelligence Features

## ✅ **What's Been Implemented**

### 1️⃣ **Selfie Capture on Signup**

**File:** `AccountSetupView.swift`  
**New Component:** `CameraView.swift`

**What it does:**
- Users can take a selfie with front camera during signup
- Alternative: Choose photo from library
- Biometric photo stored in `User.profilePictureData`
- Links face to all future vault access logs

**To use:**
```swift
// Already integrated in AccountSetupView
// Shows two buttons:
// - "Take Selfie" → Opens front camera
// - "Choose Photo" → Opens photo library
```

**Permissions:** Already configured in `Info.plist`

---

### 2️⃣ **Smart Vault Session Extension**

**File:** `VaultService.swift`

**What it does:**
- Base timeout: 30 minutes
- Auto-extends +15 minutes on activity
- Tracks: recording, previewing, editing, uploading
- Never locks you out mid-work

**To use in your views:**
```swift
// When user starts recording/previewing
await vaultService.trackVaultActivity(
    for: vault, 
    activityType: "recording"  // or "previewing", "editing"
)

// Session automatically extends for 15 more minutes
// Timeout timer restarts
```

**Activities that extend session:**
- `"recording"` - Video/audio recording
- `"previewing"` - Document preview
- `"editing"` - Document editing
- `"uploading"` - File upload

---

### 3️⃣ **Voice Memo Service**

**File:** `VoiceMemoService.swift`

**What it does:**
- Converts text to speech using AVFoundation
- Generates AI-narrated threat reports
- Saves voice memos to vault as documents
- Creates comprehensive security narratives

**To generate a voice report:**
```swift
@StateObject var voiceMemoService = VoiceMemoService()

// In your view
Task {
    // Generate intel report
    let report = await intelReportService.generateIntelReport(for: [vault])
    
    // Analyze threats
    let threatLevel = await threatService.analyzeThreatLevel(for: vault)
    let anomalyScore = threatService.anomalyScore
    
    // Generate voice memo
    let document = try await voiceMemoService.generateThreatReportVoiceMemo(
        for: vault,
        report: report,
        threatLevel: threatLevel,
        anomalyScore: anomalyScore
    )
    
    print("Voice report saved: \(document.title)")
}
```

---

### 4️⃣ **Voice Report Generator View**

**File:** `VoiceReportGeneratorView.swift`

**What it does:**
- Beautiful UI for generating voice reports
- Shows progress during generation
- Displays success state with document info
- Saves automatically to Intel Vault

**To use:**
```swift
// Present as a sheet
.sheet(isPresented: $showVoiceReportGenerator) {
    VoiceReportGeneratorView(vault: selectedVault)
}

// Or push in NavigationStack
NavigationLink {
    VoiceReportGeneratorView(vault: vault)
} label: {
    Text("Generate AI Voice Report")
}
```

---

## 🔌 **How to Integrate**

### **Add Voice Report Button to Vault Detail**

```swift
// In VaultDetailView.swift or similar

Button {
    showVoiceReportGenerator = true
} label: {
    HStack {
        Image(systemName: "waveform.circle.fill")
        Text("Generate AI Voice Report")
    }
}
.sheet(isPresented: $showVoiceReportGenerator) {
    VoiceReportGeneratorView(vault: vault)
}
```

### **Track Vault Activity**

```swift
// When user starts recording
@EnvironmentObject var vaultService: VaultService

// In your recording view
Button("Start Recording") {
    // Track activity to extend session
    Task {
        await vaultService.trackVaultActivity(
            for: currentVault,
            activityType: "recording"
        )
    }
    
    // Start recording logic...
}

// When user previews document
Button("Preview Document") {
    Task {
        await vaultService.trackVaultActivity(
            for: currentVault,
            activityType: "previewing"
        )
    }
    
    // Show preview...
}
```

---

## 🎯 **Usage Examples**

### **Example 1: Generate Voice Report**

```swift
import SwiftUI

struct IntelVaultView: View {
    let vault: Vault
    @State private var showVoiceGenerator = false
    
    var body: some View {
        VStack {
            Text("Intel Vault")
            
            Button("🎙️ Generate AI Voice Report") {
                showVoiceGenerator = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .sheet(isPresented: $showVoiceGenerator) {
            VoiceReportGeneratorView(vault: vault)
        }
    }
}
```

### **Example 2: Extend Session During Video Recording**

```swift
import SwiftUI

struct DocumentRecordingView: View {
    let vault: Vault
    let document: Document
    @EnvironmentObject var vaultService: VaultService
    @State private var isRecording = false
    
    var body: some View {
        VStack {
            Button(isRecording ? "Stop Recording" : "Start Recording") {
                if !isRecording {
                    startRecording()
                } else {
                    stopRecording()
                }
            }
        }
    }
    
    private func startRecording() {
        isRecording = true
        
        // Extend vault session
        Task {
            await vaultService.trackVaultActivity(
                for: vault,
                activityType: "recording"
            )
        }
        
        // Your recording logic...
    }
    
    private func stopRecording() {
        isRecording = false
        // Stop recording logic...
    }
}
```

### **Example 3: Listen to Generated Voice Report**

```swift
import SwiftUI
import AVFoundation

struct VoiceReportPlayerView: View {
    let document: Document  // Voice memo document
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack {
            Text(document.title)
                .font(.headline)
            
            Button(isPlaying ? "Pause" : "Play Report") {
                if isPlaying {
                    audioPlayer?.pause()
                } else {
                    playVoiceMemo()
                }
                isPlaying.toggle()
            }
        }
    }
    
    private func playVoiceMemo() {
        guard let audioData = document.encryptedData else { return }
        
        do {
            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(document.id.uuidString + ".m4a")
            try audioData.write(to: tempURL)
            
            // Play audio
            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error)")
        }
    }
}
```

---

## 🔊 **Voice Memo Features**

### **What the AI Narrates:**

1. **Opening:**
   - Vault name
   - Current date/time
   - Report type

2. **Threat Assessment:**
   - Threat level (Low/Medium/High/Critical)
   - Anomaly score (0-100)
   - Severity explanation

3. **Document Analysis:**
   - Source vs Sink breakdown
   - File type distribution
   - Tag analysis
   - Entity extraction

4. **Access Patterns:**
   - Total access count
   - Recent access timeline
   - Night access percentage
   - Unusual patterns

5. **Geographic Intelligence:**
   - Location tracking summary
   - Geographic anomaly detection
   - Impossible travel warnings

6. **Security Recommendations:**
   - Specific actionable steps
   - Risk mitigation strategies
   - Compliance notes

### **Voice Sample:**

```
"Khandoba Security Intelligence Report. 

This is an AI-generated threat analysis for vault: Client Contracts. 
Report generated on December 4th, 2025 at 3:45 PM.

Current Threat Level: High. Anomaly Score: 67 out of 100. 
Multiple security red flags detected. Immediate review of 
access logs is advised.

Your vault contains 45 sink documents received from external 
sources, and 10 source documents created by you..."
```

---

## 📊 **Data Flow**

```
User Action:
  "Generate Voice Report"
         ↓
VoiceReportGeneratorView:
  1. Shows progress UI
  2. Calls IntelReportService
  3. Calls ThreatMonitoringService
  4. Calls VoiceMemoService
         ↓
VoiceMemoService:
  1. Creates narrative text
  2. Synthesizes to speech (AVFoundation)
  3. Saves as .m4a audio file
  4. Creates Document in vault
         ↓
Intel Vault:
  New voice memo appears
  Tags: ["intel-report", "voice-memo", "ai-generated"]
         ↓
User:
  Plays voice memo
  Reviews written report
  Takes security actions
```

---

## 🎨 **UI Components**

### **VoiceReportGeneratorView States:**

1. **Initial State:**
   - Explanation of what report contains
   - Feature checklist
   - "Generate AI Voice Report" button

2. **Generating State:**
   - Progress spinner
   - Status text: "Analyzing vault and generating report..."
   - Progress steps with checkmarks

3. **Success State:**
   - Green checkmark icon
   - "Voice Report Generated!" message
   - Document info card
   - "Done" button

4. **Error State:**
   - Error alert
   - Detailed error message
   - Retry option

---

## ⚙️ **Configuration**

### **Voice Settings (in VoiceMemoService):**

```swift
// Adjust these for different voice characteristics
utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
utterance.rate = 0.50          // Speed (0.0 - 1.0)
utterance.pitchMultiplier = 1.0 // Pitch (0.5 - 2.0)
utterance.volume = 1.0          // Volume (0.0 - 1.0)
```

### **Session Timeout Settings (in VaultService):**

```swift
private let sessionTimeout: TimeInterval = 30 * 60      // 30 minutes
private let activityExtension: TimeInterval = 15 * 60    // 15 minutes
```

---

## 🧪 **Testing**

### **Test Selfie Capture:**

1. Run app in simulator or device
2. Sign in (or sign up new user)
3. AccountSetupView should show
4. Tap "Take Selfie"
5. Camera interface opens (front camera)
6. Take photo → Preview → Confirm
7. Photo saved to User.profilePictureData

### **Test Session Extension:**

1. Open a vault
2. Session starts with 30-min timeout
3. Start "recording" activity
4. Call `trackVaultActivity()`
5. Check console: "🔄 Extending vault session..."
6. Session expiry updated to +15 minutes
7. Verify session doesn't timeout while active

### **Test Voice Report:**

1. Create a vault with some documents
2. Add access logs (by opening/closing vault)
3. Navigate to Intel Vault
4. Tap "Generate AI Voice Report"
5. Watch progress UI
6. Wait for generation (may take 30-60 seconds)
7. Success screen appears
8. Voice memo saved to vault
9. Play audio to hear AI narration

---

## 🐛 **Troubleshooting**

### **Issue: No audio output**

**Solution:**
```swift
// Check audio session configuration
let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playAndRecord, mode: .default)
try audioSession.setActive(true)
```

### **Issue: Session not extending**

**Solution:**
```swift
// Verify activity type is correct
let extendableActivities = ["recording", "previewing", "editing", "uploading"]

// Check logs
print("🔄 Extending vault session for: \(vault.name)")
```

### **Issue: Voice memo not saving**

**Solution:**
```swift
// Ensure modelContext is configured
voiceMemoService.configure(modelContext: modelContext)

// Check document was created
print("✅ Voice memo saved to vault: \(title)")
```

---

## 📱 **Production Checklist**

Before shipping to production:

- [ ] Test selfie capture on real device
- [ ] Test camera permissions flow
- [ ] Verify session extension works during real recording
- [ ] Generate voice report with real data
- [ ] Test voice memo playback
- [ ] Check audio quality and clarity
- [ ] Verify documents save to Intel Vault
- [ ] Test error handling (camera denied, audio fail, etc.)
- [ ] Review voice narration for clarity
- [ ] Optimize voice synthesis speed
- [ ] Add analytics tracking
- [ ] Test on iPhone and iPad
- [ ] Verify dark mode support

---

## 🚀 **Next Steps**

### **Immediate:**
1. Add voice report button to vault views
2. Integrate session tracking in recording views
3. Test end-to-end flow

### **Future Enhancements:**
1. Multiple voice options (male/female/accents)
2. Adjustable speech rate in settings
3. Voice report scheduling (daily/weekly)
4. Email voice reports as attachments
5. Share voice reports securely
6. Multi-language support
7. Custom voice training on user's voice

---

## 💡 **Tips for Best Results**

1. **Generate reports when vault has >10 documents** for meaningful analysis
2. **Allow 1-2 minutes for voice generation** (depending on report length)
3. **Use headphones** for better audio quality when reviewing
4. **Review reports weekly** to track security trends
5. **Enable location services** for geographic intelligence
6. **Keep vault sessions active** during important work

---

## 📚 **API Reference**

### **VaultService**

```swift
// Extend session manually
await vaultService.extendVaultSession(for: vault)

// Track activity (auto-extends if applicable)
await vaultService.trackVaultActivity(
    for: vault, 
    activityType: "recording"
)
```

### **VoiceMemoService**

```swift
// Generate voice memo from text
let url = try await voiceMemoService.generateVoiceMemo(
    from: "Your text here",
    title: "Memo Title"
)

// Generate threat report voice memo
let document = try await voiceMemoService.generateThreatReportVoiceMemo(
    for: vault,
    report: intelReport,
    threatLevel: .high,
    anomalyScore: 67.0
)

// Play voice memo
try await voiceMemoService.playVoiceMemo(url: audioURL)

// Stop playback
voiceMemoService.stopPlaying()
```

---

## ✅ **Summary**

You now have:

1. ✅ **Selfie capture** integrated into signup flow
2. ✅ **Smart session extension** that never interrupts work
3. ✅ **AI voice memo service** for threat narration
4. ✅ **Voice report generator UI** for easy access
5. ✅ **Comprehensive threat narratives** in plain English
6. ✅ **Intel Vault integration** with automatic saving

**Next:** Add the voice report button to your vault views and test the complete flow!

For the complete vision and narrative, see: `KHANDOBA_THREAT_INTELLIGENCE_NARRATIVE.md`

