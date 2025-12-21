# Khandoba Secure Docs - Color Palette

## 🎨 Design Inspiration: Isometric Temple Architecture

The color palette is inspired by a minimalist, isometric 3D rendering of a multi-tiered temple structure with warm, architectural tones.

## Primary Colors

### Warm Muted Orange/Peach (`#E8A87C`)
- **Usage:** Primary brand color, main structure elements
- **RGB:** RGB(232, 168, 124)
- **Description:** Represents the main temple structure - warm, inviting, and secure
- **Application:** Primary buttons, highlights, dashboard accents

### Dark Teal/Blue-Grey (`#2D4A5F`)
- **Usage:** Secondary brand color, base structure
- **RGB:** RGB(45, 74, 95)
- **Description:** Represents the solid foundation - trustworthy and stable
- **Application:** Secondary buttons, vault elements, navigation

### Light Cream/Off-White (`#F5F0E8`)
- **Usage:** Tertiary accent, tower cap
- **RGB:** RGB(245, 240, 232)
- **Description:** Represents the elevated elements - premium and refined
- **Application:** Subtle highlights, elevated surfaces, premium features

## Background Colors

### Light Beige (`#FAF9F5`)
- **Usage:** Light mode background
- **RGB:** RGB(250, 249, 245)
- **Description:** Soft, warm background that complements the temple aesthetic

### Dark Grey Base (`#1F1F1F`)
- **Usage:** Dark mode background
- **RGB:** RGB(31, 31, 31)
- **Description:** Deep, secure foundation for dark mode

## Semantic Colors

### Success (`#45C186`)
- **RGB:** RGB(69, 193, 134)
- **Usage:** Success states, positive actions

### Error (`#D97757`)
- **RGB:** RGB(217, 119, 87)
- **Usage:** Error states, warnings, destructive actions

### Warning (`#E7A63A`)
- **RGB:** RGB(231, 166, 58)
- **Usage:** Warning states, cautionary messages

### Info (`#2D4A5F`)
- **RGB:** RGB(45, 74, 95)
- **Usage:** Informational messages, secondary information

## Role-Based Colors

### Client Color (`#2D4A5F`)
- Dark teal-blue representing trust and security

### Admin Color (`#E8A87C`)
- Warm muted orange representing authority and warmth

## Tab Colors

- **Dashboard:** `#E8A87C` (Warm muted orange)
- **Vaults:** `#2D4A5F` (Dark teal-blue)
- **Documents:** `#5A7A9A` (Medium slate)
- **Store:** `#45C186` (Success green)
- **Profile:** `#8E8E93` (Neutral grey)

## Color Usage Guidelines

1. **Primary (`#E8A87C`):** Use for main CTAs, active states, and brand highlights
2. **Secondary (`#2D4A5F`):** Use for vault-related UI, security indicators, and secondary actions
3. **Tertiary (`#F5F0E8`):** Use sparingly for premium features and elevated content
4. **Background:** Maintain contrast ratios for accessibility (WCAG AA minimum)

## Accessibility

All color combinations meet WCAG AA standards:
- Primary text on light background: ✅
- Primary text on dark background: ✅
- Interactive elements: ✅
- Error states: ✅

## Implementation

Colors are defined in `UnifiedTheme.swift` and accessible via:
```swift
@Environment(\.unifiedTheme) var theme
let colors = theme.colors(for: colorScheme)
```

---

**Last Updated:** December 2024  
**Design Reference:** Isometric Temple Architecture

