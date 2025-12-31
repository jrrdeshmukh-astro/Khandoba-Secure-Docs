//
//  DeviceManagementService.swift
//  Khandoba Secure Docs
//
//  Device management service for one authorized irrevocable device per person,
//  device whitelisting, and device fingerprinting
//

import Foundation
import SwiftData
import Combine
import CryptoKit

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
final class DeviceManagementService: ObservableObject {
    @Published var currentDevice: Device?
    @Published var authorizedDevices: [Device] = []
    @Published var isDeviceAuthorized = false
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private var currentUserID: UUID?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        self.currentUserID = userID
        Task {
            await loadAuthorizedDevices()
            await checkCurrentDeviceAuthorization()
        }
    }
    
    // MARK: - Device Fingerprinting
    
    /// Generate a unique device fingerprint
    func generateDeviceFingerprint() -> String {
        var components: [String] = []
        
        #if os(iOS)
        let device = UIDevice.current
        components.append(device.model) // e.g., "iPhone"
        components.append(device.name) // Device name
        components.append(device.systemVersion) // iOS version
        
        // Use identifierForVendor (persists per app per vendor)
        if let identifier = device.identifierForVendor?.uuidString {
            components.append(identifier)
        }
        
        // Add hardware info if available
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        } ?? "unknown"
        components.append(machine)
        
        #elseif os(macOS)
        let device = ProcessInfo.processInfo
        components.append("Mac")
        components.append(device.hostName)
        components.append(device.operatingSystemVersionString)
        
        // Get Mac model
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        components.append(String(cString: model))
        #endif
        
        // Combine all components
        let fingerprint = components.joined(separator: "|")
        
        // Create SHA-256 hash
        let data = fingerprint.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Get current device information
    func getCurrentDeviceInfo() -> (identifier: String, name: String, model: String, type: String, version: String) {
        #if os(iOS)
        let device = UIDevice.current
        let identifier = device.identifierForVendor?.uuidString ?? UUID().uuidString
        let name = device.name
        let model = device.model
        let type = "iPhone" // Could be iPad, etc.
        let version = device.systemVersion
        return (identifier, name, model, type, version)
        #elseif os(macOS)
        let hostName = ProcessInfo.processInfo.hostName
        let identifier = hostName // Use hostname as identifier
        let name = hostName
        let model = "Mac"
        let type = "Mac"
        let version = ProcessInfo.processInfo.operatingSystemVersionString
        return (identifier, name, model, type, version)
        #else
        return (UUID().uuidString, "Unknown Device", "Unknown", "Unknown", "Unknown")
        #endif
    }
    
    // MARK: - Device Authorization
    
    /// Authorize current device (one irrevocable device per person)
    func authorizeCurrentDevice(isIrrevocable: Bool = false) async throws {
        guard let modelContext = modelContext, let userID = currentUserID else {
            throw DeviceError.contextNotAvailable
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Get current device info
        let deviceInfo = getCurrentDeviceInfo()
        let fingerprintHash = generateDeviceFingerprint()
        
        // Find user
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userID }
        )
        guard let user = try modelContext.fetch(userDescriptor).first else {
            throw DeviceError.userNotFound
        }
        
        // Check if device already exists
        let deviceIdentifier = deviceInfo.identifier
        let deviceDescriptor = FetchDescriptor<Device>(
            predicate: #Predicate { device in device.deviceIdentifier == deviceIdentifier }
        )
        let existingDevices = try modelContext.fetch(deviceDescriptor)
        
        if let existingDevice = existingDevices.first(where: { $0.owner?.id == userID }) {
            // Device already exists - update it
            existingDevice.isAuthorized = true
            existingDevice.isWhitelisted = true
            existingDevice.lastAccessAt = Date()
            existingDevice.accessAttemptCount += 1
            
            if isIrrevocable {
                // Revoke all other devices' irrevocable status
                if let userDevices = user.authorizedDevices {
                    for device in userDevices where device.id != existingDevice.id {
                        device.isIrrevocable = false
                    }
                }
                existingDevice.isIrrevocable = true
            }
            
            currentDevice = existingDevice
        } else {
            // Check if user already has an irrevocable device
            if isIrrevocable {
                if let userDevices = user.authorizedDevices {
                    let existingIrrevocable = userDevices.first { $0.isIrrevocable }
                    if existingIrrevocable != nil {
                        throw DeviceError.irrevocableDeviceExists
                    }
                }
            }
            
            // Create new device
            let device = Device(
                deviceIdentifier: deviceInfo.identifier,
                deviceName: deviceInfo.name,
                deviceModel: deviceInfo.model,
                deviceType: deviceInfo.type,
                systemVersion: deviceInfo.version,
                fingerprintHash: fingerprintHash,
                owner: user
            )
            device.isAuthorized = true
            device.isWhitelisted = true
            device.authorizedAt = Date()
            device.lastAccessAt = Date()
            device.accessAttemptCount = 1
            device.isIrrevocable = isIrrevocable
            
            if user.authorizedDevices == nil {
                user.authorizedDevices = []
            }
            user.authorizedDevices?.append(device)
            
            modelContext.insert(device)
            currentDevice = device
        }
        
        try modelContext.save()
        await loadAuthorizedDevices()
        
        print("✅ Device authorized: \(deviceInfo.name) (Irrevocable: \(isIrrevocable))")
    }
    
    /// Check if current device is authorized
    func checkCurrentDeviceAuthorization() async {
        guard let modelContext = modelContext, let userID = currentUserID else {
            await MainActor.run {
                isDeviceAuthorized = false
            }
            return
        }
        
        let deviceInfo = getCurrentDeviceInfo()
        let fingerprintHash = generateDeviceFingerprint()
        
        // Find device by identifier
        let deviceIdentifier = deviceInfo.identifier
        let deviceDescriptor = FetchDescriptor<Device>(
            predicate: #Predicate { device in device.deviceIdentifier == deviceIdentifier }
        )
        
        if let devices = try? modelContext.fetch(deviceDescriptor),
           let device = devices.first(where: { $0.owner?.id == userID }) {
            
            // CRITICAL: Check if device is marked as lost/stolen
            if device.isLost || device.isStolen {
                print("🚨 SECURITY ALERT: Lost/stolen device attempting access!")
                device.lostDeviceAccessAttempts += 1
                device.failedAttemptCount += 1
                try? modelContext.save()
                
                // Send security alert via push notification
                // Note: PushNotificationService integration would go here
                print("🚨 Alert: Lost/stolen device access attempt logged")
                
                await MainActor.run {
                    isDeviceAuthorized = false
                }
                return
            }
            
            // Verify fingerprint matches
            if device.fingerprintHash == fingerprintHash && device.isAuthorized {
                // Update last access
                device.lastAccessAt = Date()
                device.accessAttemptCount += 1
                try? modelContext.save()
                
                await MainActor.run {
                    currentDevice = device
                    isDeviceAuthorized = true
                }
                return
            } else {
                // Fingerprint mismatch - potential security issue
                print("⚠️ Device fingerprint mismatch - device may have been modified")
                device.failedAttemptCount += 1
                try? modelContext.save()
            }
        }
        
        await MainActor.run {
            isDeviceAuthorized = false
        }
    }
    
    /// Load all authorized devices for current user
    func loadAuthorizedDevices() async {
        guard let modelContext = modelContext, let userID = currentUserID else { return }
        
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userID }
        )
        
        if let user = try? modelContext.fetch(userDescriptor).first,
           let devices = user.authorizedDevices {
            await MainActor.run {
                authorizedDevices = devices.filter { $0.isAuthorized }
            }
        }
    }
    
    // MARK: - Device Whitelisting
    
    /// Whitelist a device
    func whitelistDevice(_ device: Device) async throws {
        guard let modelContext = modelContext else {
            throw DeviceError.contextNotAvailable
        }
        
        device.isWhitelisted = true
        try modelContext.save()
        
        await loadAuthorizedDevices()
        print("✅ Device whitelisted: \(device.deviceName)")
    }
    
    /// Remove device from whitelist
    func removeFromWhitelist(_ device: Device) async throws {
        guard let modelContext = modelContext else {
            throw DeviceError.contextNotAvailable
        }
        
        // Cannot remove irrevocable device
        if device.isIrrevocable {
            throw DeviceError.cannotRemoveIrrevocableDevice
        }
        
        device.isWhitelisted = false
        device.isAuthorized = false
        try modelContext.save()
        
        await loadAuthorizedDevices()
        print("✅ Device removed from whitelist: \(device.deviceName)")
    }
    
    // MARK: - Device Access Tracking
    
    /// Track device access attempt
    func trackAccessAttempt(success: Bool) async {
        guard let device = currentDevice else { return }
        
        if success {
            device.accessAttemptCount += 1
            device.lastAccessAt = Date()
        } else {
            device.failedAttemptCount += 1
            
            // If too many failed attempts, revoke authorization (unless irrevocable)
            if device.failedAttemptCount >= 5 && !device.isIrrevocable {
                device.isAuthorized = false
                print("⚠️ Device authorization revoked due to multiple failed attempts")
            }
        }
        
        try? modelContext?.save()
    }
    
    /// Get device access statistics
    func getDeviceAccessStats(for device: Device) -> (totalAttempts: Int, failedAttempts: Int, lastAccess: Date?) {
        return (
            totalAttempts: device.accessAttemptCount,
            failedAttempts: device.failedAttemptCount,
            lastAccess: device.lastAccessAt
        )
    }
    
    // MARK: - Device Management
    
    /// Revoke device authorization (cannot revoke irrevocable device)
    func revokeDevice(_ device: Device) async throws {
        guard let modelContext = modelContext else {
            throw DeviceError.contextNotAvailable
        }
        
        if device.isIrrevocable {
            throw DeviceError.cannotRemoveIrrevocableDevice
        }
        
        device.isAuthorized = false
        device.isWhitelisted = false
        try modelContext.save()
        
        await loadAuthorizedDevices()
        print("✅ Device authorization revoked: \(device.deviceName)")
    }
    
    /// Get irrevocable device for user
    func getIrrevocableDevice(for userID: UUID) async -> Device? {
        guard let modelContext = modelContext else { return nil }
        
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userID }
        )
        
        if let user = try? modelContext.fetch(userDescriptor).first,
           let devices = user.authorizedDevices {
            return devices.first { $0.isIrrevocable && $0.isAuthorized }
        }
        
        return nil
    }
    
    /// Get all lost/stolen devices for current user
    func getLostDevices() async -> [Device] {
        guard let modelContext = modelContext, let userID = currentUserID else { return [] }
        
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userID }
        )
        
        if let user = try? modelContext.fetch(userDescriptor).first,
           let devices = user.authorizedDevices {
            return devices.filter { $0.isLost || $0.isStolen }
        }
        
        return []
    }
    
    // MARK: - Lost Device Management
    
    /// Mark a device as lost or stolen
    func markDeviceAsLost(_ device: Device, isStolen: Bool, reason: String?) async throws {
        guard let modelContext = modelContext else {
            throw DeviceError.contextNotAvailable
        }
        
        // Check if this is the current device
        if device.id == currentDevice?.id {
            throw DeviceError.cannotMarkCurrentDeviceAsLost
        }
        
        device.isLost = !isStolen
        device.isStolen = isStolen
        device.reportedLostAt = Date()
        device.lostDeviceReason = reason
        device.isAuthorized = false // Revoke access
        
        try modelContext.save()
        
        await loadAuthorizedDevices()
        print("✅ Device marked as \(isStolen ? "stolen" : "lost"): \(device.deviceName)")
    }
    
    /// Transfer irrevocable status from one device to another
    func transferIrrevocableStatus(from lostDevice: Device) async throws {
        guard let modelContext = modelContext, currentUserID != nil else {
            throw DeviceError.contextNotAvailable
        }
        
        // Find current device (the one to transfer to)
        guard let currentDevice = currentDevice else {
            throw DeviceError.deviceNotFound
        }
        
        // Remove irrevocable status from lost device
        lostDevice.isIrrevocable = false
        
        // Transfer to current device
        currentDevice.isIrrevocable = true
        
        try modelContext.save()
        
        await loadAuthorizedDevices()
        print("✅ Irrevocable status transferred from \(lostDevice.deviceName) to \(currentDevice.deviceName)")
    }
    
    /// Recover a lost/stolen device
    func recoverDevice(_ device: Device) async throws {
        guard let modelContext = modelContext else {
            throw DeviceError.contextNotAvailable
        }
        
        guard device.isLost || device.isStolen else {
            throw DeviceError.deviceNotLost
        }
        
        device.isLost = false
        device.isStolen = false
        device.reportedLostAt = nil
        device.lostDeviceReason = nil
        device.isAuthorized = true // Restore access
        
        try modelContext.save()
        
        await loadAuthorizedDevices()
        print("✅ Device recovered: \(device.deviceName)")
    }
}

// MARK: - Errors

enum DeviceError: LocalizedError {
    case contextNotAvailable
    case userNotFound
    case deviceNotFound
    case irrevocableDeviceExists
    case cannotRemoveIrrevocableDevice
    case deviceNotAuthorized
    case cannotMarkCurrentDeviceAsLost
    case deviceNotLost
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Device management service not configured"
        case .userNotFound:
            return "User not found"
        case .deviceNotFound:
            return "Device not found"
        case .irrevocableDeviceExists:
            return "User already has an irrevocable device. Only one irrevocable device per person is allowed."
        case .cannotRemoveIrrevocableDevice:
            return "Cannot remove or revoke an irrevocable device"
        case .deviceNotAuthorized:
            return "Device is not authorized"
        case .cannotMarkCurrentDeviceAsLost:
            return "Cannot mark the current device as lost. Please use another device to report this device as lost."
        case .deviceNotLost:
            return "Device is not marked as lost"
        }
    }
}

