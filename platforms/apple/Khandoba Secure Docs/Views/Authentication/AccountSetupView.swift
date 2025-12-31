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
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Minimalist Header
                    VStack(spacing: UnifiedTheme.Spacing.xs) {
                        Text("Complete Your Profile")
                            .font(theme.typography.largeTitle)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        Text("Just a few details")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding(.top, UnifiedTheme.Spacing.xxl)
                    .padding(.bottom, UnifiedTheme.Spacing.md)
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
                    
                    // Minimalist Profile Picture Section
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        #if os(iOS)
                        Button {
                            showImageSourceOptions = true
                        } label: {
                            if let imageData = profileImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(colors.primary.opacity(0.3), lineWidth: 2)
                                    )
                                    .overlay(
                                        Circle()
                                            .fill(Color.black.opacity(0.3))
                                            .overlay(
                                                Image(systemName: "camera.fill")
                                                    .foregroundColor(.white)
                                                    .font(.title3)
                                            )
                                    )
                            } else {
                                Circle()
                                    .fill(colors.surface)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.title2)
                                                .foregroundColor(colors.primary)
                                            Text("Add Photo")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(colors.primary.opacity(0.3), lineWidth: 2)
                                    )
                            }
                        }
                        #else
                        Circle()
                            .fill(colors.surface)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundColor(colors.textTertiary)
                            )
                        #endif
                    }
                    .padding(.bottom, UnifiedTheme.Spacing.md)
                    
                    // Minimalist Name Input
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        TextField("Your name", text: $fullName)
                            .font(theme.typography.title3)
                            .foregroundColor(colors.textPrimary)
                            .padding(UnifiedTheme.Spacing.lg)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: UnifiedTheme.CornerRadius.md)
                                    .stroke(fullName.isEmpty ? colors.textTertiary.opacity(0.3) : colors.primary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.lg)
                    
                    // Minimalist Continue Button
                    Button {
                        completeSetup()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Continue")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(UnifiedTheme.Spacing.md)
                        .background(fullName.isEmpty ? colors.textTertiary : colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                    .disabled(fullName.isEmpty || isLoading)
                    .padding(.horizontal, UnifiedTheme.Spacing.lg)
                    .padding(.top, UnifiedTheme.Spacing.xl)
                }
            }
        }
        .alert("Setup Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        #if os(iOS) || os(macOS)
        .confirmationDialog("Add Profile Photo", isPresented: $showImageSourceOptions, titleVisibility: .visible) {
            Button("Take Photo") {
                showCamera = true
            }
            
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Text("Choose from Photos")
            }
            
            Button("Cancel", role: .cancel) { }
        }
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
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    profileImageData = data
                }
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

