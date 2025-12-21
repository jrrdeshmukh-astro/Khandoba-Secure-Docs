//
//  AccountSetupView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import PhotosUI

#if os(iOS)
import UIKit
#endif

struct AccountSetupView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var fullName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCamera = false
    @State private var showImageSourceOptions = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.xl) {
                    // Header
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        Text("Complete Your Profile")
                            .font(theme.typography.title)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.bold)
                        
                        Text("We need a few details to get started")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding(.top, UnifiedTheme.Spacing.xl)
                    .onAppear {
                        // Pre-populate with name from Apple (if available)
                        if let user = authService.currentUser {
                            let existingName = user.fullName.trimmingCharacters(in: .whitespaces)
                            // Only pre-fill if it's not the default "User"
                            if !existingName.isEmpty && existingName != "User" {
                                fullName = existingName
                            }
                            // Load existing profile picture if available
                            if let existingPhoto = user.profilePictureData {
                                profileImageData = existingPhoto
                            }
                        }
                    }
                    
                    // Profile Picture
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        #if os(iOS)
                        if let imageData = profileImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(colors.primary, lineWidth: 3)
                                )
                        } else {
                            ZStack {
                                Circle()
                                    .fill(colors.surface)
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Circle()
                                            .stroke(colors.primary, lineWidth: 3)
                                    )
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(colors.textTertiary)
                            }
                        }
                        #else
                        // macOS/tvOS: Show placeholder
                        ZStack {
                            Circle()
                                .fill(colors.surface)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(colors.primary, lineWidth: 3)
                                )
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(colors.textTertiary)
                        }
                        #endif
                        
                        // Selfie / Photo options
                        #if os(iOS) || os(macOS)
                        HStack(spacing: UnifiedTheme.Spacing.md) {
                            Button {
                                showCamera = true
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                    Text("Take Selfie")
                                        .font(theme.typography.caption)
                                }
                                .foregroundColor(colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(colors.primary.opacity(0.1))
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                VStack(spacing: 4) {
                                    Image(systemName: "photo.fill")
                                        .font(.title2)
                                    Text("Choose Photo")
                                        .font(theme.typography.caption)
                                }
                                .foregroundColor(colors.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(colors.primary.opacity(0.1))
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            .onChange(of: selectedPhoto) { oldValue, newValue in
                                Task {
                                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                        profileImageData = data
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                        #endif
                    }
                    
                    // Full Name
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                        Text("Full Name")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                        
                        TextField("Enter your full name", text: $fullName)
                            .font(theme.typography.body)
                            .padding(UnifiedTheme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    
                    // Continue Button
                    Button {
                        completeSetup()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(fullName.isEmpty || isLoading)
                    .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    .padding(.top, UnifiedTheme.Spacing.lg)
                    
                    // Skip button (profile pic optional now)
                    if profileImageData == nil {
                        Button {
                            completeSetup()
                        } label: {
                            Text("Skip Profile Picture")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.top, UnifiedTheme.Spacing.sm)
                    }
                }
            }
        }
        .alert("Setup Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        #if os(iOS) || os(macOS)
        .sheet(isPresented: $showCamera) {
            CameraView { image in
                #if os(iOS)
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    profileImageData = imageData
                }
                #elseif os(macOS)
                if let tiffData = image.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
                    profileImageData = jpegData
                }
                #endif
                showCamera = false
            }
        }
        #endif
    }
    
    private func completeSetup() {
        isLoading = true
        Task {
            do {
                try await authService.completeAccountSetup(
                    fullName: fullName,
                    profilePicture: profileImageData
                )
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

