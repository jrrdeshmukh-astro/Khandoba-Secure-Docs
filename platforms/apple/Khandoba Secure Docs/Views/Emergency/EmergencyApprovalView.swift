//
//  EmergencyApprovalView.swift
//  Khandoba Secure Docs
//
//  Emergency approval UI with ML suggestions
//

import SwiftUI
import SwiftData

struct EmergencyApprovalView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @StateObject private var approvalService = EmergencyApprovalService()
    @StateObject private var mlThreatService = MLThreatAnalysisService()
    
    @State private var selectedRequest: EmergencyAccessRequest?
    @State private var recommendation: ApprovalRecommendation?
    @State private var isAnalyzing = false
    @State private var showApprovalConfirmation = false
    @State private var showDenialConfirmation = false
    @State private var showPassCodeDisplay = false
    @State private var approvedRequestPassCode: String?
    @State private var approvedRequestExpiresAt: Date?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                if approvalService.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading emergency requests...")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .padding(.top)
                    }
                } else if approvalService.pendingRequests.isEmpty {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(colors.success)
                        
                        Text("No Pending Requests")
                            .font(theme.typography.title)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("All emergency access requests have been processed.")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            ForEach(approvalService.pendingRequests) { request in
                                EmergencyRequestCard(
                                    request: request,
                                    recommendation: recommendation,
                                    isAnalyzing: isAnalyzing && selectedRequest?.id == request.id,
                                    onAnalyze: {
                                        analyzeRequest(request)
                                    },
                                    onApprove: {
                                        selectedRequest = request
                                        showApprovalConfirmation = true
                                    },
                                    onDeny: {
                                        selectedRequest = request
                                        showDenialConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Emergency Approvals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            try? await approvalService.loadPendingRequests()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                // Configure service based on backend mode
                if AppConfig.useSupabase {
                    approvalService.configure(supabaseService: supabaseService)
                } else {
                    approvalService.configure(modelContext: modelContext)
                }
                Task {
                    try? await approvalService.loadPendingRequests()
                }
            }
            .alert("Approve Emergency Access?", isPresented: $showApprovalConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Approve") {
                    if let request = selectedRequest {
                        approveRequest(request)
                    }
                }
            } message: {
                if let request = selectedRequest {
                    Text("This will grant 24-hour access to '\(request.vault?.name ?? "vault")' with an identification pass code. You'll need to share the pass code with the requester.")
                }
            }
            .sheet(isPresented: $showPassCodeDisplay) {
                if let passCode = approvedRequestPassCode, let expiresAt = approvedRequestExpiresAt {
                    EmergencyPassCodeDisplayView(
                        passCode: passCode,
                        expiresAt: expiresAt,
                        vaultName: selectedRequest?.vault?.name ?? "vault"
                    )
                }
            }
            .alert("Deny Emergency Access?", isPresented: $showDenialConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Deny", role: .destructive) {
                    if let request = selectedRequest {
                        denyRequest(request)
                    }
                }
            } message: {
                if let request = selectedRequest {
                    Text("This will deny the emergency access request for '\(request.vault?.name ?? "vault")'. The requester will be notified.")
                }
            }
        }
    }
    
    private func analyzeRequest(_ request: EmergencyAccessRequest) {
        isAnalyzing = true
        selectedRequest = request
        
        Task {
            let rec = await approvalService.analyzeEmergencyRequest(request)
            await MainActor.run {
                recommendation = rec
                isAnalyzing = false
            }
        }
    }
    
    private func approveRequest(_ request: EmergencyAccessRequest) {
        Task {
            do {
                guard let approverID = authService.currentUser?.id else {
                    print("❌ Cannot approve: User not authenticated")
                    return
                }
                
                try await approvalService.approveEmergencyRequest(request, approverID: approverID)
                
                // Show pass code to approver (they need to share it with requester)
                await MainActor.run {
                    approvedRequestPassCode = request.passCode
                    approvedRequestExpiresAt = request.expiresAt
                    showPassCodeDisplay = true
                }
                
                // Reload requests
                try await approvalService.loadPendingRequests()
            } catch {
                print("❌ Failed to approve emergency request: \(error.localizedDescription)")
            }
        }
    }
    
    private func denyRequest(_ request: EmergencyAccessRequest) {
        Task {
            do {
                guard let approverID = authService.currentUser?.id else {
                    print("❌ Cannot deny: User not authenticated")
                    return
                }
                
                try await approvalService.denyEmergencyRequest(request, approverID: approverID)
                
                // Reload requests
                try await approvalService.loadPendingRequests()
            } catch {
                print("❌ Failed to deny emergency request: \(error.localizedDescription)")
            }
        }
    }
}

struct EmergencyRequestCard: View {
    let request: EmergencyAccessRequest
    let recommendation: ApprovalRecommendation?
    let isAnalyzing: Bool
    let onAnalyze: () -> Void
    let onApprove: () -> Void
    let onDeny: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.vault?.name ?? "Unknown Vault")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Requested \(request.requestedAt, style: .relative)")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Urgency badge
                    UrgencyBadge(urgency: request.urgency)
                }
                
                Divider()
                
                // Reason
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reason")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                    
                    Text(request.reason)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textPrimary)
                }
                
                // ML Recommendation (if available)
                if let recommendation = recommendation, request.id == self.request.id {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(colors.primary)
                            Text("ML Recommendation")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text(recommendation.shouldApprove ? "Approve" : "Review Carefully")
                                .font(theme.typography.headline)
                                .foregroundColor(recommendation.shouldApprove ? colors.success : colors.warning)
                            
                            Spacer()
                            
                            Text("\(recommendation.confidencePercentage)% confidence")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        Text(recommendation.reasoning)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        if !recommendation.riskFactors.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Risk Factors:")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                    .fontWeight(.semibold)
                                
                                ForEach(recommendation.riskFactors, id: \.self) { factor in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(colors.warning)
                                        Text(factor)
                                            .font(theme.typography.caption2)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(colors.primary.opacity(0.1))
                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                }
                
                Divider()
                
                // Actions
                HStack(spacing: UnifiedTheme.Spacing.sm) {
                    Button {
                        onAnalyze()
                    } label: {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "brain.head.profile")
                            }
                            Text("Analyze")
                        }
                        .font(theme.typography.body)
                        .foregroundColor(colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.primary.opacity(0.1))
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                    .disabled(isAnalyzing)
                    
                    Button {
                        onDeny()
                    } label: {
                        Text("Deny")
                            .font(theme.typography.body)
                            .foregroundColor(colors.error)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.error.opacity(0.1))
                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                    
                    Button {
                        onApprove()
                    } label: {
                        Text("Approve")
                            .font(theme.typography.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.success)
                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                }
            }
            .padding()
        }
    }
}

struct UrgencyBadge: View {
    let urgency: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let (color, icon) = urgencyInfo
        
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(urgency.capitalized)
                .font(theme.typography.caption2)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color)
        .cornerRadius(8)
    }
    
    private var urgencyInfo: (Color, String) {
        switch urgency.lowercased() {
        case "critical":
            return (.purple, "exclamationmark.octagon.fill")
        case "high":
            return (.red, "exclamationmark.triangle.fill")
        case "medium":
            return (.orange, "exclamationmark.triangle")
        case "low":
            return (.blue, "info.circle")
        default:
            return (.gray, "questionmark.circle")
        }
    }
}
