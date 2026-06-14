//
//  AppDelegate.swift
//  Pebble
//

import AppKit
import SwiftUI

// Global (C-compatible) callback for CGEventTap.
// The `userInfo` pointer carries the AppDelegate via Unmanaged.
// Must be a plain global function — not nested, not private, not actor-isolated.
nonisolated func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }

    let delegate = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()

    // Handle tap being disabled by the system (e.g. timeout)
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = delegate.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    let keycode = event.getIntegerValueField(.keyboardEventKeycode)

    // Read the hotkey from UserDefaults directly to avoid actor isolation issues
    let savedKeycode = UserDefaults.standard.integer(forKey: "hotkeyKeycode")
    let targetKeycode = savedKeycode != 0 ? savedKeycode : 105

    if Int(keycode) == targetKeycode {
        Task { @MainActor in
            delegate.viewModel.increment()
        }
        // Consume the event so it doesn't propagate
        return nil
    }

    return Unmanaged.passUnretained(event)
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let viewModel = CounterViewModel()
    private var statusBarController: StatusBarController?
    nonisolated(unsafe) var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(viewModel: viewModel)
        setupEventTap()
    }

    // MARK: - Event Tap Setup

    func setupEventTap() {
        tearDownEventTap()

        // Check accessibility first
        if !AXIsProcessTrusted() {
            viewModel.requestAccessibility()
            viewModel.accessibilityGranted = false

            // Poll for accessibility permission being granted
            Task {
                while !AXIsProcessTrusted() {
                    try? await Task.sleep(for: .seconds(2))
                }
                viewModel.accessibilityGranted = true
                setupEventTap()
            }
            return
        }

        viewModel.accessibilityGranted = true

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: eventTapCallback,
            userInfo: selfPointer
        )

        guard let tap else {
            viewModel.accessibilityGranted = false
            return
        }

        self.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source

        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func tearDownEventTap() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
    }
}
