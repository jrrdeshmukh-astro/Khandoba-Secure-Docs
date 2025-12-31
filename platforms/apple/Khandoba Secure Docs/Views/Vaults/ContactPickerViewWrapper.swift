//
//  ContactPickerViewWrapper.swift
//  Khandoba Secure Docs
//
//  Wrapper for ContactPickerView to avoid naming conflicts
//

import SwiftUI
import Contacts
import ContactsUI

struct ContactPickerViewWrapper: UIViewControllerRepresentable {
    @Binding var selectedContacts: [CNContact]
    let onSelection: ([CNContact]) -> Void
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedContacts: $selectedContacts, onSelection: onSelection, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        @Binding var selectedContacts: [CNContact]
        let onSelection: ([CNContact]) -> Void
        let dismiss: DismissAction
        
        init(selectedContacts: Binding<[CNContact]>, onSelection: @escaping ([CNContact]) -> Void, dismiss: DismissAction) {
            self._selectedContacts = selectedContacts
            self.onSelection = onSelection
            self.dismiss = dismiss
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            selectedContacts = contacts
            onSelection(contacts)
            dismiss()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            dismiss()
        }
    }
}


