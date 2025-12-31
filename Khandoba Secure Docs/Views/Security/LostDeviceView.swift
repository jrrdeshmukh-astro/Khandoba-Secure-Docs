//
//  LostDeviceView.swift
//  Khandoba Secure Docs
//
//  View for reporting and managing lost/stolen devices
//

import SwiftUI
import SwiftData

struct LostDeviceView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @EnvironmentObject var deviceService: DeviceManagementService
    @EnvironmentObject var authService: AuthenticationService
    
    let device: Device
    
    @State private var isStolen = false
    @State private var reason: String = ""
    @State private var showingConfirmation = false
    @State private var showingTransferAlert = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            Form {
                // Device Info Section
                Section {
                    HStack {
                        Image(systemName: deviceIcon(for: device.deviceType))
                            .font(.title2)
                            .foregroundColor(colors.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.deviceName)
                                .font(theme.typography.headline)
                                .foregroundColor(colors.primary)
                            
                            Text("\(device.deviceModel) • \(device.systemVersion)")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.secondary)
                            
                            if device.isIrrevocable {
                                Label("Irrevocable Device", systemImage: "lock.fill")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.warning)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Device Information")
                }
                
                // Lost/Stolen Options
                Section {
                    Toggle(isOn: $isStolen) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mark as Stolen")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.primary)
                            
                            Text("More severe - indicates theft")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.secondary)
                        }
                    }
                    .tint(colors.error)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason (Optional)")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.primary)
                        
                        TextField("e.g., Left at coffee shop, Stolen from car", text: $reason, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                } header: {
                    Text("Report Details")
                } footer: {
                    Text("Marking a device as lost will immediately revoke all access. If this was your irrevocable device, you'll need to transfer that status to this device.")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.secondary)
                }
                
                // Warning Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(colors.warning)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What happens when you mark a device as lost:")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.primary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("All access is immediately revoked", systemImage: "checkmark.circle.fill")
                                    Label("Device cannot sign in or access vaults", systemImage: "checkmark.circle.fill")
                                    Label("Security alerts sent to all other devices", systemImage: "checkmark.circle.fill")
                                    if device.isIrrevocable {
                                        Label("Irrevocable status will be revoked", systemImage: "checkmark.circle.fill")
                                    }
                                }
                                .font(theme.typography.caption)
                                .foregroundColor(colors.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Important")
                }
                
                // Action Button
                Section {
                    Button {
                        showingConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: isStolen ? "exclamationmark.shield.fill" : "exclamationmark.triangle.fill")
                                Text(isStolen ? "Mark as Stolen" : "Mark as Lost")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(colors.error)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Report Lost Device")
            .navigationBarTitleDisplayMode(.large)
            .alert("Confirm Device Loss", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button(isStolen ? "Mark as Stolen" : "Mark as Lost", role: .destructive) {
                    Task {
                        await markDeviceAsLost()
                    }
                }
            } message: {
                Text("Are you sure you want to mark '\(device.deviceName)' as \(isStolen ? "stolen" : "lost")? This action cannot be undone and all access will be immediately revoked.")
            }
            .alert("Transfer Irrevocable Status", isPresented: $showingTransferAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Transfer to This Device") {
                    Task {
                        await transferIrrevocableStatus()
                    }
                }
            } message: {
                Text("The lost device was your irrevocable device. Would you like to transfer that status to this device?")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func deviceIcon(for type: String) -> String {
        switch type.lowercased() {
        case "iphone": return "iphone"
        case "ipad": return "ipad"
        case "mac": return "desktopcomputer"
        default: return "device.iphone"
        }
    }
    
    private func markDeviceAsLost() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await deviceService.markDeviceAsLost(device, isStolen: isStolen, reason: reason.isEmpty ? nil : reason)
            
            // If it was irrevocable, offer to transfer status
            if device.isIrrevocable {
                await MainActor.run {
                    showingTransferAlert = true
                }
            } else {
                await MainActor.run {
                    dismiss()
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func transferIrrevocableStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await deviceService.transferIrrevocableStatus(from: device)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Lost Devices List View

struct LostDevicesListView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var deviceService: DeviceManagementService
    
    @State private var lostDevices: [Device] = []
    @State private var isLoading = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        List {
            if lostDevices.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(colors.success)
                    
                    Text("No Lost Devices")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.primary)
                    
                    Text("All your devices are secure")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(lostDevices) { device in
                    LostDeviceRow(device: device)
                }
            }
        }
        .navigationTitle("Lost Devices")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadLostDevices()
        }
        .refreshable {
            await loadLostDevices()
        }
    }
    
    private func loadLostDevices() async {
        isLoading = true
        lostDevices = await deviceService.getLostDevices()
        isLoading = false
    }
}

struct LostDeviceRow: View {
    let device: Device
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var deviceService: DeviceManagementService
    
    @State private var showingRecoverConfirmation = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: deviceIcon(for: device.deviceType))
                    .foregroundColor(colors.error)
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
                
                if device.isStolen {
                    Label("Stolen", systemImage: "exclamationmark.shield.fill")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.error)
                } else {
                    Label("Lost", systemImage: "exclamationmark.triangle.fill")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.warning)
                }
            }
            
            if let reportedAt = device.reportedLostAt {
                Text("Reported: \(formatDate(reportedAt))")
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.secondary)
            }
            
            if let reason = device.lostDeviceReason, !reason.isEmpty {
                Text("Reason: \(reason)")
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.secondary)
            }
            
            if device.lostDeviceAccessAttempts > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(colors.error)
                    Text("\(device.lostDeviceAccessAttempts) access attempt(s) after being marked lost")
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.error)
                }
            }
            
            Button {
                showingRecoverConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Recover Device")
                }
                .font(theme.typography.subheadline)
                .foregroundColor(colors.success)
            }
        }
        .padding(.vertical, 8)
        .alert("Recover Device", isPresented: $showingRecoverConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Recover", role: .destructive) {
                Task {
                    try? await deviceService.recoverDevice(device)
                }
            }
        } message: {
            Text("Are you sure you found '\(device.deviceName)'? This will restore access to the device.")
        }
    }
    
    private func deviceIcon(for type: String) -> String {
        switch type.lowercased() {
        case "iphone": return "iphone"
        case "ipad": return "ipad"
        case "mac": return "desktopcomputer"
        default: return "device.iphone"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

