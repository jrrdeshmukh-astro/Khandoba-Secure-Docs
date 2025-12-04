# Theme System Architecture

> **Last Updated:** December 2024
> 
> Documentation of the unified theme system with contrasting color palette.

## Overview

The Khandoba iOS app uses a unified theme system (`UnifiedTheme`) that provides a consistent, contrasting color palette across all tabs, roles, features, and views.

## Theme Structure

### UnifiedTheme

The main theme struct that provides:
- **Contrasting Color Palette**: Primary (coral red), Secondary (cyan), Tertiary (amber)
- **Role-Specific Colors**: Client (cyan), Admin (amber)
- **Tab-Specific Colors**: Dashboard, Vaults, Documents, Activity, Store, Profile
- **Typography**: Semantic text styles with Dynamic Type support
- **Metrics**: Spacing, corner radius, shadows, elevation

### Color Palette

#### Primary Colors
- **Primary**: `#E74A48` (Vibrant coral red) - Actions and highlights
- **Secondary**: `#11A7C7` (Cyan/teal) - Secondary actions
- **Tertiary**: `#E7A63A` (Amber/orange) - Warnings and special actions

#### Semantic Colors
- **Success**: `#45C186` (Green) - Positive states
- **Error**: `#E45858` (Red) - Errors and destructive actions
- **Info**: `#11A7C7` (Blue) - Informational states

#### Background Colors (Light Mode)
- **Background**: `#F5F2ED` (Paper/cream)
- **Surface**: `#FFFFFF` (White cards)
- **Surface Elevated**: `#FAF9F7` (Slightly darker for layered cards)

#### Background Colors (Dark Mode)
- **Background Dark**: `#1F2430` (Dark charcoal)
- **Surface Dark**: `#252C39` (Dark cards)
- **Surface Elevated Dark**: `#2A303D` (Slightly lighter for layered cards)

## Environment Integration

The theme is injected via SwiftUI's environment system:

```swift
@Environment(\.unifiedTheme) var theme
@Environment(\.colorScheme) var colorScheme

let colors = theme.colors(for: colorScheme)
```

## Design System

### UnifiedDesignSystem

Provides consistent spacing, corner radius, shadows, and elevation:

- **Spacing**: xxs (4), xs (8), sm (12), md (16), lg (24), xl (32), xxl (48)
- **Corner Radius**: sm (4), md (8), lg (12), xl (16), xxl (20)
- **Shadows**: sm, md, lg with consistent opacity and radius
- **Elevation**: none, flat, card, modal, floating

## Component Standards

### Standard Components

- **StandardButton**: Consistent button styling with haptic feedback
- **StandardCard**: Base card component
- **StandardStatCard**: Statistics display card
- **StandardInfoRow**: Information row component
- **StandardActivityRow**: Activity log row
- **StandardLoadingView**: Consistent loading indicators

## Migration from BrandTheme

**Status**: ✅ **COMPLETE** (December 2024)

All views have been successfully migrated from `BrandTheme` to `UnifiedTheme`. The migration included:

### Migration Statistics
- **103 BrandTheme references** migrated across **13 files**
- **BrandTheme.swift** removed from codebase
- **Zero compilation errors** after migration
- **All views** now use UnifiedTheme via environment

### Files Migrated
1. **Infrastructure** (5 files): KhandobaApp, DesignSystem, CharcoalColorScheme, Colors, ColorScheme
2. **Components** (2 files): FeltButton, CustomTextField
3. **Views** (3 files): ThreatMetricsView (55 refs), ClientMainView (9 refs), OnboardingCarouselView (7 refs)
4. **Bridge Layer** (2 files): AppTheme, IntegratedTheme
5. **Cleanup**: BrandTheme.swift deleted, comments updated

### Benefits Achieved
- ✅ Consistent theming across all views
- ✅ Proper light/dark mode support with adaptive colors
- ✅ Smooth color transitions and animations
- ✅ Better maintainability with single theme source
- ✅ Role-specific and tab-specific colors
- ✅ Enhanced accessibility with semantic colors

## Usage Examples

### In Views

```swift
struct MyView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack {
            Text("Title")
                .font(theme.typography.title)
                .foregroundStyle(colors.textPrimary)
        }
        .padding(UnifiedDesignSystem.Spacing.md)
        .background(colors.surface)
        .cornerRadius(UnifiedDesignSystem.CornerRadius.md)
    }
}
```

### Role Colors

```swift
let roleColor = theme.color(for: .admin) // Returns admin color (amber)
```

### Tab Colors

```swift
let tabColor = theme.color(for: .vaults) // Returns vaults tab color
```

