//
//  CameraView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit

struct CameraView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front // Front camera for selfies
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onCapture(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onCapture(originalImage)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#elseif os(macOS)
import AppKit
import Combine

struct CameraView: View {
    var onCapture: (NSImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coordinator = Coordinator()
    
    var body: some View {
        VStack(spacing: 0) {
            CameraPreviewNSView(coordinator: coordinator)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Capture") {
                    coordinator.capturePhoto { image in
                        onCapture(image)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 640, height: 480)
        .onAppear {
            coordinator.setupCamera()
        }
        .onDisappear {
            coordinator.stopCamera()
        }
    }
}

private struct CameraPreviewNSView: NSViewRepresentable {
    let coordinator: Coordinator
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        coordinator.setupPreview(in: view)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let previewLayer = coordinator.previewLayer {
            previewLayer.frame = nsView.bounds
        }
    }
}

class Coordinator: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    var onCaptureComplete: ((NSImage) -> Void)?
    var captureSession: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isReady = false // Required for ObservableObject conformance
    
    func setupCamera() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else {
                print("⚠️ Camera permission denied")
                return
            }
            
            DispatchQueue.main.async {
                self?.configureCamera()
            }
        }
    }
    
    func setupPreview(in view: NSView) {
        configureCamera()
        
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            view.layer = previewLayer
            view.wantsLayer = true
        }
    }
    
    private func configureCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        // Discover available video devices (including external USB cameras)
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )
        
        // Prefer external camera if available, otherwise use built-in
        let device = discoverySession.devices.first { $0.hasMediaType(.video) } ?? discoverySession.devices.first
        
        guard let videoDevice = device else {
            print("⚠️ No camera device found - using file picker fallback")
            showFilePicker()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.photoOutput = output
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            self.previewLayer = previewLayer
            
            self.captureSession = session
            session.startRunning()
        } catch {
            print("❌ Error setting up camera: \(error.localizedDescription)")
            showFilePicker()
        }
    }
    
    func capturePhoto(completion: @escaping (NSImage) -> Void) {
        onCaptureComplete = completion
        guard let photoOutput = photoOutput else {
            showFilePicker()
            return
        }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = NSImage(data: imageData),
              let completion = onCaptureComplete else {
            print("❌ Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
            showFilePicker()
            return
        }
        
        completion(image)
    }
    
    func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
        photoOutput = nil
        previewLayer = nil
    }
    
    func showFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url,
               let image = NSImage(contentsOf: url),
               let completion = self?.onCaptureComplete {
                completion(image)
            }
        }
    }
}

#else
// tvOS - Camera not available
struct CameraView: View {
    var onCapture: (Never) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Camera not available on Apple TV")
                .font(.headline)
            
            Text("Please use another device to capture photos")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
}
#endif

/// Check camera permission status
func checkCameraPermission(completion: @escaping (Bool) -> Void) {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        completion(true)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    case .denied, .restricted:
        completion(false)
    @unknown default:
        completion(false)
    }
}

