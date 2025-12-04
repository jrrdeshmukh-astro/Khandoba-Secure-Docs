# 🔧 Create Subscription in App Store Connect

**Why "Unable to load subscription" appears:**
- The subscription product doesn't exist yet in App Store Connect
- StoreKit is looking for product ID: `com.khandoba.premium.monthly`
- You need to create it manually first

---

## 📝 Create Subscription Now:

### Step 1: Go to App Store Connect

```
https://appstoreconnect.apple.com/apps/6753986878/distribution/ios/version/inflight
```

### Step 2: Navigate to Subscriptions

1. Click **"Features"** tab
2. Click **"Subscriptions"** (or "In-App Purchases")
3. Click **(+)** button

### Step 3: Create Subscription Group

**If no subscription group exists:**
- Click **"Create Subscription Group"**
- Reference Name: `Premium Subscription`
- Display Name (Localized): `Khandoba Premium`
- Click **"Create"**

### Step 4: Add Subscription

**Click "+ Create Subscription"**

**Fill in:**
```
Reference Name: Premium Monthly Subscription
Product ID: com.khandoba.premium.monthly
```

### Step 5: Set Duration & Price

**Subscription Duration:**
- Select: **1 Month**

**Subscription Prices:**
- Click **"Add Pricing"**
- Select all countries
- Price: **$5.99 USD (Tier 6)**
- Click **"Next"** → **"Save"**

### Step 6: Add Localization

**Localization (English US):**
```
Display Name: Premium Monthly
Description: Unlimited vaults, unlimited storage, and all premium features including AI intelligence, threat monitoring, and secure sharing.
```

### Step 7: Configure Settings

**Family Sharing:**
- Toggle: **ON** ✅

**Introductory Offer:**
- Leave empty (no free trial)

**Subscription Offers:**
- Skip for now

### Step 8: Add Review Information

**Promotional Image (Optional):**
- **IMPORTANT:** This is OPTIONAL and often causes upload issues
- **If upload fails:** Skip this step entirely - it's not required for approval
- **If you want to add it:**
  - Size: 640x920 pixels (exact)
  - Format: PNG or JPEG
  - No alpha channel
  - RGB color space
  - 72 DPI minimum
- **Recommendation:** Skip for now, add later after app is live

**Review Notes:**
```
Premium subscription provides:
- Unlimited vaults
- Unlimited document storage
- AI-powered document intelligence
- Threat monitoring and security features
- HIPAA-compliant tools
- Family Sharing for up to 6 people
```

### Step 9: Save & Submit

1. Click **"Save"**
2. Subscription status: **"Ready to Submit"**
3. Your subscription is now created!

---

## ✅ After Creating Subscription:

**The subscription will work in:**
1. **Sandbox Testing** - Immediately (use sandbox test account)
2. **TestFlight** - After app build is approved
3. **Production** - After App Store approval

---

## 🧪 Test in Sandbox:

**Create sandbox test account:**
1. App Store Connect → Users and Access → Sandbox Testers
2. Create a test account
3. Sign out of App Store on device
4. Run app, tap Subscribe
5. Sign in with sandbox account
6. Test subscription (free in sandbox)

---

## 🎯 Timeline:

**Now:** Create subscription (10 minutes)  
**TestFlight:** Available immediately in sandbox  
**Production:** After App Store approval (~1 week)

---

## 🚀 Quick Command:

**After creating subscription, test it:**

```bash
# Run app in simulator
open "/Users/jaideshmukh/Desktop/Khandoba Secure Docs/Khandoba Secure Docs.xcodeproj"
# Press ⌘+R
# Go to Store tab → Should show "$5.99/month"
```

---

**Create the subscription in App Store Connect now!** 📝✨

