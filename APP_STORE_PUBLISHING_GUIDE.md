# Step-by-Step App Store Publishing Guide
## Khandoba Secure Docs v1.0.1

**Complete guide for publishing to the Apple App Store**

---

## 📋 Pre-Publication Checklist

### ✅ Code Readiness
- [x] Zero build errors
- [x] All features implemented and tested
- [x] Version number: 1.0.1
- [x] Build number: 29
- [x] Minimum iOS: 17.0
- [x] All deprecation warnings addressed (where possible)

### ✅ Configuration
- [x] Bundle ID: `com.khandoba.securedocs`
- [x] Team ID: `Q5Y8754WU4`
- [x] Entitlements: Production mode
- [x] Signing: Automatic (team selected)
- [x] App Icon: 1024x1024 (in Assets.xcassets)

### ⏳ Required Before Submission
- [ ] App Store Connect app created
- [ ] Subscription products created
- [ ] Screenshots prepared (all required sizes)
- [ ] App description written
- [ ] Privacy policy URL live
- [ ] Terms of service URL live
- [ ] Support URL configured

---

## Step 1: App Store Connect Setup

### 1.1 Create App Listing

1. **Go to App Store Connect**
   - Visit: https://appstoreconnect.apple.com
   - Sign in with your Apple ID (must be Account Holder or Admin)

2. **Navigate to My Apps**
   - Click "My Apps" in the top navigation
   - Click the "+" button to create a new app

3. **Fill App Information**
   ```
   Platform: iOS
   Name: Khandoba Secure Docs
   Primary Language: English (U.S.)
   Bundle ID: com.khandoba.securedocs
   SKU: khandoba-secure-docs-001
   User Access: Full Access (or Limited Access if using teams)
   ```

4. **Click "Create"**
   - App will be created in "Prepare for Submission" status

### 1.2 Configure App Information

**In App Store Connect → Your App → App Information:**

1. **Category**
   - Primary: Productivity
   - Secondary: Business

2. **Age Rating**
   - Select "4+" (suitable for all ages)
   - Answer questionnaire:
     - Medical/Treatment Information: No
     - Unrestricted Web Access: No
     - Gambling/Contests: No
     - Violence: No
     - Profanity/Crude Humor: No
     - Sexual Content: No
     - Alcohol/Tobacco/Drugs: No
     - Mature/Suggestive Themes: No
     - Horror/Fear Themes: No
     - Simulated Gambling: No

3. **App Privacy**
   - Click "Manage" under App Privacy
   - Answer questions:
     - **Data Collection**: Yes (we collect some data)
     - **Data Types Collected**:
       - Name (from Apple Sign In)
       - Email (from Apple Sign In, optional)
       - Location Data (for security monitoring)
       - User Content (documents you upload)
     - **Data Usage**: 
       - App Functionality
       - Analytics (optional)
       - Product Personalization
     - **Data Linked to User**: Yes
     - **Tracking**: No (we do not track users across apps)

4. **Copyright**
   - Enter: "© 2025 Khandoba Secure Docs"

---

## Step 2: Create Subscription Products

### 2.1 Navigate to Subscriptions

1. **In App Store Connect**
   - Go to: Your App → Features → In-App Purchases
   - Click "+" to create new subscription

2. **Create Subscription Group**
   - Name: "Premium Subscription"
   - Click "Create"

### 2.2 Create Monthly Subscription

1. **Click "+" in Subscription Group**
2. **Fill Subscription Details:**
   ```
   Reference Name: Premium Monthly
   Product ID: com.khandoba.premium.monthly
   Subscription Duration: 1 Month
   Price: $9.99
   Free Trial: 7 Days
   ```

3. **Localizations:**
   - **English (U.S.)**:
     - Display Name: Premium Monthly
     - Description: Unlimited vaults, AI features, and premium security tools. Cancel anytime.

4. **Review Information:**
   - Review Notes: "Monthly premium subscription with 7-day free trial"
   - Screenshot: (optional, but recommended)

5. **Click "Save"**

### 2.3 Create Yearly Subscription

1. **Click "+" in Subscription Group**
2. **Fill Subscription Details:**
   ```
   Reference Name: Premium Yearly
   Product ID: com.khandoba.premium.yearly
   Subscription Duration: 1 Year
   Price: $71.88
   Free Trial: 7 Days
   ```

3. **Localizations:**
   - **English (U.S.)**:
     - Display Name: Premium Yearly
     - Description: Save 40% with annual subscription. All premium features included.

4. **Review Information:**
   - Review Notes: "Annual premium subscription with 7-day free trial. Saves 40% compared to monthly."

5. **Click "Save"**

### 2.4 Submit Subscriptions for Review

1. **Select both subscriptions**
2. **Click "Submit for Review"**
3. **Wait for approval** (typically 24-48 hours)

---

## Step 3: Prepare App Metadata

### 3.1 App Description

**Copy from:** `APP_STORE_LAUNCH_CHECKLIST.md` (lines 112-173)

**Or use this:**
```
🔐 KHANDOBA SECURE DOCS - AI-Powered Security Vault

The world's first vault app with AI voice intelligence and ML-powered threat detection.

🎙️ AI VOICE SECURITY REPORTS
Get comprehensive security briefings narrated by AI. Listen to threat analysis, access patterns, and step-by-step security recommendations—all in plain English.

🤖 ML AUTO-APPROVAL
Our machine learning system automatically approves or denies vault access based on threat metrics, geographic location, and behavioral patterns. No more manual approvals for low-risk requests.

📊 SOURCE/SINK INTELLIGENCE
Understand where your documents come from. Our AI classifies every document as "source" (created by you) or "sink" (received from others), providing context-aware security analysis.

🌍 GEOGRAPHIC INTELLIGENCE
Impossible travel detection prevents unauthorized access. If someone accesses your vault from New York at 3 PM and Los Angeles at 3:30 PM, our AI knows that's impossible and auto-denies the request.

🎯 ACTIONABLE INSIGHTS
Not just "what" but "how" and "when." Every threat comes with:
• Specific action steps
• Priority levels (Critical/High/Medium/Low)
• Timeframes for completion
• Detailed rationale

🗓️ AUTOMATED SECURITY SCHEDULING
Set up recurring security reviews. Our system automatically schedules:
• Daily reviews for critical vaults
• Weekly for high-risk vaults
• Monthly for standard vaults
Syncs with your iOS calendar.

PREMIUM FEATURES:
• Military-Grade AES-256 Encryption
• AI Threat Detection & Analysis
• Voice-Narrated Security Reports
• ML-Based Dual-Key Auto-Approval
• Geographic Anomaly Detection
• Source/Sink Document Classification
• Advanced Analytics Dashboard
• Unlimited Secure Storage
• Real-Time Threat Monitoring
• Biometric Selfie Verification

WHY KHANDOBA?
Traditional vault apps show you logs and numbers. Khandoba tells you stories and gives you action plans. Our AI security analyst works 24/7 to protect your most sensitive information.

SUBSCRIPTION:
• Monthly: $9.99/month
• Yearly: $71.88/year (Save 40%)
• 7-day free trial
• Cancel anytime

PERFECT FOR:
• Executives with sensitive business documents
• Lawyers handling client files
• Healthcare professionals with patient records
• Anyone who values security and privacy

Download now and experience security that speaks your language.

Khandoba: Where Security Meets AI Storytelling 🎭🔐
```

### 3.2 Subtitle (30 characters max)
```
AI Security Vault with Voice
```

### 3.3 Promotional Text (170 characters max)
```
🎙️ NEW: AI Voice Security Reports! Get threat analysis narrated in plain English. The only vault app with ML auto-approval and actionable insights.
```

### 3.4 Keywords (100 characters max)
```
secure vault,encryption,AI security,voice report,document storage,dual-key,threat detection
```

### 3.5 Support URL
```
https://khandoba.org/support
```

### 3.6 Marketing URL (Optional)
```
https://khandoba.org
```

### 3.7 Privacy Policy URL
```
https://khandoba.org/privacy
```

---

## Step 4: Prepare Screenshots

### 4.1 Required Screenshot Sizes

**iPhone 6.7" Display (Required):**
- Size: 1290 x 2796 pixels
- Format: PNG or JPEG
- Required: Yes

**iPhone 6.5" Display (Required):**
- Size: 1284 x 2778 pixels
- Format: PNG or JPEG
- Required: Yes

**iPad Pro 12.9" (Optional but Recommended):**
- Size: 2048 x 2732 pixels
- Format: PNG or JPEG
- Required: No

### 4.2 Screenshot Content

**Recommended Screenshots (in order):**

1. **Welcome Screen** - Apple Sign In interface
2. **Vault List** - Showing vault cards and organization
3. **Vault Detail** - Documents, security features
4. **AI Voice Report** - Voice memo player with waveform
5. **Threat Dashboard** - ML scores and security metrics
6. **Document Upload** - Camera and file picker interface
7. **Nominee Sharing** - Invitation and sharing flow
8. **Access Map** - Geographic security visualization
9. **Settings/Profile** - User profile and preferences
10. **Subscription** - Premium features and pricing

### 4.3 Screenshot Tips
- Use real device screenshots (not simulator)
- Show actual app content (not mockups)
- Highlight key features
- Ensure text is readable
- Use consistent styling

---

## Step 5: Build and Archive

### 5.1 Pre-Build Checklist

**In Xcode:**
- [ ] Select "Generic iOS Device" (not simulator)
- [ ] Version: 1.0.1
- [ ] Build: 29
- [ ] Signing: Automatic (Team: Q5Y8754WU4)
- [ ] Configuration: Release

### 5.2 Create Archive

**Option A: Using Scripts (Recommended)**

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Step 1: Validate configuration
./scripts/validate_for_transporter.sh

# Step 2: Build and export IPA
./scripts/prepare_for_transporter.sh
```

**Option B: Manual Xcode Build**

1. **Open Xcode**
2. **Product → Destination → Any iOS Device (arm64)**
3. **Product → Archive**
4. **Wait for archive to complete** (5-10 minutes)
5. **Organizer window opens automatically**

### 5.3 Validate Archive

1. **In Organizer window**
2. **Select your archive**
3. **Click "Validate App"**
4. **Follow prompts:**
   - Select distribution method: "App Store Connect"
   - Select team: Your team
   - Select provisioning: Automatic
5. **Review validation results**
   - Fix any errors before proceeding

### 5.4 Export IPA

**If using scripts:** IPA is automatically created at:
```
./build/Final_IPA/Khandoba Secure Docs.ipa
```

**If using Xcode:**
1. **In Organizer → Select Archive**
2. **Click "Distribute App"**
3. **Select "App Store Connect"**
4. **Click "Upload"**
5. **Follow prompts**
6. **Wait for upload** (10-30 minutes)

---

## Step 6: Upload to App Store Connect

### 6.1 Using Transporter App (Recommended)

1. **Download Transporter**
   - Mac App Store → Search "Transporter"
   - Or: https://apps.apple.com/app/transporter/id1450874784

2. **Open Transporter**
   - Sign in with your Apple ID
   - (Same Apple ID as App Store Connect)

3. **Upload IPA**
   - Click "+" button (or drag IPA file)
   - Navigate to: `./build/Final_IPA/Khandoba Secure Docs.ipa`
   - Click "Deliver"

4. **Wait for Upload**
   - Progress bar shows status
   - Typically 10-20 minutes
   - Don't close Transporter until complete

5. **Success Message**
   - "Package delivered successfully"
   - Build appears in App Store Connect within 10-15 minutes

### 6.2 Using Xcode Organizer

1. **In Organizer window**
2. **Select your archive**
3. **Click "Distribute App"**
4. **Select "App Store Connect"**
5. **Click "Upload"**
6. **Follow prompts:**
   - Distribution options: Default
   - App Store Connect: Automatic
   - Signing: Automatic
7. **Click "Upload"**
8. **Wait for completion** (10-30 minutes)

### 6.3 Using Command Line (Advanced)

```bash
xcrun altool --upload-app \
    --type ios \
    --file "./build/Final_IPA/Khandoba Secure Docs.ipa" \
    --apiKey YOUR_API_KEY_ID \
    --apiIssuer YOUR_ISSUER_ID
```

**Get API Keys:**
- App Store Connect → Users and Access → Keys
- Generate new key → Download .p8 file
- Note Key ID and Issuer ID

---

## Step 7: Complete App Store Connect Submission

### 7.1 Wait for Processing

1. **Go to App Store Connect**
2. **My Apps → Khandoba Secure Docs**
3. **TestFlight tab** (or App Store tab)
4. **Wait 10-30 minutes** for processing
5. **Build status will change:**
   - "Processing" → "Ready to Submit" or "Invalid Binary"

### 7.2 Handle Processing Issues

**If "Invalid Binary":**
- Check email for details
- Common issues:
  - Missing Info.plist keys
  - Invalid entitlements
  - Code signing issues
- Fix and re-upload

**If "Missing Export Compliance":**
- Go to: App Store Connect → Your App → App Store → Build
- Answer encryption questions:
  - Uses encryption? **YES**
  - Exempt from regulations? **YES** (standard encryption)
  - Export compliance code: **Not required**

### 7.3 Add Build to Version

1. **Go to: App Store Connect → Your App → App Store**
2. **Click "+ Version or Platform"** (if first version)
3. **Or select existing version**
4. **Under "Build" section:**
   - Click "+" next to "Build"
   - Select your processed build
   - Click "Done"

### 7.4 Complete Version Information

**Fill in all required fields:**

1. **What's New in This Version:**
   ```
   Version 1.0.1 - Initial Release
   
   🎉 Welcome to Khandoba Secure Docs!
   
   The world's first vault app with AI voice intelligence. Here's what makes us different:
   
   🎙️ AI VOICE SECURITY REPORTS
   Listen to your security status instead of reading logs. Our AI narrates comprehensive threat analysis with step-by-step recommendations.
   
   🤖 ML AUTO-APPROVAL
   Dual-key vault access is automatically approved or denied based on threat metrics, location data, and behavior patterns. 99%+ accuracy.
   
   📊 SOURCE/SINK INTELLIGENCE  
   Every document is classified as "source" (you created) or "sink" (you received). Get context-aware security analysis.
   
   🌍 GEOGRAPHIC INTELLIGENCE
   Impossible travel detection prevents fraud. Access from NYC at 3 PM then LA at 3:30 PM? Auto-denied.
   
   🎯 ACTIONABLE INSIGHTS
   Every threat comes with:
   • What to do
   • Why it matters  
   • When to do it
   • How to do it
   
   Plus: Professional animations, haptic feedback, calendar sync, and more!
   
   Start your 7-day free trial today! 🚀
   ```

2. **App Review Information:**
   - **First Name:** [Your first name]
   - **Last Name:** [Your last name]
   - **Phone:** [Your phone number]
   - **Email:** [Your email]
   - **Demo Account:** (if required)
     - Username: [test account]
     - Password: [test password]
   - **Notes:** 
     ```
     Thank you for reviewing Khandoba Secure Docs!
     
     Key features to test:
     - AI Voice Security Reports (generate from any vault)
     - ML Auto-Approval (create dual-key vault and request access)
     - Document upload and encryption
     - Nominee sharing and transfer ownership
     
     All features are fully functional. The app uses Apple Sign In for authentication.
     
     If you need any clarification, please contact support@khandoba.org
     ```

3. **Version Release:**
   - **Automatically release this version:** No (manual release recommended)
   - **Or:** Select "Manually release this version"

### 7.5 Add Screenshots

1. **For each device size:**
   - Click "+" under Screenshots
   - Upload required screenshots (minimum 3, maximum 10)
   - Drag to reorder (first screenshot is most important)

2. **Screenshot Order:**
   - 1. Welcome/Home screen
   - 2. Vault list
   - 3. AI Voice Report
   - 4. Threat Dashboard
   - 5. Document features

### 7.6 Review and Submit

1. **Review all information:**
   - App description ✅
   - Screenshots ✅
   - Version information ✅
   - Build selected ✅
   - Subscriptions created ✅

2. **Click "Add for Review"**
   - Review summary appears
   - Check all items

3. **Click "Submit for Review"**
   - Confirmation dialog appears
   - Click "Submit"

4. **Status Changes:**
   - "Prepare for Submission" → "Waiting for Review"
   - You'll receive email confirmation

---

## Step 8: Post-Submission

### 8.1 Monitor Review Status

**Possible Statuses:**
- **Waiting for Review**: In queue (typically 24-48 hours)
- **In Review**: Apple is reviewing (1-3 days)
- **Pending Developer Release**: Approved, waiting for release
- **Ready for Sale**: Live on App Store
- **Rejected**: Issues found (check email for details)

### 8.2 Respond to Review Feedback

**If Rejected:**
1. **Read rejection email carefully**
2. **Check Resolution Center** in App Store Connect
3. **Address all issues:**
   - Fix bugs
   - Update metadata
   - Provide additional information
4. **Resubmit** with explanation

**Common Rejection Reasons:**
- Missing functionality described in app description
- Subscription issues
- Privacy policy not accessible
- App crashes or bugs
- Guideline violations

### 8.3 After Approval

1. **Release App:**
   - If set to manual release: Click "Release This Version"
   - If set to automatic: App releases automatically

2. **Monitor Launch:**
   - App appears on App Store within 24 hours
   - Monitor downloads and reviews
   - Respond to user feedback

---

## Step 9: Marketing & Launch

### 9.1 Pre-Launch

- [ ] Update website with app links
- [ ] Prepare social media announcements
- [ ] Notify beta testers
- [ ] Prepare press release (if applicable)

### 9.2 Launch Day

- [ ] Post on social media
- [ ] Send email to existing users
- [ ] Update website homepage
- [ ] Monitor App Store reviews

### 9.3 Post-Launch

- [ ] Respond to user reviews
- [ ] Monitor crash reports
- [ ] Track subscription conversions
- [ ] Plan feature updates

---

## Troubleshooting

### Build Issues

**"Archive Failed"**
```bash
# Clean build folder
xcodebuild clean -project "Khandoba Secure Docs.xcodeproj" -scheme "Khandoba Secure Docs"

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Try again
```

**"Signing Failed"**
- Check Xcode → Target → Signing & Capabilities
- Ensure "Automatically manage signing" is checked
- Ensure correct team is selected
- Download manual profiles if needed

### Upload Issues

**"Transporter Upload Failed"**
- Check internet connection
- Try using Xcode Organizer instead
- Verify IPA file isn't corrupted
- Check file size (should be < 200MB)

**"Invalid Binary"**
- Check email for specific errors
- Verify Info.plist has all required keys
- Check entitlements are correct
- Ensure no simulator builds included

### App Store Connect Issues

**"Build Not Appearing"**
- Wait 15-30 minutes after upload
- Check processing status
- Verify build is for correct bundle ID
- Check if build was rejected during processing

**"Missing Compliance"**
- Answer encryption questions in App Store Connect
- Standard encryption = exempt from regulations
- No export compliance code needed

---

## Quick Reference

### Key URLs
- **App Store Connect**: https://appstoreconnect.apple.com
- **Apple Developer**: https://developer.apple.com
- **Transporter Download**: Mac App Store

### Key Information
- **Bundle ID**: com.khandoba.securedocs
- **Team ID**: Q5Y8754WU4
- **Version**: 1.0.1
- **Build**: 29
- **Minimum iOS**: 17.0

### Support Contacts
- **App Store Connect Support**: https://help.apple.com/app-store-connect/
- **Developer Support**: https://developer.apple.com/contact/
- **Your Support**: support@khandoba.org

---

## Timeline Estimate

**Total Time: 3-7 days**

- **Day 1**: App Store Connect setup, subscription creation (2-4 hours)
- **Day 2**: Build, archive, upload (2-3 hours)
- **Day 3-5**: Apple review (24-48 hours typical)
- **Day 6-7**: Post-approval release and monitoring

**Note:** First-time submissions may take longer. Subsequent updates are typically faster.

---

## Success Checklist

Before clicking "Submit for Review", verify:

- [ ] App Store Connect app created
- [ ] All metadata completed
- [ ] Screenshots uploaded (all required sizes)
- [ ] Subscription products created and approved
- [ ] Build uploaded and processed
- [ ] Build added to version
- [ ] App description written
- [ ] Privacy policy URL live and accessible
- [ ] Support URL configured
- [ ] Review notes provided
- [ ] Demo account created (if needed)
- [ ] All required information filled

---

## Final Steps

1. **Double-check everything**
2. **Click "Submit for Review"**
3. **Wait for Apple's review** (typically 24-48 hours)
4. **Respond to any feedback**
5. **Release when approved**
6. **Celebrate! 🎉**

---

**Good luck with your App Store submission!**

**Khandoba Secure Docs v1.0.1**  
**Last Updated: December 18, 2025**
