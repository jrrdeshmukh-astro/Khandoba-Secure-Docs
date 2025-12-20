//
//  BluetoothSessionNominationService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//
//  Bluetooth-based proximity session nomination
//  Allows users to share vault sessions with nearby devices via Bluetooth

import Foundation
import CoreBluetooth
import Combine

@MainActor
final class BluetoothSessionNominationService: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var nearbyDevices: [BluetoothDevice] = []
    @Published var isAdvertising = false
    @Published var connectedDevice: BluetoothDevice?
    @Published var errorMessage: String?
    
    // Bluetooth managers
    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    
    // Service and characteristic UUIDs
    private let serviceUUID = CBUUID(string: "A7B3C5D1-E8F2-4A6B-9C1D-2E3F4A5B6C7D")
    private let characteristicUUID = CBUUID(string: "B8C4D6E2-F9A3-5B7C-0D2E-3F4A5B6C7D8E")
    
    // Session data
    private var currentVaultID: UUID?
    private var currentUserID: UUID?
    private var sessionData: Data?
    
    // Connected peripherals
    private var connectedPeripherals: [CBPeripheral] = []
    private var discoveredPeripherals: [CBPeripheral: BluetoothDevice] = [:]
    
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Start advertising vault session for nearby devices
    func startAdvertising(vaultID: UUID, userID: UUID, sessionData: Data) {
        self.currentVaultID = vaultID
        self.currentUserID = userID
        self.sessionData = sessionData
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    /// Stop advertising
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        peripheralManager = nil
        isAdvertising = false
    }
    
    /// Start scanning for nearby devices advertising vault sessions
    func startScanning() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Stop scanning
    func stopScanning() {
        centralManager?.stopScan()
        centralManager = nil
        isScanning = false
        nearbyDevices = []
    }
    
    /// Connect to a nearby device
    func connect(to device: BluetoothDevice) {
        guard let peripheral = device.peripheral else {
            errorMessage = "Device not available"
            return
        }
        
        connectedPeripherals.append(peripheral)
        centralManager?.connect(peripheral, options: nil)
    }
    
    /// Disconnect from current device
    func disconnect() {
        for peripheral in connectedPeripherals {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals.removeAll()
        connectedDevice = nil
    }
    
    /// Send session invitation to connected device
    func sendSessionInvitation(vaultID: UUID, selectedDocumentIDs: [UUID]?, sessionDuration: TimeInterval) async throws {
        guard let connectedDevice = connectedDevice,
              let peripheral = connectedDevice.peripheral else {
            throw BluetoothError.notConnected
        }
        
        // Create invitation payload
        let invitation = BluetoothSessionInvitation(
            vaultID: vaultID,
            inviterUserID: currentUserID ?? UUID(),
            selectedDocumentIDs: selectedDocumentIDs,
            sessionDuration: sessionDuration,
            timestamp: Date()
        )
        
        guard let data = try? JSONEncoder().encode(invitation) else {
            throw BluetoothError.encodingFailed
        }
        
        // Find characteristic and write data
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }),
              let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
            throw BluetoothError.characteristicNotFound
        }
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothSessionNominationService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if !isScanning {
                startScanningForDevices()
            }
        case .poweredOff:
            errorMessage = "Bluetooth is turned off. Please enable Bluetooth in Settings."
            stopScanning()
        case .unauthorized:
            errorMessage = "Bluetooth permission denied. Please enable Bluetooth access in Settings."
            stopScanning()
        case .unsupported:
            errorMessage = "Bluetooth is not supported on this device."
            stopScanning()
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Only connect to devices advertising our service
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
              serviceUUIDs.contains(serviceUUID) else {
            return
        }
        
        // Create device info
        let deviceName = peripheral.name ?? "Unknown Device"
        let device = BluetoothDevice(
            id: peripheral.identifier,
            name: deviceName,
            rssi: RSSI.intValue,
            peripheral: peripheral
        )
        
        discoveredPeripherals[peripheral] = device
        
        // Update nearby devices list
        nearbyDevices = Array(discoveredPeripherals.values)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        
        if let device = discoveredPeripherals[peripheral] {
            connectedDevice = device
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let index = connectedPeripherals.firstIndex(of: peripheral) {
            connectedPeripherals.remove(at: index)
        }
        
        if connectedDevice?.peripheral?.identifier == peripheral.identifier {
            connectedDevice = nil
        }
        
        if let error = error {
            errorMessage = "Disconnected: \(error.localizedDescription)"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        errorMessage = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
    }
    
    private func startScanningForDevices() {
        guard let centralManager = centralManager else { return }
        
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        isScanning = true
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothSessionNominationService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                // Subscribe to notifications
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        // Handle received session invitation
        if let invitation = try? JSONDecoder().decode(BluetoothSessionInvitation.self, from: data) {
            handleReceivedInvitation(invitation)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            errorMessage = "Failed to send invitation: \(error.localizedDescription)"
        }
    }
    
    private func handleReceivedInvitation(_ invitation: BluetoothSessionInvitation) {
        // Notify user of received invitation
        NotificationCenter.default.post(
            name: .bluetoothSessionInvitationReceived,
            object: nil,
            userInfo: ["invitation": invitation]
        )
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BluetoothSessionNominationService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            startAdvertisingService()
        case .poweredOff:
            errorMessage = "Bluetooth is turned off. Please enable Bluetooth in Settings."
            stopAdvertising()
        case .unauthorized:
            errorMessage = "Bluetooth permission denied. Please enable Bluetooth access in Settings."
            stopAdvertising()
        case .unsupported:
            errorMessage = "Bluetooth is not supported on this device."
            stopAdvertising()
        default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            errorMessage = "Failed to add service: \(error.localizedDescription)"
            return
        }
        
        // Start advertising
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "Khandoba Secure Docs"
        ]
        
        peripheralManager?.startAdvertising(advertisementData)
        isAdvertising = true
    }
    
    private func startAdvertisingService() {
        guard let peripheralManager = peripheralManager else { return }
        
        // Create service and characteristic
        let characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        
        peripheralManager.add(service)
    }
}

// MARK: - Models

struct BluetoothDevice: Identifiable {
    let id: UUID
    let name: String
    let rssi: Int
    var peripheral: CBPeripheral?
    
    var signalStrength: String {
        if rssi > -50 {
            return "Excellent"
        } else if rssi > -70 {
            return "Good"
        } else if rssi > -85 {
            return "Fair"
        } else {
            return "Weak"
        }
    }
}

struct BluetoothSessionInvitation: Codable {
    let vaultID: UUID
    let inviterUserID: UUID
    let selectedDocumentIDs: [UUID]?
    let sessionDuration: TimeInterval
    let timestamp: Date
}

enum BluetoothError: LocalizedError {
    case notConnected
    case encodingFailed
    case characteristicNotFound
    case serviceNotFound
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to a device"
        case .encodingFailed:
            return "Failed to encode invitation data"
        case .characteristicNotFound:
            return "Bluetooth characteristic not found"
        case .serviceNotFound:
            return "Bluetooth service not found"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let bluetoothSessionInvitationReceived = Notification.Name("bluetoothSessionInvitationReceived")
}
