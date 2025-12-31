//
//  PlatformDetection.swift
//  Khandoba Secure Docs
//
//  Platform detection and capability checking utilities
//

import Foundation
import SwiftUI

/// Platform detection and capability checking
enum Platform {
    case iOS
    case macOS
    case tvOS
    
    static var current: Platform {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(tvOS)
        return .tvOS
        #else
        return .iOS // Default fallback
        #endif
    }
    
    var supportsCamera: Bool {
        #if os(iOS)
        return true
        #elseif os(macOS)
        return true // External camera support
        #elseif os(tvOS)
        return false
        #else
        return false
        #endif
    }
    
    var supportsMicrophone: Bool {
        #if os(iOS)
        return true
        #elseif os(macOS)
        return true
        #elseif os(tvOS)
        return false
        #else
        return false
        #endif
    }
    
    var supportsLocation: Bool {
        #if os(iOS)
        return true
        #elseif os(macOS)
        return true
        #elseif os(tvOS)
        return false
        #else
        return false
        #endif
    }
    
    var supportsPushNotifications: Bool {
        #if os(iOS)
        return true
        #elseif os(macOS)
        return true
        #elseif os(tvOS)
        return true
        #else
        return false
        #endif
    }
    
    var supportsPhotoLibrary: Bool {
        #if os(iOS)
        return true
        #elseif os(macOS)
        return false // Use file picker instead
        #elseif os(tvOS)
        return false
        #else
        return false
        #endif
    }
    
    var requiresFocusEngine: Bool {
        #if os(tvOS)
        return true
        #else
        return false
        #endif
    }
    
    var minimumTouchTarget: CGFloat {
        #if os(tvOS)
        return 44.0 // Apple TV minimum
        #elseif os(iOS)
        return 44.0 // iOS minimum
        #elseif os(macOS)
        return 32.0 // macOS can be smaller
        #else
        return 44.0
        #endif
    }
    
    var defaultSpacing: CGFloat {
        #if os(tvOS)
        return 32.0 // Larger spacing for TV
        #elseif os(macOS)
        return 16.0 // Standard macOS spacing
        #else
        return 16.0 // iOS standard
        #endif
    }
    
    var defaultFontSize: CGFloat {
        #if os(tvOS)
        return 28.0 // Larger fonts for TV viewing
        #elseif os(macOS)
        return 13.0 // Standard macOS font
        #else
        return 17.0 // iOS standard
        #endif
    }
}

/// Platform-specific view modifiers and utilities
struct PlatformViewModifiers {
    /// Apply platform-specific styling
    static func applyPlatformStyling<V: View>(_ view: V) -> some View {
        let platform = Platform.current
        
        return view
            .font(.system(size: platform.defaultFontSize))
            .padding(platform.defaultSpacing)
    }
    
    /// Make view focusable on Apple TV
    static func makeFocusable<V: View>(_ view: V) -> some View {
        #if os(tvOS)
        return view
            .focusable()
        #else
        return view
        #endif
    }
}

/// Platform-specific layout helpers
struct PlatformLayout {
    static var cardSpacing: CGFloat {
        Platform.current.defaultSpacing * 2
    }
    
    static var sectionSpacing: CGFloat {
        Platform.current.defaultSpacing * 3
    }
    
    static var gridColumns: [GridItem] {
        let platform = Platform.current
        switch platform {
        case .tvOS:
            // Fewer columns on TV for larger items
            return [
                GridItem(.adaptive(minimum: 400), spacing: cardSpacing)
            ]
        case .macOS:
            // More columns on macOS
            return [
                GridItem(.adaptive(minimum: 200), spacing: cardSpacing)
            ]
        case .iOS:
            // Standard iOS grid
            return [
                GridItem(.adaptive(minimum: 150), spacing: cardSpacing)
            ]
        }
    }
}
