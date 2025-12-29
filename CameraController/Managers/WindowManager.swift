//
//  WindowManager.swift
//  CameraController
//
//  Created by Itay Brenner on 25/1/22.
//  Copyright © 2022 Itaysoft. All rights reserved.
//

import Foundation
import AppKit
import SwiftUI

class WindowManager: NSObject {
    static let shared = WindowManager()

    private var popover: NSPopover?
    private var isShowing: Bool = false

    private var mainWindow: NSWindow?

    func toggleShowWindow(from button: NSButton) {
        if isShowing {
            closeWindow()
        } else {
            showWindow(from: button)
        }
    }

    func showWindow(from button: NSButton) {
        NotificationCenter.default.post(name: .windowOpen, object: nil)

        let contentView = ContentView()

        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: contentView)
        popover?.contentSize.width = UserSettings.shared.cameraPreviewSize.getWidth()
        popover?.contentSize.height = 100
        popover?.behavior = .transient
        popover?.delegate = self
        DispatchQueue.main.async { [weak self] in
            self?.popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            self?.popover?.contentViewController?.view.window?.makeKey()
        }

        isShowing = true
    }

    func closeWindow() {
        isShowing = false

        popover?.performClose(nil)
    }

    // MARK: - Main Window (regular app UX)
    func showMainWindow() {
        if mainWindow == nil {
            let hostingController = NSHostingController(rootView: ContentView())
            let window = NSWindow(contentViewController: hostingController)
            window.title = "CameraController"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.isReleasedWhenClosed = false
            window.setFrameAutosaveName("CameraControllerMainWindow")
            window.center()
            window.delegate = self

            // Give it a sensible initial size; the SwiftUI content is largely fixed-size.
            window.setContentSize(NSSize(width: UserSettings.shared.cameraPreviewSize.getWidth(), height: 600))

            mainWindow = window
        }

        NotificationCenter.default.post(name: .windowOpen, object: nil)
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension WindowManager: NSPopoverDelegate {
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }

    func popoverWillClose(_ notification: Notification) {
        NotificationCenter.default.post(name: .windowClose, object: nil)
        isShowing = false
    }

    func popoverDidDetach(_ popover: NSPopover) {
        // Disable dragging, only dragging with the preview is allowed
        popover.contentViewController?.view.window?.isMovableByWindowBackground = false
    }
}

extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let closingWindow = notification.object as? NSWindow, closingWindow == mainWindow {
            NotificationCenter.default.post(name: .windowClose, object: nil)
        }
    }
}
