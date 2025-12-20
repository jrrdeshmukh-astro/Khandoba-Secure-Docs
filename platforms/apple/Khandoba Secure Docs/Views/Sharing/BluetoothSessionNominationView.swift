//
//  BluetoothSessionNominationView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//
//  View for Bluetooth-based session nomination
//  Allows users to share vault sessions with nearby devices

import SwiftUI
import CoreBluetooth

struct BluetoothSessionNominationView: View {
    let vault: Vault
    @ObservedObject var bluetoothService: BluetoothSessionNominationService
    let selectedDocumentIDs: [UUID]?
    let sessionDuration: TimeInterval
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var isAdvertising = false
    @State private var showInvitationSent = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 50))
                                .foregroundColor(colors.primary)
                            
                            Text("Bluetooth Session Nomination")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Share vault session with nearby devices")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)
                        
                        // Vault Info
                        StandardCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(colors.primary)
                                    Text("Vault")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                Text(vault.name)
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Mode Selection
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            // Advertise Mode (Share your session)
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    HStack {
                                        Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                                            .foregroundColor(colors.primary)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Share Your Session")
                                                .font(theme.typography.headline)
                                                .foregroundColor(colors.textPrimary)
                                            
                                            Text("Make your vault session discoverable to nearby devices")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                    
                                    if bluetoothService.isAdvertising {
                                        HStack {
                                            ProgressView()
                                                .tint(colors.primary)
                                            Text("Advertising...")
                                                .font(theme.typography.body)
                                                .foregroundColor(colors.textPrimary)
                                        }
                                        
                                        Button {
                                            bluetoothService.stopAdvertising()
                                        } label: {
                                            Text("Stop Advertising")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(colors.error)
                                                .foregroundColor(.white)
                                                .cornerRadius(UnifiedTheme.CornerRadius.md)
                                        }
                                    } else {
                                        Button {
                                            startAdvertising()
                                        } label: {
                                            Text("Start Advertising")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(colors.primary)
                                                .foregroundColor(.white)
                                                .cornerRadius(UnifiedTheme.CornerRadius.md)
                                        }
                                    }
                                }
                            }
                            
                            // Scan Mode (Find nearby sessions)
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    HStack {
                                        Image(systemName: "magnifyingglass.circle.fill")
                                            .foregroundColor(colors.secondary)
                                            .font(.title2)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Find Nearby Sessions")
                                                .font(theme.typography.headline)
                                                .foregroundColor(colors.textPrimary)
                                            
                                            Text("Scan for vault sessions shared by nearby devices")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                    
                                    if bluetoothService.isScanning {
                                        HStack {
                                            ProgressView()
                                                .tint(colors.secondary)
                                            Text("Scanning...")
                                                .font(theme.typography.body)
                                                .foregroundColor(colors.textPrimary)
                                        }
                                        
                                        Button {
                                            bluetoothService.stopScanning()
                                        } label: {
                                            Text("Stop Scanning")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(colors.error)
                                                .foregroundColor(.white)
                                                .cornerRadius(UnifiedTheme.CornerRadius.md)
                                        }
                                    } else {
                                        Button {
                                            bluetoothService.startScanning()
                                        } label: {
                                            Text("Start Scanning")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(colors.secondary)
                                                .foregroundColor(.white)
                                                .cornerRadius(UnifiedTheme.CornerRadius.md)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Nearby Devices List
                        if !bluetoothService.nearbyDevices.isEmpty {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                Text("Nearby Devices")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                    .padding(.horizontal)
                                
                                ForEach(bluetoothService.nearbyDevices) { device in
                                    StandardCard {
                                        HStack {
                                            Image(systemName: "iphone")
                                                .foregroundColor(colors.primary)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(device.name)
                                                    .font(theme.typography.subheadline)
                                                    .foregroundColor(colors.textPrimary)
                                                
                                                Text("Signal: \(device.signalStrength)")
                                                    .font(theme.typography.caption)
                                                    .foregroundColor(colors.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Button {
                                                connectToDevice(device)
                                            } label: {
                                                Text("Connect")
                                                    .font(theme.typography.caption)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(colors.primary)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(UnifiedTheme.CornerRadius.sm)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Connected Device
                        if let connectedDevice = bluetoothService.connectedDevice {
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(colors.success)
                                        
                                        Text("Connected to \(connectedDevice.name)")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(colors.textPrimary)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Button {
                                        sendInvitation()
                                    } label: {
                                        Text("Send Session Invitation")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(colors.success)
                                            .foregroundColor(.white)
                                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                                    }
                                    
                                    Button {
                                        bluetoothService.disconnect()
                                    } label: {
                                        Text("Disconnect")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(colors.surface)
                                            .foregroundColor(colors.textPrimary)
                                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Error Message
                        if let errorMessage = bluetoothService.errorMessage {
                            StandardCard {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(colors.error)
                                    
                                    Text(errorMessage)
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textPrimary)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Bluetooth Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        bluetoothService.stopAdvertising()
                        bluetoothService.stopScanning()
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .alert("Invitation Sent", isPresented: $showInvitationSent) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Session invitation has been sent to the connected device.")
            }
            .onDisappear {
                bluetoothService.stopAdvertising()
                bluetoothService.stopScanning()
            }
        }
    }
    
    // MARK: - Actions
    
    private func startAdvertising() {
        guard let userID = authService.currentUser?.id else {
            bluetoothService.errorMessage = "You must be logged in to share sessions"
            return
        }
        
        // Create session data
        let sessionData = try? JSONEncoder().encode([
            "vaultID": vault.id.uuidString,
            "userID": userID.uuidString,
            "vaultName": vault.name
        ])
        
        bluetoothService.startAdvertising(
            vaultID: vault.id,
            userID: userID,
            sessionData: sessionData ?? Data()
        )
    }
    
    private func connectToDevice(_ device: BluetoothDevice) {
        bluetoothService.connect(to: device)
    }
    
    private func sendInvitation() {
        Task {
            do {
                try await bluetoothService.sendSessionInvitation(
                    vaultID: vault.id,
                    selectedDocumentIDs: selectedDocumentIDs,
                    sessionDuration: sessionDuration
                )
                
                await MainActor.run {
                    showInvitationSent = true
                }
            } catch {
                await MainActor.run {
                    bluetoothService.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
