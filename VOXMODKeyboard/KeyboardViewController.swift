// KeyboardViewController.swift
// VOXMODKeyboard

import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private var hostingController: UIHostingController<KeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUI()
    }

    private func setupSwiftUI() {
        // Create the SwiftUI view, passing the text document proxy
        let keyboardView = KeyboardView(
            actionHandler: { [weak self] action in
                self?.handleKeyboardAction(action)
            },
            textDocumentProxy: textDocumentProxy
        )
        
        let hc = UIHostingController(rootView: keyboardView)
        hc.view.backgroundColor = .clear
        hc.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.addChild(hc)
        self.view.addSubview(hc.view)
        hc.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hc.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hc.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        // Define a strict height for the keyboard (Apple standard is ~220-250)
        let heightConstraint = self.view.heightAnchor.constraint(equalToConstant: 280)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        
        self.hostingController = hc
    }

    override func textDidChange(_ textInput: UITextInput?) {
        // Notify SwiftUI view of changes (if binding isn't used directly)
        // Handled automatically via textDocumentProxy reference
    }
    
    // MARK: - Actions
    
    private func handleKeyboardAction(_ action: KeyboardAction) {
        switch action {
        case .character(let char):
            textDocumentProxy.insertText(char)
        case .delete:
            textDocumentProxy.deleteBackward()
        case .space:
            textDocumentProxy.insertText(" ")
        case .return:
            textDocumentProxy.insertText("\n")
        case .replaceText(let newText):
            // Delete current sentence and insert new
            while textDocumentProxy.hasText {
                textDocumentProxy.deleteBackward()
            }
            textDocumentProxy.insertText(newText)
        case .nextKeyboard:
            advanceToNextInputMode()
        }
    }
}

// Actions our SwiftUI view can emit
enum KeyboardAction {
    case character(String)
    case delete
    case space
    case `return`
    case replaceText(String)
    case nextKeyboard
}
