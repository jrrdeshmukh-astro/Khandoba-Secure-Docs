//
//  ProfessionalKYCView.swift
//  Khandoba Secure Docs
//
//  Professional KYC verification view
//  Replaces admin role with professional identity verification
//

import SwiftUI
import SwiftData
#if os(iOS)
import VisionKit
import PhotosUI
#endif

struct ProfessionalKYCView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @SwiftUI.Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var verificationType: KYCVerificationType = .professional
    @State private var fullName = ""
    @State private var organizationName = ""
    @State private var professionalTitle = ""
    @State private var licenseNumber = ""
    @State private var licenseType: LicenseType = .other
    @State private var documentImages: [Data] = []
    @State private var showDocumentScanner = false
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var verificationStatus: KYCStatus = .pending
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            Form {
                // Verification Type
                Section {
                    Picker("Verification Type", selection: $verificationType) {
                        ForEach(KYCVerificationType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Type")
                } footer: {
                    Text(verificationType.description)
                        .font(theme.typography.caption)
                }
                
                // Personal Information
                Section {
                    TextField("Full Legal Name", text: $fullName)
                        .textContentType(.name)
                    
                    TextField("Organization Name", text: $organizationName)
                        .textContentType(.organizationName)
                    
                    TextField("Professional Title", text: $professionalTitle)
                        .textContentType(.jobTitle)
                } header: {
                    Text("Professional Information")
                }
                
                // License Information
                if verificationType == .licensedProfessional {
                    Section {
                        Picker("License Type", selection: $licenseType) {
                            ForEach(LicenseType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        
                        TextField("License Number", text: $licenseNumber)
                            .textContentType(.none)
                            .autocapitalization(.allCharacters)
                    } header: {
                        Text("Professional License")
                    }
                }
                
                // Document Upload
                Section {
                    if documentImages.isEmpty {
                        Button {
                            showDocumentScanner = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.viewfinder")
                                Text("Scan ID Document")
                            }
                        }
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "photo")
                                Text("Upload from Photos")
                            }
                        }
                    } else {
                        ForEach(Array(documentImages.enumerated()), id: \.offset) { index, imageData in
                            DocumentPreviewCard(imageData: imageData, index: index) {
                                documentImages.remove(at: index)
                            }
                        }
                        
                        Button {
                            showDocumentScanner = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Another Document")
                            }
                        }
                    }
                } header: {
                    Text("Identity Documents")
                } footer: {
                    Text("Upload government-issued ID, professional license, or business registration document")
                        .font(theme.typography.caption)
                }
                
                // Verification Status
                if verificationStatus != .pending {
                    Section {
                        HStack {
                            Image(systemName: statusIcon(for: verificationStatus))
                                .foregroundColor(statusColor(for: verificationStatus, colors: colors))
                            
                            Text(verificationStatus.displayName)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                            
                            if verificationStatus == .verified {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(colors.success)
                            }
                        }
                    } header: {
                        Text("Status")
                    }
                }
                
                // Submit Button
                Section {
                    Button {
                        submitKYCVerification()
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Submit for Verification")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Professional KYC")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showDocumentScanner) {
                DocumentScannerView { scannedImages in
                    documentImages.append(contentsOf: scannedImages)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView { selectedImages in
                    documentImages.append(contentsOf: selectedImages)
                }
            }
            #endif
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .onAppear {
                loadUserData()
            }
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !organizationName.isEmpty &&
        !documentImages.isEmpty &&
        (verificationType != .licensedProfessional || !licenseNumber.isEmpty)
    }
    
    private func loadUserData() {
        if let user = authService.currentUser {
            fullName = user.fullName
        }
    }
    
    private func submitKYCVerification() {
        isLoading = true
        
        Task {
            // In a real implementation, this would:
            // 1. Upload documents securely
            // 2. Submit verification request
            // 3. Wait for verification (could be automated or manual)
            
            // For now, simulate verification process
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                verificationStatus = .underReview
                isLoading = false
                
                // Save KYC status
                UserDefaults.standard.set(true, forKey: "kyc_verification_submitted")
                UserDefaults.standard.set(verificationType.rawValue, forKey: "kyc_verification_type")
            }
        }
    }
    
    private func statusIcon(for status: KYCStatus) -> String {
        switch status {
        case .pending:
            return "clock"
        case .underReview:
            return "hourglass"
        case .verified:
            return "checkmark.shield.fill"
        case .rejected:
            return "xmark.shield.fill"
        }
    }
    
    private func statusColor(for status: KYCStatus, colors: UnifiedTheme.Colors) -> Color {
        switch status {
        case .pending:
            return colors.secondary
        case .underReview:
            return colors.warning
        case .verified:
            return colors.success
        case .rejected:
            return colors.error
        }
    }
}

struct DocumentPreviewCard: View {
    let imageData: Data
    let index: Int
    let onDelete: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            #if os(iOS)
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            #endif
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Document \(index + 1)")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                Text(formatFileSize(imageData.count))
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(colors.error)
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#if os(iOS)
struct DocumentScannerView: UIViewControllerRepresentable {
    let onScanComplete: ([Data]) -> Void
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScanComplete: onScanComplete, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScanComplete: ([Data]) -> Void
        let dismiss: DismissAction
        
        init(onScanComplete: @escaping ([Data]) -> Void, dismiss: DismissAction) {
            self.onScanComplete = onScanComplete
            self.dismiss = dismiss
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [Data] = []
            for pageIndex in 0..<scan.pageCount {
                let page = scan.imageOfPage(at: pageIndex)
                if let imageData = page.jpegData(compressionQuality: 0.8) {
                    images.append(imageData)
                }
            }
            onScanComplete(images)
            dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanner error: \(error.localizedDescription)")
            dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            dismiss()
        }
    }
}
#endif

#if os(iOS)
struct ImagePickerView: UIViewControllerRepresentable {
    let onImagesSelected: ([Data]) -> Void
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagesSelected: onImagesSelected, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImagesSelected: ([Data]) -> Void
        let dismiss: DismissAction
        
        init(onImagesSelected: @escaping ([Data]) -> Void, dismiss: DismissAction) {
            self.onImagesSelected = onImagesSelected
            self.dismiss = dismiss
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var images: [Data] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage,
                       let imageData = image.jpegData(compressionQuality: 0.8) {
                        images.append(imageData)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.onImagesSelected(images)
                self.dismiss()
            }
        }
    }
}
#endif

// MARK: - Models

enum KYCVerificationType: String, Codable, CaseIterable, Identifiable {
    case professional = "professional"
    case licensedProfessional = "licensed_professional"
    case business = "business"
    case organization = "organization"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .professional:
            return "Professional"
        case .licensedProfessional:
            return "Licensed Professional"
        case .business:
            return "Business"
        case .organization:
            return "Organization"
        }
    }
    
    var description: String {
        switch self {
        case .professional:
            return "For individual professionals (lawyers, doctors, consultants)"
        case .licensedProfessional:
            return "For licensed professionals (requires license number)"
        case .business:
            return "For business entities"
        case .organization:
            return "For organizations and institutions"
        }
    }
}

enum LicenseType: String, Codable, CaseIterable, Identifiable {
    case medical = "medical"
    case legal = "legal"
    case financial = "financial"
    case engineering = "engineering"
    case accounting = "accounting"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .medical: return "Medical"
        case .legal: return "Legal"
        case .financial: return "Financial"
        case .engineering: return "Engineering"
        case .accounting: return "Accounting"
        case .other: return "Other"
        }
    }
}

enum KYCStatus: String, Codable {
    case pending = "pending"
    case underReview = "under_review"
    case verified = "verified"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending Submission"
        case .underReview:
            return "Under Review"
        case .verified:
            return "Verified"
        case .rejected:
            return "Rejected"
        }
    }
}

