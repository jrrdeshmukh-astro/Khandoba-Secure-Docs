//
//  RemoteControlHandler.swift
//  Khandoba Secure Docs
//
//  Apple TV remote control gesture handling
//

import SwiftUI
import GameController

#if os(tvOS)
/// Handles Siri Remote gestures and button presses
@MainActor
class RemoteControlHandler: ObservableObject {
    @Published var lastGesture: RemoteGesture?
    
    enum RemoteGesture {
        case swipeUp
        case swipeDown
        case swipeLeft
        case swipeRight
        case tap
        case longPress
        case playPause
    }
    
    private var controller: GCController?
    
    init() {
        setupController()
    }
    
    private func setupController() {
        // Listen for controller connections
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleControllerConnect(notification)
        }
        
        // Check for already connected controllers
        if let controller = GCController.controllers().first {
            self.controller = controller
            setupControllerInputs(controller)
        }
    }
    
    private func handleControllerConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        self.controller = controller
        setupControllerInputs(controller)
    }
    
    private func setupControllerInputs(_ controller: GCController) {
        // Handle micro gamepad (Siri Remote)
        if let microGamepad = controller.microGamepad {
            microGamepad.buttonA.pressedChangedHandler = { [weak self] button, value, pressed in
                if pressed {
                    self?.lastGesture = .tap
                }
            }
            
            microGamepad.buttonX.pressedChangedHandler = { [weak self] button, value, pressed in
                if pressed {
                    self?.lastGesture = .playPause
                }
            }
            
            // Handle directional pad for swipes
            microGamepad.dpad.valueChangedHandler = { [weak self] dpad, xValue, yValue in
                if abs(xValue) > abs(yValue) {
                    self?.lastGesture = xValue > 0 ? .swipeRight : .swipeLeft
                } else {
                    self?.lastGesture = yValue > 0 ? .swipeUp : .swipeDown
                }
            }
        }
        
        // Handle extended gamepad (Apple TV Remote)
        if let extendedGamepad = controller.extendedGamepad {
            extendedGamepad.buttonA.pressedChangedHandler = { [weak self] button, value, pressed in
                if pressed {
                    self?.lastGesture = .tap
                }
            }
            
            extendedGamepad.buttonMenu.pressedChangedHandler = { [weak self] button, value, pressed in
                if pressed {
                    self?.lastGesture = .longPress
                }
            }
        }
    }
    
    /// Process a remote gesture and return action
    func processGesture(_ gesture: RemoteGesture) -> RemoteAction? {
        switch gesture {
        case .swipeUp:
            return .moveUp
        case .swipeDown:
            return .moveDown
        case .swipeLeft:
            return .moveLeft
        case .swipeRight:
            return .moveRight
        case .tap:
            return .select
        case .longPress:
            return .menu
        case .playPause:
            return .playPause
        }
    }
}

enum RemoteAction {
    case moveUp
    case moveDown
    case moveLeft
    case moveRight
    case select
    case menu
    case playPause
}

/// View modifier to handle remote control gestures
struct RemoteControlModifier: ViewModifier {
    @StateObject private var handler = RemoteControlHandler()
    let onGesture: (RemoteAction) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: handler.lastGesture) { gesture in
                if let gesture = gesture,
                   let action = handler.processGesture(gesture) {
                    onGesture(action)
                }
            }
    }
}

extension View {
    /// Add remote control gesture handling
    func onRemoteGesture(_ action: @escaping (RemoteAction) -> Void) -> some View {
        modifier(RemoteControlModifier(onGesture: action))
    }
}
#endif
