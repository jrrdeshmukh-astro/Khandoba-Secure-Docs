import UIKit
import CloudKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        // CloudKit sharing is handled by the main app
        // The extension receives share invitations but processing happens in main app
        Task {
            // Store share metadata for main app to process
            let appGroupIdentifier = MessageAppConfig.appGroupIdentifier
            if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
                // Store share metadata for main app to process on next launch
                if let shareMetadataData = try? NSKeyedArchiver.archivedData(withRootObject: cloudKitShareMetadata, requiringSecureCoding: true) {
                    sharedDefaults.set(shareMetadataData, forKey: "pending_cloudkit_share")
                }
            }
        }
    }
}
