//
//  DeviceDetailView.swift
//  Khandoba Secure Docs
//
//  Detailed view for a specific device with management options
//

import SwiftUI

struct DeviceDetailView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @EnvironmentObject var deviceService: DeviceManagementService
    
    let device: Device
    
    @State private var showingMarkAsLost = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        List {
            // Device Info
            Section {
                HStack {
                    Image(systemName: deviceIcon(for: device.deviceType))
                        .font(.system(size: 50))
                        .foregroundColor(colors.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.deviceName)
                            .font(theme.typography.title2)
                            .foregroundColor(colors.primary)
                        
                        Text("\(device.deviceModel) • \(device.systemVersion)")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Status
            Section {
                if device.isIrrevocable {
                    Label("Irrevocable Device", systemImage: "lock.fill")
                        .foregroundColor(colors.warning)
                }
                
                if device.isWhitelisted {
                    Label("Whitelisted", systemImage: "checkmark.shield.fill")
                        .foregroundColor(colors.success)
                }
                
                if device.isAuthorized {
                    Label("Authorized", systemImage: "checkmark.circle.fill")
                        .foregroundColor(colors.success)
                }
            } header: {
                Text("Status")
            }
            
            // Access Statistics
            Section {
                HStack {
                    Text("Total Access Attempts")
                    Spacer()
                    Text("\(device.accessAttemptCount)")
                        .foregroundColor(colors.secondary)
                }
                
                HStack {
                    Text("Failed Attempts")
                    Spacer()
                    Text("\(device.failedAttemptCount)")
                        .foregroundColor(device.failedAttemptCount > 0 ? colors.error : colors.secondary)
                }
                
                if let lastAccess = device.lastAccessAt {
                    HStack {
                        Text("Last Access")
                        Spacer()
                        Text(formatDate(lastAccess))
                            .foregroundColor(colors.secondary)
                    }
                }
                
                if let authorizedAt = device.authorizedAt {
                    HStack {
                        Text("Authorized")
                        Spacer()
                        Text(formatDate(authorizedAt))
                            .foregroundColor(colors.secondary)
                    }
                }
            } header: {
                Text("Access Statistics")
            }
            
            // Actions
            Section {
                if device.id != deviceService.currentDevice?.id {
                    Button(role: .destructive) {
                        showingMarkAsLost = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Mark as Lost/Stolen")
                        }
                    }
                } else {
                    Text("This is your current device")
                        .foregroundColor(colors.secondary)
                        .font(theme.typography.caption)
                }
            } header: {
                Text("Actions")
            }
        }
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingMarkAsLost) {
            NavigationStack {
                LostDeviceView(device: device)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

