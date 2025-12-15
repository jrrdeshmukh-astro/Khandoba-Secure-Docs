import Foundation
import SwiftData

// Import debug logger for instrumentation

enum SharedModelContainer {
    private struct TimeoutError: Error {}
    static func ensureAppGroupSupportDir() {
        // #region agent log
        let appGroupID = MessageAppConfig.appGroupIdentifier
        DebugLogger.shared.log(
            location: "SharedModelContainer.swift:6",
            message: "Checking App Group directory access",
            data: [
                "appGroupIdentifier": appGroupID,
                "step": "app_group_check"
            ],
            hypothesisId: "B"
        )
        // #endregion
        
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MessageAppConfig.appGroupIdentifier) else {
            // #region agent log
            DebugLogger.shared.log(
                location: "SharedModelContainer.swift:8",
                message: "App Group URL not accessible - Missing entitlement or wrong identifier",
                data: [
                    "appGroupIdentifier": appGroupID,
                    "step": "app_group_failed"
                ],
                hypothesisId: "B"
            )
            // #endregion
            return
        }
        
        // #region agent log
        DebugLogger.shared.log(
            location: "SharedModelContainer.swift:10",
            message: "App Group URL accessible",
            data: [
                "appGroupIdentifier": appGroupID,
                "appGroupURL": appGroupURL.path,
                "step": "app_group_success"
            ],
            hypothesisId: "B"
        )
        // #endregion
        
        let appSupportURL = appGroupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
        
        // #region agent log
        let dirExists = FileManager.default.fileExists(atPath: appSupportURL.path)
        DebugLogger.shared.log(
            location: "SharedModelContainer.swift:12",
            message: "App Support directory check",
            data: [
                "appGroupIdentifier": appGroupID,
                "appSupportPath": appSupportURL.path,
                "directoryExists": dirExists,
                "step": "app_support_check"
            ],
            hypothesisId: "B"
        )
        // #endregion
    }
    
    static func schema() -> Schema {
        // Include all core models used by app and extension
        Schema([
            User.self,
            UserRole.self,
            Vault.self,
            VaultSession.self,
            VaultAccessLog.self,
            DualKeyRequest.self,
            Document.self,
            DocumentVersion.self,
            Nominee.self,
            VaultTransferRequest.self,
            VaultAccessRequest.self,
            EmergencyAccessRequest.self
            // If you have ChatMessage in your project, add it here as well.
        ])
    }
    
    static func configuration() -> ModelConfiguration {
        ModelConfiguration(
            schema: schema(),
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(MessageAppConfig.appGroupIdentifier),
            cloudKitDatabase: .automatic
        )
    }
    
    static func container() throws -> ModelContainer {
        // #region agent log
        let appGroupID = MessageAppConfig.appGroupIdentifier
        DebugLogger.shared.log(
            location: "SharedModelContainer.swift:42",
            message: "ModelContainer creation entry - App Group verification",
            data: [
                "appGroupIdentifier": appGroupID,
                "function": "container",
                "step": "entry"
            ],
            hypothesisId: "B"
        )
        // #endregion
        
        ensureAppGroupSupportDir()
        
        // #region agent log
        let config = configuration()
        DebugLogger.shared.log(
            location: "SharedModelContainer.swift:44",
            message: "ModelContainer configuration - Before creation",
            data: [
                "appGroupIdentifier": appGroupID,
                "cloudKitEnabled": true,
                "isStoredInMemoryOnly": false,
                "step": "before_container_creation"
            ],
            hypothesisId: "C"
        )
        // #endregion
        
        let container = try ModelContainer(for: schema(), configurations: [configuration()])
        
        // #region agent log
        DebugLogger.shared.log(
            location: "SharedModelContainer.swift:45",
            message: "ModelContainer created successfully",
            data: [
                "appGroupIdentifier": appGroupID,
                "containerCreated": true,
                "step": "container_created"
            ],
            hypothesisId: "C"
        )
        // #endregion
        
        return container
    }
    
    static func containerWithTimeout(seconds: TimeInterval = 8) async throws -> ModelContainer {
        // #region agent log
        let appGroupID = MessageAppConfig.appGroupIdentifier
        DebugLogger.shared.log(
            location: "SharedModelContainer.swift:47",
            message: "ModelContainer creation with timeout - Entry",
            data: [
                "appGroupIdentifier": appGroupID,
                "timeout": seconds,
                "function": "containerWithTimeout",
                "step": "entry"
            ],
            hypothesisId: "C"
        )
        // #endregion
        
        let result = try await withTimeout(seconds: seconds) {
            // #region agent log
            let createStartTime = Date().timeIntervalSince1970
            // #endregion
            
            let container = try ModelContainer(for: schema(), configurations: [configuration()])
            
            // #region agent log
            let createDuration = Date().timeIntervalSince1970 - createStartTime
            DebugLogger.shared.log(
                location: "SharedModelContainer.swift:49",
                message: "ModelContainer created in timeout block",
                data: [
                    "appGroupIdentifier": appGroupID,
                    "containerCreated": true,
                    "creationDuration": createDuration,
                    "step": "container_created"
                ],
                hypothesisId: "C"
            )
            // #endregion
            
            return container
        }
        
        // #region agent log
        DebugLogger.shared.log(
            location: "SharedModelContainer.swift:51",
            message: "ModelContainer timeout operation completed",
            data: [
                "appGroupIdentifier": appGroupID,
                "timeoutCompleted": true,
                "step": "timeout_completed"
            ],
            hypothesisId: "C"
        )
        // #endregion
        
        return result
    }
    
    @MainActor
    static func context() throws -> ModelContext {
        try container().mainContext
    }
    
    // Generic timeout helper
    private static func withTimeout<T>(seconds: TimeInterval, operation: @escaping () throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            group.cancelAll()
            return result
        }
    }
}
