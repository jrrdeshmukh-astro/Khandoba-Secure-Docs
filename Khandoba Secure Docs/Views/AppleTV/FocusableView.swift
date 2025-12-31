//
//  FocusableView.swift
//  Khandoba Secure Docs
//
//  Apple TV focus engine integration
//

import SwiftUI

#if os(tvOS)
/// View modifier to make views focusable on Apple TV
struct FocusableModifier: ViewModifier {
    @FocusState.Binding var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focusable()
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

extension View {
    /// Make a view focusable on Apple TV
    func focusable(_ binding: FocusState<Bool>.Binding) -> some View {
        modifier(FocusableModifier(isFocused: binding))
    }
}

/// Focus engine coordinator for Apple TV navigation
@MainActor
class FocusEngineCoordinator: ObservableObject {
    @Published var focusedItem: UUID?
    
    func setFocus(_ id: UUID) {
        focusedItem = id
    }
    
    func clearFocus() {
        focusedItem = nil
    }
}
#endif

/// Platform-agnostic focusable wrapper
struct PlatformFocusable<Content: View>: View {
    let content: Content
    let id: UUID
    
    #if os(tvOS)
    @FocusState private var isFocused: Bool
    @EnvironmentObject private var focusCoordinator: FocusEngineCoordinator
    #endif
    
    init(id: UUID = UUID(), @ViewBuilder content: () -> Content) {
        self.id = id
        self.content = content()
    }
    
    var body: some View {
        #if os(tvOS)
        content
            .focusable()
            .focused($isFocused)
            .onChange(of: isFocused) { newValue in
                if newValue {
                    focusCoordinator.setFocus(id)
                }
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        #else
        content
        #endif
    }
}
