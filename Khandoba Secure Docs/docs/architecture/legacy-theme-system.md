# Theme System Documentation

## Overview

A comprehensive theme system that extracts colors from images and applies them across the Khandoba iOS app. The system automatically processes images, extracts dominant colors, and creates a cohesive theme that adapts to both light and dark modes.

## Features

✅ **Image-Based Color Extraction** - Automatically extracts dominant colors from any image  
✅ **Intelligent Color Assignment** - Assigns colors based on brightness and saturation  
✅ **Light/Dark Mode Support** - Automatic theme variants for both modes  
✅ **Live Preview** - See theme changes in real-time  
✅ **Persistent Storage** - Theme preferences saved and restored on app launch  
✅ **Easy Integration** - Simple view modifiers to apply theme  

## Files Created

### Core Theme Files

1. **`ImageBasedTheme.swift`** - Base theme structure with color extraction utilities
2. **`ThemeConfigurator.swift`** - Color extraction engine and processing logic
3. **`ThemeProcessor.swift`** - Main processor that applies themes across the app
4. **`IntegratedTheme.swift`** - Integrated theme system with app-wide support
5. **`ThemeApplicationView.swift`** - UI for selecting images and applying themes
6. **`ThemePreviewView.swift`** - Preview interface to see theme changes
7. **`PresetThemes.swift`** - 10 beautiful preset theme definitions
8. **`PresetThemeView.swift`** - UI for selecting and applying preset themes

## How to Use

### For Users

1. **Access Theme Customization:**
   - Open the app
   - Go to **Profile** tab
   - Tap **Settings** section
   - Select **Theme Customization**

2. **Apply a Custom Theme from Image:**
   - Tap **Photo Library** or **Camera** to select an image
   - The system automatically extracts colors from the image
   - Review the extracted colors
   - Tap **Apply Theme** to apply across the app
   - Tap **Preview Theme** to see how it looks

3. **Apply a Preset Theme:**
   - In Theme Customization, scroll to **"Or Choose a Preset"**
   - Tap **Preset Themes**
   - Browse 10 beautiful pre-designed themes
   - Tap a theme to select it
   - Tap **Apply** to apply the theme
   - Themes include: Burgundy & Gold, Ocean Blue, Forest Green, Sunset Orange, Purple Dream, Charcoal Gray, Rose Pink, Emerald Teal, Midnight Blue, and Warm Amber

4. **Theme Persistence:**
   - Your theme is automatically saved
   - It will be restored when you restart the app

### For Developers

#### Applying Theme to Views

```swift
import SwiftUI

struct MyView: View {
    @Environment(\.integratedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Text("Hello")
                .foregroundColor(theme.textColor(for: colorScheme))
        }
        .background(theme.backgroundColor(for: colorScheme))
    }
}
```

#### Using Theme Colors

```swift
// Primary color
theme.primaryColor(for: colorScheme)

// Background color
theme.backgroundColor(for: colorScheme)

// Surface color
theme.surfaceColor(for: colorScheme)

// Text color
theme.textColor(for: colorScheme)

// Gradients
theme.primaryGradient(for: colorScheme)
theme.accentGradient(for: colorScheme)
```

#### Processing Images Programmatically

```swift
let themeProcessor = ThemeProcessor.shared

// Process an image and apply theme
if let image = UIImage(named: "myImage") {
    await themeProcessor.processImageAndApplyTheme(image)
}
```

## Color Extraction Algorithm

The system uses an intelligent color extraction algorithm:

1. **Image Resizing** - Resizes large images to 300px max dimension for performance
2. **Pixel Sampling** - Samples all pixels in the resized image
3. **Brightness Filtering** - Filters out very dark (<10%) and very light (>95%) colors
4. **Color Quantization** - Quantizes colors to reduce noise (12 levels per channel)
5. **Frequency Analysis** - Counts color frequency
6. **Top Colors** - Returns top 6 most frequent colors
7. **Smart Assignment** - Assigns colors based on:
   - **Primary**: Most saturated color
   - **Secondary**: Second most saturated color
   - **Accent**: Third most saturated color
   - **Background**: Lightest color
   - **Surface**: Slightly darker than background
   - **Text**: Darkest color

## Theme Structure

```swift
struct IntegratedTheme {
    var primary: Color          // Main brand color
    var secondary: Color         // Supporting color
    var accent: Color           // Highlight color
    var background: Color       // Base background
    var surface: Color          // Card/surface background
    var text: Color             // Primary text color
    
    // Dark mode variants
    var primaryDark: Color
    var backgroundDark: Color
    var surfaceDark: Color
    var textDark: Color
}
```

## Integration Points

### App Entry Point
- `KhandobaApp.swift` - Loads saved theme on app launch
- Provides theme environment to all views

### Profile View
- Added "Theme Customization" link in Settings section
- Accessible from Profile → Settings → Theme Customization

### Views Using Theme
- All views can access theme via `@Environment(\.integratedTheme)`
- Theme automatically adapts to light/dark mode

## Storage

Theme colors are stored in `UserDefaults` with keys:
- `theme.primary.red/green/blue`
- `theme.secondary.red/green/blue`
- `theme.accent.red/green/blue`
- `theme.background.red/green/blue`
- `theme.surface.red/green/blue`
- `theme.text.red/green/blue`
- `theme.customApplied` (boolean flag)

## Preset Themes

The system includes 10 professionally designed preset themes:

1. **Burgundy & Gold** - Classic warm burgundy with elegant gold accents
2. **Ocean Blue** - Calming ocean blues with crisp whites
3. **Forest Green** - Natural forest greens with earth tones
4. **Sunset Orange** - Vibrant sunset oranges and warm yellows
5. **Purple Dream** - Rich purples with soft lavender highlights
6. **Charcoal Gray** - Sophisticated grays with subtle accents
7. **Rose Pink** - Soft rose pinks with delicate pastels
8. **Emerald Teal** - Vibrant emerald with cool teal accents
9. **Midnight Blue** - Deep midnight blues with silver highlights
10. **Warm Amber** - Warm amber tones with golden highlights

Each preset includes:
- Primary, secondary, and accent colors
- Background and surface colors
- Text colors optimized for readability
- Light and dark mode variants

## Future Enhancements

- [x] Preset theme collections ✅
- [ ] Export/Import theme configurations
- [ ] Multiple saved themes with quick switching
- [ ] Manual color adjustment sliders
- [ ] Theme sharing between devices
- [ ] Animation when switching themes
- [ ] Custom preset creation from images

## Testing

To test the theme system:

1. Build and run the app
2. Navigate to Profile → Settings → Theme Customization
3. Select an image with distinct colors
4. Review extracted colors
5. Apply theme and verify it appears across the app
6. Restart app to verify persistence

## Notes

- Theme extraction works best with images that have clear, distinct colors
- Very dark or very light images may produce less optimal results
- The system filters out extreme colors to ensure readability
- Theme is applied globally but individual views can override if needed

