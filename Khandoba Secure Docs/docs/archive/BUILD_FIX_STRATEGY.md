# Build Error Fix Strategy

## Problem Summary
All 129 files from the build error are actually located in `Features/` folder, but have explicit file references in the Xcode project that point to wrong paths (without `Features/` prefix).

## Root Cause
- `Features` folder uses `PBXFileSystemSynchronizedRootGroup` which auto-discovers files
- Explicit file references conflict with file system sync
- Files are referenced at paths like `Khandoba/Core/...` but actually exist at `Khandoba/Features/Core/...`

## Solution
Since `Features` uses file system synchronization, we should:
1. Remove explicit `PBXFileReference` entries for files in Features/
2. Remove explicit `PBXBuildFile` entries (from Sources section)
3. Remove group children references

## Files Already Fixed
✅ Removed explicit references for:
- AccessLogService.swift
- ActivityLogService.swift
- AccountSwitchService.swift
- OptimizedCoreDataHelpers.swift
- DataCacheService.swift
- PaymentUsageService.swift
- ApplePayService.swift
- OnboardingCarouselView.swift

## Remaining Files
~121 more files in Features/ that need explicit references removed.

## Recommended Approach
Since this is a large change affecting 129 files, the safest approach is:

1. **Option A (Recommended):** Remove all explicit references for files in Features/
   - Let PBXFileSystemSynchronizedRootGroup handle discovery
   - Clean and rebuild

2. **Option B:** Update all explicit reference paths to include `Features/` prefix
   - More work but preserves explicit structure
   - Still may conflict with file system sync

## Next Steps
1. Identify all file IDs for files in Features/
2. Remove PBXFileReference entries
3. Remove PBXBuildFile entries
4. Remove group children references
5. Clean build folder
6. Rebuild project

## Note
The project file structure is complex. Manual removal of 129 file references is error-prone. Consider using Xcode to:
1. Remove files from project (but keep on disk)
2. Let file system sync rediscover them automatically

