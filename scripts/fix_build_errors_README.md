# Build Error Fixer Script

## Overview

Automatically fixes common build errors and warnings in Khandoba Secure Docs by applying patterns from `.cursorrules` and project documentation.

## Usage

```bash
./scripts/fix_build_errors.sh
```

## What It Fixes

### Automatic Fixes

1. **Missing Imports:**
   - `import Combine` (for services with `@Published`)
   - `import CloudKit` (for CloudKit operations)
   - `import SwiftData` (for SwiftData models)

2. **Property Name Errors:**
   - `document.title` → `document.name`
   - `document.encryptedData` → `document.encryptedFileData`
   - `document.tags` → `document.aiTags`

3. **Subscription Properties:**
   - `isSubscribed` → `subscriptionStatus == .active`
   - `availableSubscriptions` → `products`

4. **Naming Conflicts:**
   - `Observation` → `LogicalObservation` (SwiftData conflict)

5. **Entity Types:**
   - `.placeName` → `.location`

6. **CloudKit API Errors:**
   - `metadata.shareURL` → `metadata.share.recordID.recordName`
   - `records(for:)` tuple destructuring fixes
   - `participantType` removal (unavailable in iOS)

7. **Main Actor:**
   - Adds `@MainActor` to service classes missing it

8. **Unused Variables:**
   - Prefixes unused variables with `_`

## How It Works

1. **Builds the project** and captures errors/warnings
2. **Parses build output** to extract file paths and error types
3. **Applies fixes** based on error patterns
4. **Rebuilds** to verify fixes
5. **Repeats** up to 10 iterations or until no more fixes can be applied

## Safety Features

- **Backup:** Creates backup before making changes (via sed -i)
- **Iteration Limit:** Stops after 10 iterations to prevent infinite loops
- **File Validation:** Checks file exists before modifying
- **Pattern Matching:** Only fixes known safe patterns

## Limitations

Some errors require manual fixes:
- Complex type mismatches
- Architecture-level issues
- Context-dependent fixes
- Deprecated API migrations (non-critical)

## Output

The script provides:
- ✅ Real-time fix notifications
- 📊 Summary of fixes applied
- ⚠️ Remaining errors that need manual attention
- 📝 Full build log saved to `build/build_errors.log`

## Integration with Project Rules

The script follows patterns from:
- `.cursorrules` - Common issues and fixes
- `WARNINGS_SUMMARY.md` - Known warning patterns
- Project documentation - Architecture patterns

## Example Output

```
🔧 Khandoba Secure Docs - Build Error Fixer
==========================================

📦 Building project...
🔍 Analyzing errors...
  📝 Fixing: CloudKitSharingService.swift:240
  ✅ Added 'import CloudKit' to CloudKitSharingService.swift
  ✅ Fixed metadata.shareURL access

🔄 Rebuilding after fixes...

✅ Build succeeded!
   Errors fixed: 2
   Warnings fixed: 0
   Iterations: 1
```

## Notes

- Script uses `sed -i ''` for macOS compatibility
- Builds for iOS Simulator (iPhone 15) by default
- Non-destructive: Only fixes known safe patterns
- Can be run multiple times safely

