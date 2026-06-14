//
//  HotkeyRecorder.swift
//  Pebble
//

import SwiftUI
import AppKit

/// A SwiftUI view that listens for a single key press and reports its keycode.
struct HotkeyRecorder: View {

    @Binding var keycode: Int
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(isRecording ? "Press any key…" : CounterViewModel.keyName(for: keycode))
                .frame(minWidth: 80)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(isRecording ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )

            if isRecording {
                Button("Cancel") {
                    isRecording = false
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .font(.caption)
            }
        }
        .background(
            HotkeyRecorderRepresentable(isRecording: $isRecording, keycode: $keycode)
                .frame(width: 0, height: 0)
        )
        .onTapGesture {
            isRecording = true
        }
    }
}

// MARK: - NSView bridge that captures key events

private struct HotkeyRecorderRepresentable: NSViewRepresentable {

    @Binding var isRecording: Bool
    @Binding var keycode: Int

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyDown = { code in
            keycode = Int(code)
            isRecording = false
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.isRecordingEnabled = isRecording
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

final class KeyCaptureView: NSView {

    var onKeyDown: ((UInt16) -> Void)?
    var isRecordingEnabled = false

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecordingEnabled else {
            super.keyDown(with: event)
            return
        }
        onKeyDown?(event.keyCode)
    }
}
