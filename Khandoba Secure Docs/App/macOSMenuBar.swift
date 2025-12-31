//
//  macOSMenuBar.swift
//  Khandoba Secure Docs
//
//  macOS menu bar and keyboard shortcuts
//

#if os(macOS)
import AppKit
import SwiftUI

/// Configure macOS menu bar
func configureMacOSMenuBar() {
    let appMenu = NSMenu()
    
    // App menu
    appMenu.addItem(withTitle: "About Khandoba", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
    appMenu.addItem(NSMenuItem.separator())
    appMenu.addItem(withTitle: "Preferences...", action: #selector(NSApplication.showPreferencesWindow), keyEquivalent: ",")
    appMenu.addItem(NSMenuItem.separator())
    appMenu.addItem(withTitle: "Hide Khandoba", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
    appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h").keyEquivalentModifierMask = [.command, .option]
    appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
    appMenu.addItem(NSMenuItem.separator())
    appMenu.addItem(withTitle: "Quit Khandoba", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    
    let appMenuTitle = NSMenuItem()
    appMenuTitle.submenu = appMenu
    NSApp.mainMenu?.addItem(appMenuTitle)
    
    // File menu
    let fileMenu = NSMenu()
    fileMenu.addItem(withTitle: "New Vault", action: nil, keyEquivalent: "n")
    fileMenu.addItem(withTitle: "Open...", action: nil, keyEquivalent: "o")
    fileMenu.addItem(NSMenuItem.separator())
    fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
    fileMenu.addItem(withTitle: "Save", action: nil, keyEquivalent: "s")
    fileMenu.addItem(NSMenuItem.separator())
    fileMenu.addItem(withTitle: "Import Document...", action: nil, keyEquivalent: "i")
    
    let fileMenuTitle = NSMenuItem()
    fileMenuTitle.submenu = fileMenu
    NSApp.mainMenu?.addItem(fileMenuTitle)
    
    // Edit menu
    let editMenu = NSMenu()
    editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
    editMenu.addItem(withTitle: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "z").keyEquivalentModifierMask = [.command, .shift]
    editMenu.addItem(NSMenuItem.separator())
    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    
    let editMenuTitle = NSMenuItem()
    editMenuTitle.submenu = editMenu
    NSApp.mainMenu?.addItem(editMenuTitle)
    
    // View menu
    let viewMenu = NSMenu()
    viewMenu.addItem(withTitle: "Show Sidebar", action: nil, keyEquivalent: "s").keyEquivalentModifierMask = [.command, .control]
    viewMenu.addItem(NSMenuItem.separator())
    viewMenu.addItem(withTitle: "Actual Size", action: nil, keyEquivalent: "0")
    viewMenu.addItem(withTitle: "Zoom In", action: nil, keyEquivalent: "+")
    viewMenu.addItem(withTitle: "Zoom Out", action: nil, keyEquivalent: "-")
    
    let viewMenuTitle = NSMenuItem()
    viewMenuTitle.submenu = viewMenu
    NSApp.mainMenu?.addItem(viewMenuTitle)
    
    // Window menu
    let windowMenu = NSMenu()
    windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
    windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
    windowMenu.addItem(NSMenuItem.separator())
    windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
    
    let windowMenuTitle = NSMenuItem()
    windowMenuTitle.submenu = windowMenu
    NSApp.mainMenu?.addItem(windowMenuTitle)
    
    // Help menu
    let helpMenu = NSMenu()
    helpMenu.addItem(withTitle: "Khandoba Help", action: nil, keyEquivalent: "?")
    
    let helpMenuTitle = NSMenuItem()
    helpMenuTitle.submenu = helpMenu
    NSApp.mainMenu?.addItem(helpMenuTitle)
}

extension NSApplication {
    @objc func showPreferencesWindow() {
        // Post notification to show preferences
        NotificationCenter.default.post(name: .showPreferences, object: nil)
    }
}

extension Notification.Name {
    static let showPreferences = Notification.Name("showPreferences")
}
#endif
