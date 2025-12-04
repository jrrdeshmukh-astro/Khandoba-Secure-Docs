# Bitrise Build Cache Setup & Verification Guide

This guide explains how to run your Bitrise workflows and verify that the Xcode Build Cache is working correctly.

## Prerequisites

✅ **Completed:**
- `bitrise.yml` configuration file created
- Xcode 26 stack configured (`osx-xcode-26.0.x-edge`)
- Build Cache step added to all workflows

## Method 1: Trigger Builds via Bitrise Dashboard (Recommended)

### Step 1: Access Your Bitrise Project

1. Go to [Bitrise Dashboard](https://app.bitrise.io)
2. Navigate to your project: **khandoba-ios**
3. You should see your configured workflows: `primary`, `test`, and `deploy`

### Step 2: Trigger a Build

1. Click on **"Start/Schedule a Build"** button (or use the "+" button)
2. Select the workflow you want to run:
   - **`test`** workflow (fastest, recommended for cache verification)
   - **`primary`** workflow (full archive build)
   - **`deploy`** workflow (full deployment)
3. Select the branch: **`main`** (or the branch where `bitrise.yml` is located)
4. Click **"Start Build"**

### Step 3: Run Multiple Builds

**Important:** To verify the cache is working, you need to run **at least 2-3 builds**:

1. **First Build:** Will populate the cache (slower)
2. **Second Build:** Should read from cache (faster)
3. **Third Build:** Should confirm cache is being reused

**Timing:**
- Wait for the first build to complete
- Trigger the second build immediately after
- Trigger the third build to confirm consistency

### Step 4: Verify Cache is Working

#### Check Build Logs

In each build log, look for:
```
[Build Cache] Restoring cache...
[Build Cache] Cache hit!
[Build Cache] Saving cache...
```

#### Check Cache History

1. Go to the **Build Cache Overview** page:
   - Direct link: https://app.bitrise.io/build-cache/82489c8ef68b7dab/invocations?tool=xcode&project_slug=664f1e4e-89c8-4ad3-98de-b39ecdc36dae
   - Or navigate: Project → **Build Cache** → **Invocations** → Filter by **Xcode**

2. You should see invocations appearing with:
   - **Status:** Success
   - **Cache Hit Rate:** Should improve on subsequent builds
   - **Duration:** Should decrease on cached builds

#### Expected Results

- ✅ **First Build:** Cache miss (no previous cache), saves cache
- ✅ **Second Build:** Cache hit (reads from cache), faster build time
- ✅ **Third Build:** Cache hit confirmed, consistent performance

## Method 2: Trigger Builds via Bitrise CLI

### Install Bitrise CLI

```bash
# Install via Homebrew (recommended)
brew install bitrise

# Or via installer script
curl -fL https://github.com/bitrise-io/bitrise/releases/download/2.2.0/bitrise-$(uname -s)-$(uname -m) > /usr/local/bin/bitrise
chmod +x /usr/local/bin/bitrise
```

### Authenticate

```bash
# Login to Bitrise
bitrise login

# You'll need your Bitrise API token
# Get it from: https://app.bitrise.io/me/profile/account_settings#/security
```

### Trigger Builds

```bash
# Navigate to project directory
cd /Users/jaideshmukh/Documents/khandoba-ios

# Trigger test workflow
bitrise trigger --workflow test --branch main

# Wait for build to complete, then trigger again
bitrise trigger --workflow test --branch main

# Trigger third build
bitrise trigger --workflow test --branch main
```

## Method 3: Trigger via Git Push

If you have automatic triggers configured:

```bash
# Make a small change and push
echo "# Cache test" >> README.md
git add README.md
git commit -m "Test build cache"
git push origin main
```

## Verification Checklist

After running 2-3 builds, verify:

- [ ] **Cache Invocations Appear:** Check https://app.bitrise.io/build-cache/82489c8ef68b7dab/invocations?tool=xcode&project_slug=664f1e4e-89c8-4ad3-98de-b39ecdc36dae
- [ ] **Build Time Decreases:** Second and third builds should be faster
- [ ] **Cache Hit Rate Increases:** Subsequent builds show cache hits
- [ ] **No Errors in Logs:** Build cache step executes successfully
- [ ] **Xcode Build Succeeds:** Actual compilation uses cached artifacts

## Troubleshooting

### Cache Not Appearing

1. **Check Stack:** Ensure you're using `osx-xcode-26.0.x-edge` stack
2. **Check Step Order:** `activate-build-cache-for-xcode` must be before Xcode steps
3. **Check Workflow:** Verify workflow is using the correct `bitrise.yml` file

### Build Fails

1. **Check Logs:** Look for error messages in build logs
2. **Check Secrets:** Ensure all required secrets are configured
3. **Check Xcode Version:** Verify Xcode 26 is available on the stack

### Cache Not Improving Build Time

1. **First Build:** Will always be slower (populating cache)
2. **Second Build:** Should show improvement
3. **Check Cache Size:** Large projects may need multiple builds to populate cache

## Expected Performance Improvement

- **First Build (Cache Miss):** Baseline time
- **Second Build (Cache Hit):** 30-50% faster
- **Subsequent Builds:** 40-60% faster (depending on code changes)

## Additional Resources

- [Bitrise Build Cache Documentation](https://docs.bitrise.io/en/bitrise-build-cache/build-cache-for-xcode/configuring-the-build-cache-for-xcode-in-the-bitrise-ci-environment.html)
- [Bitrise Dashboard](https://app.bitrise.io)
- [Cache History Page](https://app.bitrise.io/build-cache/82489c8ef68b7dab/invocations?tool=xcode&project_slug=664f1e4e-89c8-4ad3-98de-b39ecdc36dae)

## Current Configuration

✅ **Stack:** `osx-xcode-26.0.x-edge`
✅ **Workflows Configured:** `primary`, `test`, `deploy`
✅ **Build Cache Step:** `activate-build-cache-for-xcode@1`
✅ **Cache Push Enabled:** `true` (default)

Your `bitrise.yml` file is committed and ready to use!

