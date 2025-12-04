//
//  LocationService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false
    
    private let locationManager = CLLocationManager()
    private var geofences: [Geofence] = []
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationPermission() async {
        // Request permission if not determined
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // Wait a moment for user response
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        // Start tracking if authorized
        if isAuthorized {
            locationManager.startUpdatingLocation()
            // Give it time to get first location
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
    }
    
    func startTracking() {
        guard isAuthorized else { return }
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() async -> CLLocation? {
        guard isAuthorized else { return nil }
        return currentLocation
    }
    
    // MARK: - Geofencing
    
    func addGeofence(_ geofence: Geofence) {
        geofences.append(geofence)
        
        let region = CLCircularRegion(
            center: geofence.center,
            radius: geofence.radius,
            identifier: geofence.id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    func removeGeofence(_ geofence: Geofence) {
        geofences.removeAll { $0.id == geofence.id }
        
        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == geofence.id.uuidString }) {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    func isInsideGeofence(_ geofence: Geofence, location: CLLocation) -> Bool {
        let distance = location.distance(from: CLLocation(latitude: geofence.center.latitude, longitude: geofence.center.longitude))
        return distance <= geofence.radius
    }
    
    func isInsideAnyGeofence(_ location: CLLocation) -> Bool {
        for geofence in geofences where geofence.isActive {
            if isInsideGeofence(geofence, location: location) {
                return true
            }
        }
        return false
    }
    
    private func checkAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
        isAuthorized = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                currentLocation = location
            }
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            checkAuthorizationStatus()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            print("Entered geofence: \(region.identifier)")
            // Post notification or handle geofence entry
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            print("Exited geofence: \(region.identifier)")
            // Post notification or handle geofence exit
            NotificationCenter.default.post(name: .geofenceExited, object: region.identifier)
        }
    }
}

// MARK: - Geofence Model
struct Geofence: Identifiable, Codable {
    let id: UUID
    let name: String
    let center: CLLocationCoordinate2D
    let radius: CLLocationDistance // in meters
    var isActive: Bool
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.center = center
        self.radius = radius
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, centerLatitude, centerLongitude, radius, isActive, createdAt
    }
    
    // Manual Codable to avoid extending CLLocationCoordinate2D
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        let lat = try c.decode(CLLocationDegrees.self, forKey: .centerLatitude)
        let lon = try c.decode(CLLocationDegrees.self, forKey: .centerLongitude)
        center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        radius = try c.decode(CLLocationDistance.self, forKey: .radius)
        isActive = try c.decode(Bool.self, forKey: .isActive)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(center.latitude, forKey: .centerLatitude)
        try c.encode(center.longitude, forKey: .centerLongitude)
        try c.encode(radius, forKey: .radius)
        try c.encode(isActive, forKey: .isActive)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let geofenceEntered = Notification.Name("geofenceEntered")
    static let geofenceExited = Notification.Name("geofenceExited")
}
