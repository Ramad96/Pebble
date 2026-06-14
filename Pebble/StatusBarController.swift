//
//  StatusBarController.swift
//  Pebble
//

import AppKit
import SwiftUI

@MainActor
final class StatusBarController {

    private var statusItem: NSStatusItem
    private let popover: NSPopover
    private var eventMonitor: Any?
    private let viewModel: CounterViewModel
    private var observationTask: Task<Void, Never>?

    init(viewModel: CounterViewModel) {
        self.viewModel = viewModel

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 240, height: 320)
        popover.behavior = .transient
        popover.animates = true

        let contentView = ContentView(viewModel: viewModel)
        popover.contentViewController = NSHostingController(rootView: contentView)

        updateButton()

        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        startObserving()
    }

    private func startObserving() {
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let countBefore = viewModel.count
                withObservationTracking {
                    _ = self.viewModel.count
                    _ = self.viewModel.didIncrement
                } onChange: {
                    // onChange fires on a background thread; bounce to main
                    Task { @MainActor [weak self] in
                        self?.handleChange()
                    }
                }
                // Suspend until the onChange closure triggers
                if countBefore == viewModel.count {
                    try? await Task.sleep(for: .milliseconds(50))
                }
            }
        }
    }

    private func handleChange() {
        updateButton()
        if viewModel.didIncrement {
            flashButton()
        }
    }

    func updateButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "circle.dotted", accessibilityDescription: "Dhikr Counter")
        button.image?.size = NSSize(width: 16, height: 16)
        button.imagePosition = .imageLeading
        button.title = " \(viewModel.count)"
        button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
    }

    private func flashButton() {
        guard let button = statusItem.button else { return }
        let originalColor = button.contentTintColor
        button.contentTintColor = .systemGreen
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            button.contentTintColor = originalColor
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.becomeKey()

        // Close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
