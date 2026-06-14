//
//  ContentView.swift
//  Pebble
//

import SwiftUI
import AppKit

struct ContentView: View {

    @Bindable var viewModel: CounterViewModel

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Count display
            VStack(spacing: 4) {
                Text("\(viewModel.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("Dhikr Count")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // MARK: - Actions
            HStack(spacing: 12) {
                Button {
                    withAnimation { viewModel.increment() }
                } label: {
                    Label("Increment", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive) {
                    showResetConfirmation()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.vertical, 12)

            Divider()

            // MARK: - Accessibility warning
            if !viewModel.accessibilityGranted {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Accessibility access required for global hotkey.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)

                Button("Grant Access…") {
                    viewModel.requestAccessibility()
                }
                .buttonStyle(.link)
                .font(.caption)
                .padding(.bottom, 8)
            }

            // MARK: - Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Global Hotkey")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HotkeyRecorder(keycode: $viewModel.hotkeyKeycode)

                Text("Menu Bar Icon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Picker("", selection: $viewModel.useDarkIcon) {
                    Label("Dark", systemImage: "circle.lefthalf.filled")
                        .tag(true)
                    Label("Light", systemImage: "circle.righthalf.filled")
                        .tag(false)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // MARK: - Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit Dhikr Counter")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .frame(width: 240)
        .onAppear {
            viewModel.checkAccessibility()
        }
    }

    // MARK: - Reset confirmation via NSAlert

    private func showResetConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Reset Counter"
        alert.informativeText = "Are you sure you want to reset the dhikr count to zero?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            withAnimation { viewModel.reset() }
        }
    }
}
