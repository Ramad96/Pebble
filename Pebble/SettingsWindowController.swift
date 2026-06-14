//
//  SettingsWindowController.swift
//  Pebble
//

import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {

    private var window: NSWindow?
    private let viewModel: CounterViewModel

    init(viewModel: CounterViewModel) {
        self.viewModel = viewModel
    }

    func showSettings() {
        if let window {
            window.makeKeyAndOrderFront(nil)
        } else {
            let settingsView = SettingsView(viewModel: viewModel)
            let hostingController = NSHostingController(rootView: settingsView)

            let newWindow = NSWindow(contentViewController: hostingController)
            newWindow.title = "Pebble Settings"
            newWindow.styleMask = [.titled, .closable]
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            newWindow.makeKeyAndOrderFront(nil)

            self.window = newWindow
        }

        NSApp.activate()
    }
}
