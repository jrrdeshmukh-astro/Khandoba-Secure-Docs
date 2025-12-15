import Foundation
import SwiftData

enum SharedModelContainer {
    private struct TimeoutError: Error {}
    static func ensureAppGroupSupportDir() {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MessageAppConfig.appGroupIdentifier) else {
            return
        }
        let appSupportURL = appGroupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
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
        ensureAppGroupSupportDir()
        return try ModelContainer(for: schema(), configurations: [configuration()])
    }
    
    static func containerWithTimeout(seconds: TimeInterval = 8) async throws -> ModelContainer {
        try await withTimeout(seconds: seconds) {
            try ModelContainer(for: schema(), configurations: [configuration()])
        }
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
