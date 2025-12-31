//
//  Device.swift
//  Khandoba Secure Docs
//
//  Device management model for tracking authorized devices
//

import Foundation
import SwiftData

@Model
final class Device {
    var id: UUID = UUID()
    var deviceIdentifier: String = "" // Unique device fingerprint
    var deviceName: String = "" // User-friendly name
    var deviceModel: String = "" // e.g., "iPhone 15 Pro"
    var deviceType: String = "" // "iPhone", "iPad", "Mac"
    var systemVersion: String = "" // iOS version
    var isAuthorized: Bool = false
    var isIrrevocable: Bool = false // One authorized irrevocable device per person
    var isWhitelisted: Bool = false
    var isLost: Bool = false // Device marked as lost/stolen
    var isStolen: Bool = false // Device marked as stolen (more severe)
    var reportedLostAt: Date? // When device was reported lost
    var lostDeviceReason: String? // Reason for marking as lost
    var authorizedAt: Date?
    var lastAccessAt: Date?
    var accessAttemptCount: Int = 0
    var failedAttemptCount: Int = 0
    var lostDeviceAccessAttempts: Int = 0 // Access attempts after being marked lost
    var createdAt: Date = Date()
    
    // Device fingerprint components
    var fingerprintHash: String = "" // SHA-256 hash of device fingerprint
    var hardwareUUID: String? // Device hardware UUID (if available)
    var advertisingIdentifier: String? // IDFA (if available)
    
    // User relationship
    // Note: Using .nullify to avoid circular cascade - if device is deleted, just remove reference from user
    @Relationship(deleteRule: .nullify, inverse: \User.authorizedDevices)
    var owner: User?
    
    init(
        id: UUID = UUID(),
        deviceIdentifier: String,
        deviceName: String,
        deviceModel: String,
        deviceType: String,
        systemVersion: String,
        fingerprintHash: String,
        owner: User? = nil
    ) {
        self.id = id
        self.deviceIdentifier = deviceIdentifier
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.deviceType = deviceType
        self.systemVersion = systemVersion
        self.fingerprintHash = fingerprintHash
        self.owner = owner
        self.createdAt = Date()
    }
}

