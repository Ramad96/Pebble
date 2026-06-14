//
//  ContentView.swift
//  Pebble
//

import SwiftUI
import AppKit

struct ContentView: View {

    @Bindable var viewModel: CounterViewModel
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let tasbih = viewModel.activeTasbih {
                tasbihView(tasbih)
            } else {
                freeCountView
            }

            Divider()

            // MARK: - Tasbih list
            if viewModel.activeTasbih == nil && !viewModel.tasbihs.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.tasbihs) { tasbih in
                        Button {
                            withAnimation { viewModel.startTasbih(tasbih) }
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(tasbih.name)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(tasbih.steps.count) steps")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.vertical, 4)

                Divider()
            }

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

            // MARK: - Settings & Quit
            VStack(spacing: 0) {
                Button {
                    onOpenSettings()
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Settings…")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
                .contentShape(Rectangle())

                Divider()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit Pebble")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
        }
        .frame(width: 240)
        .onAppear {
            viewModel.checkAccessibility()
        }
    }

    // MARK: - Free count view

    private var freeCountView: some View {
        VStack(spacing: 0) {
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
        }
    }

    // MARK: - Tasbih view

    private func tasbihView(_ tasbih: Tasbih) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                if viewModel.tasbihCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                        .padding(.bottom, 4)

                    Text("Complete")
                        .font(.title3.bold())

                    Text(tasbih.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(viewModel.stepCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    if let name = viewModel.currentStepName,
                       let target = viewModel.currentStepTarget {
                        Text(name)
                            .font(.subheadline.bold())

                        Text("\(viewModel.stepCount) / \(target)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    if let total = viewModel.totalSteps, total > 1 {
                        Text("Step \(viewModel.currentStepIndex + 1) of \(total)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            HStack(spacing: 12) {
                if viewModel.tasbihCompleted {
                    Button {
                        withAnimation { viewModel.restartTasbih() }
                    } label: {
                        Label("Restart", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button {
                        withAnimation { viewModel.increment() }
                    } label: {
                        Label("Increment", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                Button {
                    withAnimation { viewModel.stopTasbih() }
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.vertical, 12)
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
