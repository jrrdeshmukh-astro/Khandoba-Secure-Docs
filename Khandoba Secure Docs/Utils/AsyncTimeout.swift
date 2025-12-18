//
//  AsyncTimeout.swift
//  Khandoba Secure Docs
//
//  Created for production 1.0.1 launch
//

import Foundation
import Combine

/// Utility for adding timeouts to async operations to prevent hangs
enum AsyncTimeout {
    
    /// Execute an async operation with a timeout
    /// - Parameters:
    ///   - timeout: Maximum time to wait in seconds
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    /// - Throws: TimeoutError if operation exceeds timeout, or the operation's error
    static func withTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the operation task
            group.addTask {
                try await operation()
            }
            
            // Add the timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError.operationTimedOut(timeout: timeout)
            }
            
            // Return the first completed result and cancel the other
            guard let result = try await group.next() else {
                throw TimeoutError.operationTimedOut(timeout: timeout)
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Execute an async operation with a timeout and cancellation support
    /// - Parameters:
    ///   - timeout: Maximum time to wait in seconds
    ///   - cancellationToken: Token to check for cancellation
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    /// - Throws: TimeoutError or CancellationError
    static func withTimeout<T>(
        _ timeout: TimeInterval,
        cancellationToken: CancellationToken? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the operation task
            group.addTask {
                // Check for cancellation periodically
                if let token = cancellationToken {
                    try Task.checkCancellation()
                    if token.isCancelledValue {
                        throw CancellationError()
                    }
                }
                return try await operation()
            }
            
            // Add the timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError.operationTimedOut(timeout: timeout)
            }
            
            // Return the first completed result and cancel the other
            guard let result = try await group.next() else {
                throw TimeoutError.operationTimedOut(timeout: timeout)
            }
            
            group.cancelAll()
            return result
        }
    }
}

/// Timeout error
enum TimeoutError: LocalizedError {
    case operationTimedOut(timeout: TimeInterval)
    
    var errorDescription: String? {
        switch self {
        case .operationTimedOut(let timeout):
            return "Operation timed out after \(Int(timeout)) seconds. Please try again."
        }
    }
}

/// Cancellation token for async operations
class CancellationToken: @unchecked Sendable {
    @Published private(set) var isCancelled = false
    
    func cancel() {
        isCancelled = true
    }
    
    func reset() {
        isCancelled = false
    }
    
    // Nonisolated accessor for Swift 6 concurrency
    nonisolated var isCancelledValue: Bool {
        MainActor.assumeIsolated {
            isCancelled
        }
    }
}
