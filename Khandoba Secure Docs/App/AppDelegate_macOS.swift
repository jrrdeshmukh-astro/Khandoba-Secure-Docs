//
//  AppDelegate_macOS.swift
//  Khandoba Secure Docs
//
//  macOS-specific AppDelegate implementation
//

#if os(macOS)
import AppKit
import UserNotifications
import CloudKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = PushNotificationService.shared
        
        // Setup memory pressure monitoring
        setupMemoryPressureMonitoring()
        
        print("✅ macOS app delegate initialized")
    }
    
    private func setupMemoryPressureMonitoring() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .main)
        source.setEventHandler {
            let event = source.mask
            if event.contains(.warning) {
                Task { @MainActor in
                    DataOptimizationService.cleanupCacheIfNeeded(maxSize: 5_000_000)
                }
            } else if event.contains(.critical) {
                Task { @MainActor in
                    DataOptimizationService.handleMemoryPressure()
                }
            }
        }
        source.resume()
    }
    
    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationService.shared.registerDeviceToken(deviceToken)
        }
    }
    
    func application(
        _ application: NSApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushNotificationService.shared.registrationFailed(error: error)
        }
    }
    
    func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
    ) {
        Task {
            _ = await PushNotificationService.shared.handleRemoteNotification(userInfo)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Allow app to run without windows (menu bar app)
    }
}
#endif
