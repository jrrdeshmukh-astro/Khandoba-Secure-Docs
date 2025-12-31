//
//  DeviceManagementView.swift
//  Khandoba Secure Docs
//
//  Device management view for viewing and managing authorized devices
//

import SwiftUI
import SwiftData

struct DeviceManagementView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var deviceService: DeviceManagementService
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showingAuthorizationAlert = false
    @State private var authorizationError: String?
    @State private var lostDeviceCount: Int = 0
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        List {
            // Current Device Section
            Section {
                if let currentDevice = deviceService.currentDevice {
                    DeviceRow(device: currentDevice, isCurrent: true)
                } else {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(colors.secondary)
                        Text("Current device not authorized")
                            .foregroundColor(colors.secondary)
                        Spacer()
                        Button("Authorize") {
                            Task {
                                await authorizeCurrentDevice()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } header: {
                Text("Current Device")
            }
            
            // Authorized Devices Section
            Section {
                if deviceService.authorizedDevices.isEmpty {
                    Text("No authorized devices")
                        .foregroundColor(colors.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(deviceService.authorizedDevices) { device in
                        NavigationLink {
                            if device.isLost || device.isStolen {
                                LostDeviceView(device: device)
                            } else {
                                DeviceDetailView(device: device)
                            }
                        } label: {
                            DeviceRow(device: device, isCurrent: device.id == deviceService.currentDevice?.id)
                        }
                    }
                }
            } header: {
                Text("Authorized Devices")
            } footer: {
                Text("One device can be marked as irrevocable. This device cannot be removed or revoked.")
            }
            
            // Lost Devices Section
            Section {
                NavigationLink {
                    LostDevicesListView()
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(colors.warning)
                        Text("Lost/Stolen Devices")
                            .foregroundColor(colors.primary)
                        Spacer()
                        if lostDeviceCount > 0 {
                            Text("\(lostDeviceCount)")
                                .font(theme.typography.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(colors.error)
                                .cornerRadius(8)
                        }
                    }
                }
            } header: {
                Text("Security")
            }
        }
        .navigationTitle("Device Management")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadLostDeviceCount()
        }
        .refreshable {
            await loadLostDeviceCount()
            await deviceService.loadAuthorizedDevices()
        }
        .alert("Authorization Error", isPresented: .constant(authorizationError != nil)) {
            Button("OK") {
                authorizationError = nil
            }
        } message: {
            if let error = authorizationError {
                Text(error)
            }
        }
    }
    
    private func loadLostDeviceCount() async {
        let lostDevices = await deviceService.getLostDevices()
        await MainActor.run {
            lostDeviceCount = lostDevices.count
        }
    }
    
    private func authorizeCurrentDevice() async {
        do {
            // Check if user already has an irrevocable device
            if let userID = authService.currentUser?.id {
                let hasIrrevocable = await deviceService.getIrrevocableDevice(for: userID) != nil
                try await deviceService.authorizeCurrentDevice(isIrrevocable: !hasIrrevocable)
            } else {
                try await deviceService.authorizeCurrentDevice(isIrrevocable: false)
            }
        } catch {
            await MainActor.run {
                authorizationError = error.localizedDescription
            }
        }
    }
}

struct DeviceRow: View {
    let device: Device
    let isCurrent: Bool
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var deviceService: DeviceManagementService
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: deviceIcon(for: device.deviceType))
                    .foregroundColor(colors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.deviceName)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.primary)
                    
                    Text("\(device.deviceModel) • \(device.systemVersion)")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.secondary)
                }
                
                Spacer()
                
                if isCurrent {
                    Label("Current", systemImage: "checkmark.circle.fill")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.success)
                }
            }
            
            // Device Status
            HStack(spacing: 12) {
                if device.isIrrevocable {
                    Label("Irrevocable", systemImage: "lock.fill")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.warning)
                }
                
                if device.isWhitelisted {
                    Label("Whitelisted", systemImage: "checkmark.shield.fill")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.success)
                }
                
                if device.isAuthorized {
                    Label("Authorized", systemImage: "checkmark.circle")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.success)
                }
                
                if device.isLost || device.isStolen {
                    Label(device.isStolen ? "Stolen" : "Lost", systemImage: "exclamationmark.triangle.fill")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.error)
                }
            }
            
            // Access Statistics
            if let stats = deviceService.getDeviceAccessStats(for: device) as? (totalAttempts: Int, failedAttempts: Int, lastAccess: Date?) {
                Text("Last access: \(formatDate(stats.lastAccess))")
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func deviceIcon(for type: String) -> String {
        switch type.lowercased() {
        case "iphone": return "iphone"
        case "ipad": return "ipad"
        case "mac": return "desktopcomputer"
        default: return "device.iphone"
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


