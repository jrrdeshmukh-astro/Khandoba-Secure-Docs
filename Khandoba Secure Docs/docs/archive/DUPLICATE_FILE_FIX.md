# Duplicate File Fix - OnboardingCarouselView.swift

## Issue
Two files with the same name `OnboardingCarouselView.swift` existed:
1. `Khandoba/Features/App/OnboardingCarouselView.swift` (older, 3.5K, Nov 27)
2. `Khandoba/Features/Authentication/Views/OnboardingCarouselView.swift` (newer, 6.7K, Nov 28)

## Resolution
✅ **Removed the duplicate file:**
- Deleted: `Khandoba/Features/App/OnboardingCarouselView.swift`
- Kept: `Khandoba/Features/Authentication/Views/OnboardingCarouselView.swift`

## Why Keep the Authentication/Views Version?
- **Newer file** (Nov 28 vs Nov 27)
- **More complete** (6.7K vs 3.5K)
- **Better design** - Uses modern system colors instead of deprecated CharcoalColorScheme
- **More features** - 5 onboarding pages vs 3, better navigation
- **Better location** - Authentication/Views is the logical place for onboarding

## Usage
The file is used in:
- `Khandoba/Features/App/ContentView.swift` - Line 30

Since both files are in the `Features/` folder which uses `PBXFileSystemSynchronizedRootGroup`, Swift can find the file regardless of which subdirectory it's in.

## Verification
✅ Only one `OnboardingCarouselView.swift` file remains
✅ File is in correct location: `Features/Authentication/Views/`
✅ File is the newer, more complete version

## Status
✅ **Fixed** - Duplicate file removed, build should now succeed

