# Build Error Fix - Missing File References

## Problem
Build errors indicate files cannot be found because:
1. Files are located in `Khandoba/Features/Core/...` and `Khandoba/Features/App/...`
2. Project has explicit file references pointing to `Khandoba/Core/...` and `Khandoba/App/...`
3. The `Features` folder uses `PBXFileSystemSynchronizedRootGroup` which auto-discovers files
4. Explicit references conflict with file system sync

## Root Cause
The project has both:
- File system sync group: `24F44ADB2EDC2F5B00A10317 /* Features */` (auto-discovers files)
- Explicit file references for files inside Features (conflicts with sync)

## Solution
Since `Features` uses file system synchronization, explicit file references for files inside Features should be removed. The file system sync will automatically discover them.

## Files Affected
All files in:
- `Khandoba/Features/Core/...`
- `Khandoba/Features/App/...`
- `Khandoba/Features/UI/...` (if any)

## Recommended Fix
1. Remove explicit file references for files inside Features folder
2. Let PBXFileSystemSynchronizedRootGroup handle file discovery
3. Clean and rebuild project

## Alternative Fix (if needed)
If removing references causes issues, update explicit file reference paths to include `Features/` prefix.

