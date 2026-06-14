//
//  SettingsView.swift
//  Pebble
//

import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case about = "About"

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {

    @Bindable var viewModel: CounterViewModel
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
            }
            .navigationSplitViewColumnWidth(140)
        } detail: {
            switch selectedTab {
            case .general:
                GeneralSettingsTab(viewModel: viewModel)
            case .about:
                AboutTab()
            }
        }
        .frame(width: 520, height: 260)
    }
}

// MARK: - General Tab

private struct GeneralSettingsTab: View {

    @Bindable var viewModel: CounterViewModel

    var body: some View {
        VStack(spacing: 0) {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 16) {
                // Hotkey row
                GridRow {
                    Text("Global Hotkey")
                        .gridColumnAlignment(.trailing)

                    HStack(spacing: 10) {
                        HotkeyRecorder(keycode: $viewModel.hotkeyKeycode)

                        if !viewModel.accessibilityGranted {
                            Button("Grant Access…") {
                                viewModel.requestAccessibility()
                            }
                            .font(.caption)
                            .buttonStyle(.link)
                        }
                    }
                }

                Divider()
                    .gridCellColumns(2)

                // Icon style row
                GridRow {
                    Text("Menu Bar Icon")
                        .gridColumnAlignment(.trailing)

                    Picker("", selection: $viewModel.useDarkIcon) {
                        Text("Dark").tag(true)
                        Text("Light").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                    .labelsHidden()
                }
            }
            .padding(24)

            if !viewModel.accessibilityGranted {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text("Accessibility access is required for the global hotkey to work.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            viewModel.checkAccessibility()
        }
    }
}

// MARK: - About Tab

private struct AboutTab: View {

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pebble")
                        .font(.title2.bold())
                    Text("Every pebble, a remembrance.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("A lightweight macOS menu bar app for counting your dhikr at your desk. Inspired by the early Muslims who counted their remembrance on pebbles and fingertips, Pebble brings that same quiet practice to your modern workflow — one keystroke at a time.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 20)

            Link(destination: URL(string: "https://amanahdigital.co.uk")!) {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                    Text("amanahdigital.co.uk")
                }
                .font(.callout)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 16)
    }
}
