//
//  ContactPickerView.swift
//  Khandoba Secure Docs
//
//  Contact picker for iMessage sharing

import SwiftUI
import Contacts
import ContactsUI
import MessageUI
import Combine

struct ContactPickerView: UIViewControllerRepresentable {
    let vault: Vault
    let onContactsSelected: ([CNContact]) -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            parent.onContactsSelected(contacts)
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.onDismiss()
        }
    }
}

// Helper to request contacts permission
class ContactsPermissionManager: ObservableObject {
    @Published var hasPermission = false
    @Published var permissionStatus: CNAuthorizationStatus = .notDetermined
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        permissionStatus = CNContactStore.authorizationStatus(for: .contacts)
        hasPermission = (permissionStatus == .authorized)
    }
    
    func requestPermission() async -> Bool {
        let store = CNContactStore()
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                hasPermission = granted
                checkPermission()
            }
            return granted
        } catch {
            print("Contacts permission error: \(error)")
            return false
        }
    }
}

// Message composer for sending via iMessage
struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let message: String
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = context.coordinator
        composer.recipients = recipients
        composer.body = message
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposeView
        
        init(_ parent: MessageComposeView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.onDismiss()
        }
    }
}

