//
//  AppDelegate_iOS.swift
//  Khandoba Secure Docs
//
//  iOS-specific AppDelegate implementation
//

#if os(iOS)
import UIKit
import UserNotifications
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = PushNotificationService.shared
        
        // Force dark mode for system alerts and modals
        configureDarkModeAppearance()
        
        // Setup memory pressure monitoring
        setupMemoryPressureMonitoring()
        
        return true
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
    
    private func configureDarkModeAppearance() {
        if #available(iOS 13.0, *) {
            #if !APP_EXTENSION
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = .dark
                }
            }
            #endif
            
            let textFieldAppearance = UITextField.appearance(whenContainedInInstancesOf: [UIAlertController.self])
            textFieldAppearance.overrideUserInterfaceStyle = .dark
            
            let buttonAppearance = UIButton.appearance(whenContainedInInstancesOf: [UIAlertController.self])
            buttonAppearance.overrideUserInterfaceStyle = .dark
            
            NotificationCenter.default.addObserver(
                forName: UIWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let window = notification.object as? UIWindow {
                    window.overrideUserInterfaceStyle = .dark
                }
            }
            
            print("✅ Dark mode enforced for system alerts, modals, and all windows")
        }
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationService.shared.registerDeviceToken(deviceToken)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushNotificationService.shared.registrationFailed(error: error)
        }
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            let result = await PushNotificationService.shared.handleRemoteNotification(userInfo)
            completionHandler(result.uiBackgroundFetchResult)
        }
    }
    
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        print("📥 CloudKit share invitation received")
        print("   Share record: \(cloudKitShareMetadata.share.recordID.recordName)")
        
        let rootRecordName = getRootRecordName(from: cloudKitShareMetadata)
        print("   Root record: \(rootRecordName)")
        
        NotificationCenter.default.post(
            name: .cloudKitShareInvitationReceived,
            object: nil,
            userInfo: ["metadata": cloudKitShareMetadata]
        )
    }
    
    private func getRootRecordID(from metadata: CKShare.Metadata) -> CKRecord.ID {
        if #available(iOS 16.0, *) {
            // Prefer hierarchicalRootRecordID on iOS 16+
            if let hierarchicalID = metadata.hierarchicalRootRecordID {
                return hierarchicalID
            }
        }
        // Fallback to rootRecordID when hierarchicalRootRecordID is unavailable
        // Note: rootRecordID is deprecated in iOS 16+ but still functional and needed as fallback
        // This is intentional fallback behavior per Apple's migration guidance
        // swiftlint:disable:next deprecated_member_use
        return metadata.rootRecordID
    }
    
    private func getRootRecordName(from metadata: CKShare.Metadata) -> String {
        return getRootRecordID(from: metadata).recordName
    }
}
#endif
