//
//  BackgroundTaskService.swift
//  Khandoba Secure Docs
//
//  Created for production 1.0.1 launch
//

import Foundation

#if os(iOS)
import UIKit
#endif
import Combine

/// Service for managing background tasks (uploads, sync, etc.)
@MainActor
final class BackgroundTaskService: ObservableObject {
    @Published var activeTasks: [UUID: BackgroundTask] = [:]
    @Published var isProcessing = false
    
    #if os(iOS)
    private var backgroundTaskIdentifiers: [UUID: UIBackgroundTaskIdentifier] = [:]
    #endif
    private var cancellables = Set<AnyCancellable>()
    
    nonisolated init() {}
    
    /// Start a background task
    /// - Parameters:
    ///   - task: The background task to execute
    /// - Returns: Task ID for tracking
    @discardableResult
    func startTask(_ task: BackgroundTask) -> UUID {
        let taskID = UUID()
        
        #if os(iOS)
        // Register with iOS for background execution
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: task.name) { [weak self] in
            // Task expired - clean up
            Task { @MainActor in
                self?.endTask(taskID)
            }
        }
        
        guard backgroundTaskID != UIBackgroundTaskIdentifier.invalid else {
            print("⚠️ Failed to start background task: \(task.name)")
            return taskID
        }
        
        backgroundTaskIdentifiers[taskID] = backgroundTaskID
        #endif
        
        activeTasks[taskID] = task
        
        // Execute the task
        Task {
            do {
                isProcessing = true
                try await task.operation()
                
                // Task completed successfully
                await MainActor.run {
                    endTask(taskID)
                }
            } catch {
                // Task failed
                await MainActor.run {
                    print("⚠️ Background task failed: \(task.name) - \(error.localizedDescription)")
                    endTask(taskID)
                }
            }
        }
        
        return taskID
    }
    
    /// End a background task
    /// - Parameter taskID: The task ID to end
    func endTask(_ taskID: UUID) {
        #if os(iOS)
        if let backgroundTaskID = backgroundTaskIdentifiers[taskID] {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskIdentifiers.removeValue(forKey: taskID)
        }
        #endif
        
        activeTasks.removeValue(forKey: taskID)
        
        if activeTasks.isEmpty {
            isProcessing = false
        }
    }
    
    /// End all background tasks
    func endAllTasks() {
        let taskIDs = Array(activeTasks.keys)
        for taskID in taskIDs {
            endTask(taskID)
        }
    }
    
    /// Handle app entering background
    func handleAppDidEnterBackground() {
        #if os(iOS)
        // Ensure all tasks are registered
        for (taskID, task) in activeTasks {
            if backgroundTaskIdentifiers[taskID] == nil {
                let backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: task.name) { [weak self] in
                    Task { @MainActor in
                        self?.endTask(taskID)
                    }
                }
                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                    backgroundTaskIdentifiers[taskID] = backgroundTaskID
                }
            }
        }
        #endif
    }
    
    /// Handle app entering foreground
    func handleAppWillEnterForeground() {
        // Tasks will continue normally in foreground
        // No special handling needed
    }
}

/// Background task definition
struct BackgroundTask {
    let id: UUID
    let name: String
    let operation: () async throws -> Void
    
    init(name: String, operation: @escaping () async throws -> Void) {
        self.id = UUID()
        self.name = name
        self.operation = operation
    }
}
