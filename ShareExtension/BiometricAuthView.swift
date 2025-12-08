//
//  BiometricAuthView.swift
//  Khandoba Secure Docs
//
//  Biometric authentication view for ShareExtension
//

import SwiftUI
import LocalAuthentication

struct BiometricAuthView: View {
    let onSuccess: () -> Void
    let onFailure: (String) -> Void
    
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "faceid")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Authentication Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please authenticate to access your vaults")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                authenticate()
            } label: {
                HStack {
                    if isAuthenticating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "faceid")
                        Text("Authenticate")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isAuthenticating)
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            authenticate()
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        errorMessage = nil
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isAuthenticating = false
            errorMessage = "Biometric authentication is not available on this device"
            onFailure(errorMessage ?? "Authentication not available")
            return
        }
        
        let reason = "Authenticate to access your vaults"
        
        Task {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
                
                await MainActor.run {
                    isAuthenticating = false
                    if success {
                        onSuccess()
                    } else {
                        errorMessage = "Authentication failed"
                        onFailure("Authentication failed")
                    }
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    errorMessage = error.localizedDescription
                    onFailure(error.localizedDescription)
                }
            }
        }
    }
}

