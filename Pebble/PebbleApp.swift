//
//  PebbleApp.swift
//  Pebble
//

import SwiftUI

@main
struct PebbleApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible windows — the app lives entirely in the menu bar.
        // Using Settings as a placeholder scene that is never shown.
        Settings {
            EmptyView()
        }
    }
}
