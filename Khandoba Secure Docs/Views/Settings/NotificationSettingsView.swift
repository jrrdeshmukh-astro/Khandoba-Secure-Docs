//
//  NotificationSettingsView.swift
//  Khandoba Secure Docs
//
//  Notification preferences management

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var pushNotificationsEnabled = false
    @State private var dualKeyRequestsEnabled = true
    @State private var vaultAccessAlertsEnabled = true
    @State private var threatAlertsEnabled = true
    @State private var geofencingAlertsEnabled = true
    @State private var chatMessagesEnabled = true
    @State private var transferRequestsEnabled = true
    @State private var emergencyAccessEnabled = true
    
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionAlert = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                List {
                    // Permission Status
                    Section {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            HStack {
                                Image(systemName: notificationPermissionStatus == .authorized ? "checkmark.circle.fill" : "bell.slash.fill")
                                    .foregroundColor(notificationPermissionStatus == .authorized ? colors.success : colors.warning)
                                
                                Text("Notification Permission")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Spacer()
                                
                                Text(permissionStatusText)
                                    .font(theme.typography.caption)
                                    .foregroundColor(notificationPermissionStatus == .authorized ? colors.success : colors.warning)
                            }
                            
                            if notificationPermissionStatus != .authorized {
                                Button("Enable in Settings") {
                                    openAppSettings()
                                }
                                .font(theme.typography.caption)
                                .foregroundColor(colors.primary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(colors.surface)
                    
                    // Security Notifications
                    Section("Security Alerts") {
                        NotificationToggle(
                            icon: "shield.checkered",
                            title: "Threat Alerts",
                            description: "Security threats and anomalies",
                            isEnabled: $threatAlertsEnabled,
                            isDisabled: notificationPermissionStatus != .authorized
                        )
                        
                        NotificationToggle(
                            icon: "map.fill",
                            title: "Geofencing Alerts",
                            description: "Location-based security alerts",
                            isEnabled: $geofencingAlertsEnabled,
                            isDisabled: notificationPermissionStatus != .authorized
                        )
                        
                        NotificationToggle(
                            icon: "lock.shield.fill",
                            title: "Vault Access Alerts",
                            description: "Notify when vault is accessed",
                            isEnabled: $vaultAccessAlertsEnabled,
                            isDisabled: notificationPermissionStatus != .authorized
                        )
                    }
                    .listRowBackground(colors.surface)
                    
                    // Collaboration Notifications
                    Section("Collaboration") {
                        NotificationToggle(
                            icon: "key.fill",
                            title: "Dual-Key Requests",
                            description: "Vault unlock approvals",
                            isEnabled: $dualKeyRequestsEnabled,
                            isDisabled: notificationPermissionStatus != .authorized
                        )
                        
                        NotificationToggle(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Transfer Requests",
                            description: "Vault ownership transfers",
                            isEnabled: $transferRequestsEnabled,
                            isDisabled: notificationPermissionStatus != .authorized
                        )
                        
                        NotificationToggle(
                            icon: "exclamationmark.triangle.fill",
                            title: "Emergency Access",
                            description: "Emergency access requests",
                            isEnabled: $emergencyAccessEnabled,
                            isDisabled: notificationPermissionStatus != .authorized
                        )
                    }
                    .listRowBackground(colors.surface)
                    
                    // Communication Notifications
                    Section("Communication") {
                        NotificationToggle(
                            icon: "message.fill",
                            title: "Chat Messages",
                            description: "New support messages",
                            isEnabled: $chatMessagesEnabled,
                            isDisabled: notificationPermissionStatus != .authorized
                        )
                    }
                    .listRowBackground(colors.surface)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        savePreferences()
                        dismiss()
                    }
                }
            }
            .task {
                await checkNotificationPermission()
                loadPreferences()
            }
        }
    }
    
    private var permissionStatusText: String {
        switch notificationPermissionStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func checkNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        notificationPermissionStatus = settings.authorizationStatus
        
        if settings.authorizationStatus == .notDetermined {
            // Request permission
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if granted {
                    notificationPermissionStatus = .authorized
                }
            } catch {
                print("Permission request failed: \(error)")
            }
        }
    }
    
    private func loadPreferences() {
        // Load from UserDefaults
        dualKeyRequestsEnabled = UserDefaults.standard.bool(forKey: "notif_dualKeyRequests")
        vaultAccessAlertsEnabled = UserDefaults.standard.bool(forKey: "notif_vaultAccess")
        threatAlertsEnabled = UserDefaults.standard.bool(forKey: "notif_threats")
        geofencingAlertsEnabled = UserDefaults.standard.bool(forKey: "notif_geofencing")
        chatMessagesEnabled = UserDefaults.standard.bool(forKey: "notif_chatMessages")
        transferRequestsEnabled = UserDefaults.standard.bool(forKey: "notif_transfers")
        emergencyAccessEnabled = UserDefaults.standard.bool(forKey: "notif_emergency")
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(dualKeyRequestsEnabled, forKey: "notif_dualKeyRequests")
        UserDefaults.standard.set(vaultAccessAlertsEnabled, forKey: "notif_vaultAccess")
        UserDefaults.standard.set(threatAlertsEnabled, forKey: "notif_threats")
        UserDefaults.standard.set(geofencingAlertsEnabled, forKey: "notif_geofencing")
        UserDefaults.standard.set(chatMessagesEnabled, forKey: "notif_chatMessages")
        UserDefaults.standard.set(transferRequestsEnabled, forKey: "notif_transfers")
        UserDefaults.standard.set(emergencyAccessEnabled, forKey: "notif_emergency")
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct NotificationToggle: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let isDisabled: Bool
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Toggle(isOn: $isEnabled) {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                Image(systemName: icon)
                    .foregroundColor(colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(description)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

