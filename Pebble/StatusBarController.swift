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
                    _ = self.viewModel.useDarkIcon
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
    }

    func updateButton() {
        guard let button = statusItem.button else { return }
        let icon = NSImage(named: "MenuBarIcon")
        icon?.size = NSSize(width: 18, height: 18)
        icon?.isTemplate = false
        let tintColor: NSColor = viewModel.useDarkIcon ? .black : .white
        button.image = icon?.tinted(with: tintColor)
        button.imagePosition = .imageLeading

        let title = " \(viewModel.count)"
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: tintColor,
                .font: font
            ]
        )
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

// MARK: - NSImage tinting

extension NSImage {
    /// Returns a copy of the image filled with the given color, preserving the alpha channel.
    func tinted(with color: NSColor) -> NSImage {
        let tinted = NSImage(size: size, flipped: false) { rect in
            self.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
        tinted.isTemplate = false
        return tinted
    }
}
