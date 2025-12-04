//
//  UnifiedTheme.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

// MARK: - Unified Theme
struct UnifiedTheme {
    
    // MARK: - Color Palette
    struct Colors {
        // Primary Colors
        let primary: Color
        let secondary: Color
        let tertiary: Color
        
        // Backgrounds
        let background: Color
        let surface: Color
        let surfaceElevated: Color
        
        // Text Colors
        let textPrimary: Color
        let textSecondary: Color
        let textTertiary: Color
        
        // Semantic Colors
        let success: Color
        let error: Color
        let warning: Color
        let info: Color
        
        // Role Colors
        let clientColor: Color
        let adminColor: Color
        
        // Tab Colors
        let dashboardColor: Color
        let vaultsColor: Color
        let documentsColor: Color
        let storeColor: Color
        let profileColor: Color
        
        static let light = Colors(
            primary: Color(hex: "E74A48"), // Coral red
            secondary: Color(hex: "11A7C7"), // Cyan
            tertiary: Color(hex: "E7A63A"), // Amber
            background: Color(hex: "F5F2ED"), // Paper/cream
            surface: .white,
            surfaceElevated: Color(hex: "FAF9F7"),
            textPrimary: Color(hex: "141414"),
            textSecondary: Color(hex: "4B4B4F"),
            textTertiary: Color(hex: "8E8E93"),
            success: Color(hex: "45C186"),
            error: Color(hex: "E45858"),
            warning: Color(hex: "E7A63A"),
            info: Color(hex: "11A7C7"),
            clientColor: Color(hex: "11A7C7"),
            adminColor: Color(hex: "E7A63A"),
            dashboardColor: Color(hex: "E74A48"),
            vaultsColor: Color(hex: "11A7C7"),
            documentsColor: Color(hex: "6C63FF"),
            storeColor: Color(hex: "45C186"),
            profileColor: Color(hex: "8E8E93")
        )
        
        static let dark = Colors(
            primary: Color(hex: "E74A48"), // Coral red
            secondary: Color(hex: "11A7C7"), // Cyan
            tertiary: Color(hex: "E7A63A"), // Amber
            background: Color(hex: "1F2430"), // Dark charcoal
            surface: Color(hex: "252C39"), // Dark surface
            surfaceElevated: Color(hex: "2A303D"),
            textPrimary: .white,
            textSecondary: Color(hex: "B8B8BD"),
            textTertiary: Color(hex: "8E8E93"),
            success: Color(hex: "45C186"),
            error: Color(hex: "E45858"),
            warning: Color(hex: "E7A63A"),
            info: Color(hex: "11A7C7"),
            clientColor: Color(hex: "11A7C7"),
            adminColor: Color(hex: "E7A63A"),
            dashboardColor: Color(hex: "E74A48"),
            vaultsColor: Color(hex: "11A7C7"),
            documentsColor: Color(hex: "6C63FF"),
            storeColor: Color(hex: "45C186"),
            profileColor: Color(hex: "8E8E93")
        )
    }
    
    // MARK: - Typography
    struct Typography {
        let largeTitle: Font = .system(size: 34, weight: .bold, design: .rounded)
        let title: Font = .system(size: 28, weight: .bold, design: .rounded)
        let title2: Font = .system(size: 22, weight: .bold, design: .rounded)
        let headline: Font = .system(size: 17, weight: .semibold, design: .rounded)
        let body: Font = .system(size: 17, weight: .regular, design: .rounded)
        let callout: Font = .system(size: 16, weight: .regular, design: .rounded)
        let subheadline: Font = .system(size: 15, weight: .regular, design: .rounded)
        let footnote: Font = .system(size: 13, weight: .regular, design: .rounded)
        let caption: Font = .system(size: 12, weight: .regular, design: .rounded)
        let caption2: Font = .system(size: 11, weight: .regular, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let full: CGFloat = 9999
    }
    
    // MARK: - Shadows
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        static func sm(for colorScheme: ColorScheme) -> Shadow {
            Shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        
        static func md(for colorScheme: ColorScheme) -> Shadow {
            Shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        
        static func lg(for colorScheme: ColorScheme) -> Shadow {
            Shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.2),
                radius: 16,
                x: 0,
                y: 8
            )
        }
    }
    
    let typography = Typography()
    
    func colors(for colorScheme: ColorScheme) -> Colors {
        colorScheme == .dark ? .dark : .light
    }
    
    func color(for role: Role) -> Color {
        switch role {
        case .client: return Colors.dark.clientColor
        case .admin: return Colors.dark.adminColor
        }
    }
}

// MARK: - Environment Key
struct UnifiedThemeKey: EnvironmentKey {
    static let defaultValue = UnifiedTheme()
}

extension EnvironmentValues {
    var unifiedTheme: UnifiedTheme {
        get { self[UnifiedThemeKey.self] }
        set { self[UnifiedThemeKey.self] = newValue }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

