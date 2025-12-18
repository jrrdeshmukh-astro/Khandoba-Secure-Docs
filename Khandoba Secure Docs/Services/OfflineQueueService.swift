//
//  OfflineQueueService.swift
//  Khandoba Secure Docs
//
//  Created for production 1.0.1 launch
//

import Foundation
import Combine
import Network

/// Service for queuing operations when offline and retrying when connection is restored
@MainActor
final class OfflineQueueService: ObservableObject {
    @Published var queuedOperations: [QueuedOperation] = []
    @Published var isProcessing = false
    @Published var isOnline = true
    
    private let queue = DispatchQueue(label: "com.khandoba.offlinequeue")
    private var networkMonitor: NWPathMonitor?
    private var monitorQueue: DispatchQueue?
    private var cancellables = Set<AnyCancellable>()
    
    nonisolated init() {
        setupNetworkMonitoring()
    }
    
    /// Setup network monitoring to detect online/offline status
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        monitorQueue = DispatchQueue(label: "com.khandoba.networkmonitor")
        
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOnline = self?.isOnline ?? true
                self?.isOnline = path.status == .satisfied
                
                // If we just came online, process queued operations
                if !wasOnline && self?.isOnline == true {
                    print("🌐 Network connection restored - processing queued operations")
                    self?.processQueue()
                } else if wasOnline && self?.isOnline == false {
                    print("📴 Network connection lost - operations will be queued")
                }
            }
        }
        
        networkMonitor?.start(queue: monitorQueue!)
    }
    
    /// Queue an operation for later execution
    /// - Parameters:
    ///   - operation: The operation to queue
    ///   - priority: Operation priority (higher = executed first)
    func queueOperation(_ operation: QueuedOperation) {
        queuedOperations.append(operation)
        queuedOperations.sort { $0.priority > $1.priority }
        
        print("📦 Queued operation: \(operation.name) (Priority: \(operation.priority))")
        
        // If online, try to process immediately
        if isOnline {
            processQueue()
        }
    }
    
    /// Process queued operations
    func processQueue() {
        guard isOnline && !isProcessing && !queuedOperations.isEmpty else {
            return
        }
        
        isProcessing = true
        
        Task {
            var processedIndices: [Int] = []
            
            for (index, operation) in queuedOperations.enumerated() {
                do {
                    print("🔄 Processing queued operation: \(operation.name)")
                    try await operation.operation()
                    
                    // Operation succeeded - remove from queue
                    processedIndices.append(index)
                    print("✅ Queued operation completed: \(operation.name)")
                } catch {
                    // Operation failed
                    if operation.retryCount < operation.maxRetries {
                        // Retry later
                        operation.retryCount += 1
                        print("⚠️ Queued operation failed (retry \(operation.retryCount)/\(operation.maxRetries)): \(operation.name)")
                    } else {
                        // Max retries reached - remove from queue
                        processedIndices.append(index)
                        print("❌ Queued operation failed after \(operation.maxRetries) retries: \(operation.name)")
                        
                        // Notify about failure
                        await MainActor.run {
                            NotificationCenter.default.post(
                                name: .offlineOperationFailed,
                                object: nil,
                                userInfo: ["operation": operation.name, "error": error]
                            )
                        }
                    }
                }
            }
            
            // Remove processed operations (in reverse order to maintain indices)
            await MainActor.run {
                for index in processedIndices.reversed() {
                    queuedOperations.remove(at: index)
                }
                
                isProcessing = false
                
                if !queuedOperations.isEmpty {
                    // More operations to process - schedule next batch
                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                        await MainActor.run {
                            processQueue()
                        }
                    }
                }
            }
        }
    }
    
    /// Clear all queued operations
    func clearQueue() {
        queuedOperations.removeAll()
        isProcessing = false
    }
    
    /// Get queue status
    var queueStatus: QueueStatus {
        QueueStatus(
            totalOperations: queuedOperations.count,
            pendingOperations: queuedOperations.filter { $0.retryCount < $0.maxRetries }.count,
            failedOperations: queuedOperations.filter { $0.retryCount >= $0.maxRetries }.count,
            isOnline: isOnline,
            isProcessing: isProcessing
        )
    }
}

/// Queued operation
class QueuedOperation {
    let id: UUID
    let name: String
    let priority: Int
    let maxRetries: Int
    let operation: () async throws -> Void
    var retryCount: Int = 0
    let createdAt: Date
    
    init(
        name: String,
        priority: Int = 0,
        maxRetries: Int = 3,
        operation: @escaping () async throws -> Void
    ) {
        self.id = UUID()
        self.name = name
        self.priority = priority
        self.maxRetries = maxRetries
        self.operation = operation
        self.createdAt = Date()
    }
}

/// Queue status
struct QueueStatus {
    let totalOperations: Int
    let pendingOperations: Int
    let failedOperations: Int
    let isOnline: Bool
    let isProcessing: Bool
}

/// Notification names
extension Notification.Name {
    static let offlineOperationFailed = Notification.Name("offlineOperationFailed")
}
