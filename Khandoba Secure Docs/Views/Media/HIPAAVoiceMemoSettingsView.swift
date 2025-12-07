//
//  HIPAAVoiceMemoSettingsView.swift
//  Khandoba Secure Docs
//
//  HIPAA Settings for Voice Memo Recording
//

import SwiftUI

struct HIPAAVoiceMemoSettingsView: View {
    @Binding var containsPHI: Bool
    @Binding var retentionDays: Int?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var retentionDaysText: String = ""
    @State private var selectedRetentionOption: RetentionOption = .none
    
    enum RetentionOption: String, CaseIterable {
        case none = "No Retention Policy"
        case days30 = "30 Days"
        case days90 = "90 Days"
        case days365 = "1 Year"
        case days2555 = "7 Years"
        case custom = "Custom"
        
        var days: Int? {
            switch self {
            case .none: return nil
            case .days30: return 30
            case .days90: return 90
            case .days365: return 365
            case .days2555: return 2555
            case .custom: return nil
            }
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationView {
            Form {
                Section {
                    Toggle("Contains Protected Health Information (PHI)", isOn: $containsPHI)
                        .font(theme.typography.body)
                    
                    if containsPHI {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(colors.warning)
                            Text("PHI flag enables enhanced audit logging and access controls")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                } header: {
                    Text("Health Information")
                } footer: {
                    Text("Mark if this recording contains patient health information subject to HIPAA regulations")
                }
                
                Section {
                    Picker("Retention Policy", selection: $selectedRetentionOption) {
                        ForEach(RetentionOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .font(theme.typography.body)
                    .onChange(of: selectedRetentionOption) { oldValue, newValue in
                        if newValue == .custom {
                            retentionDaysText = ""
                        } else {
                            retentionDays = newValue.days
                            retentionDaysText = newValue.days?.description ?? ""
                        }
                    }
                    
                    if selectedRetentionOption == .custom {
                        HStack {
                            TextField("Days", text: $retentionDaysText)
                                .keyboardType(.numberPad)
                                .onChange(of: retentionDaysText) { oldValue, newValue in
                                    retentionDays = Int(newValue)
                                }
                            Text("days")
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    
                    if let days = retentionDays {
                        HStack {
                            Image(systemName: "calendar")
                            Text("Recording will be automatically deleted after \(days) days")
                                .font(theme.typography.caption)
                        }
                        .foregroundColor(colors.textSecondary)
                    }
                } header: {
                    Text("Retention Policy")
                } footer: {
                    Text("Set automatic deletion period. HIPAA requires minimum retention periods for medical records (typically 6-7 years)")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(colors.success)
                            Text("AES-256-GCM Encryption")
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(colors.success)
                            Text("SHA-256 Integrity Hashing")
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(colors.success)
                            Text("Comprehensive Audit Logging")
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(colors.success)
                            Text("Secure Cryptographic Deletion")
                        }
                    }
                    .font(theme.typography.caption)
                } header: {
                    Text("Security Features")
                }
            }
            .navigationTitle("HIPAA Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
        }
        .onAppear {
            // Initialize retention option based on current value
            if let days = retentionDays {
                if days == 30 {
                    selectedRetentionOption = .days30
                } else if days == 90 {
                    selectedRetentionOption = .days90
                } else if days == 365 {
                    selectedRetentionOption = .days365
                } else if days == 2555 {
                    selectedRetentionOption = .days2555
                } else {
                    selectedRetentionOption = .custom
                    retentionDaysText = days.description
                }
            }
        }
    }
}

