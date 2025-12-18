//
//  RetryService.swift
//  Khandoba Secure Docs
//
//  Created for production 1.0.1 launch
//

import Foundation
import Combine

/// Service for retrying failed operations with exponential backoff
final class RetryService {
    
    /// Retry configuration
    struct RetryConfig {
        let maxAttempts: Int
        let initialDelay: TimeInterval
        let maxDelay: TimeInterval
        let multiplier: Double
        let retryableErrors: (Error) -> Bool
        
        nonisolated static let `default` = RetryConfig(
            maxAttempts: 3,
            initialDelay: 1.0,
            maxDelay: 30.0,
            multiplier: 2.0,
            retryableErrors: { error in
                // Retry on network errors
                if let urlError = error as? URLError {
                    return urlError.code == .timedOut ||
                           urlError.code == .networkConnectionLost ||
                           urlError.code == .notConnectedToInternet
                }
                // Retry on timeout errors
                if error is TimeoutError {
                    return true
                }
                return false
            }
        )
        
        static let networkOnly = RetryConfig(
            maxAttempts: 3,
            initialDelay: 1.0,
            maxDelay: 30.0,
            multiplier: 2.0,
            retryableErrors: { error in
                error is URLError || error is TimeoutError
            }
        )
    }
    
    /// Retry an async operation with exponential backoff
    /// - Parameters:
    ///   - config: Retry configuration
    ///   - operation: The async operation to retry
    /// - Returns: The result of the operation
    /// - Throws: The last error if all retries fail
    static func retry<T>(
        config: RetryConfig = .default,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = config.initialDelay
        
        for attempt in 1...config.maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if error is retryable
                guard config.retryableErrors(error) else {
                    throw error // Don't retry non-retryable errors
                }
                
                // Don't delay after the last attempt
                guard attempt < config.maxAttempts else {
                    break
                }
                
                // Wait with exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Calculate next delay with exponential backoff
                delay = min(delay * config.multiplier, config.maxDelay)
                
                print("⚠️ Retry attempt \(attempt + 1)/\(config.maxAttempts) after \(String(format: "%.1f", delay))s delay")
            }
        }
        
        // All retries failed
        throw lastError ?? RetryError.allRetriesFailed
    }
    
    /// Retry an async operation with cancellation support
    /// - Parameters:
    ///   - config: Retry configuration
    ///   - cancellationToken: Token to check for cancellation
    ///   - operation: The async operation to retry
    /// - Returns: The result of the operation
    /// - Throws: CancellationError if cancelled, or the last error if all retries fail
    static func retry<T>(
        config: RetryConfig = .default,
        cancellationToken: CancellationToken? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = config.initialDelay
        
        for attempt in 1...config.maxAttempts {
            // Check for cancellation
            if let token = cancellationToken, token.isCancelled {
                throw CancellationError()
            }
            
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if error is retryable
                guard config.retryableErrors(error) else {
                    throw error
                }
                
                // Don't delay after the last attempt
                guard attempt < config.maxAttempts else {
                    break
                }
                
                // Check for cancellation before waiting
                if let token = cancellationToken, token.isCancelled {
                    throw CancellationError()
                }
                
                // Wait with exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Calculate next delay
                delay = min(delay * config.multiplier, config.maxDelay)
                
                print("⚠️ Retry attempt \(attempt + 1)/\(config.maxAttempts) after \(String(format: "%.1f", delay))s delay")
            }
        }
        
        throw lastError ?? RetryError.allRetriesFailed
    }
}

/// Retry error
enum RetryError: LocalizedError {
    case allRetriesFailed
    
    var errorDescription: String? {
        switch self {
        case .allRetriesFailed:
            return "Operation failed after all retry attempts"
        }
    }
}
