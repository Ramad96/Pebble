//
//  SettingsView.swift
//  Pebble
//

import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case tasbih = "Tasbih"
    case about = "About"

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .tasbih: "list.bullet.rectangle"
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
            case .tasbih:
                TasbihSettingsTab(viewModel: viewModel)
            case .about:
                AboutTab()
            }
        }
        .frame(width: 560, height: 340)
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

// MARK: - Tasbih Tab

private struct TasbihSettingsTab: View {

    @Bindable var viewModel: CounterViewModel
    @State private var selectedTasbihID: Tasbih.ID?

    var body: some View {
        HStack(spacing: 0) {
            // Left: list of tasbihs
            VStack(spacing: 0) {
                List(selection: $selectedTasbihID) {
                    ForEach(viewModel.tasbihs) { tasbih in
                        HStack {
                            Text(tasbih.name.isEmpty ? "Untitled" : tasbih.name)
                                .lineLimit(1)
                            Spacer()
                            Text("\(tasbih.steps.count)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .tag(tasbih.id)
                    }
                    .onDelete { offsets in
                        let wasSelected = offsets.contains(where: {
                            viewModel.tasbihs[$0].id == selectedTasbihID
                        })
                        viewModel.tasbihs.remove(atOffsets: offsets)
                        if wasSelected { selectedTasbihID = viewModel.tasbihs.first?.id }
                    }
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))

                HStack(spacing: 4) {
                    Button(action: addTasbih) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)

                    Button(action: removeSelected) {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedTasbihID == nil)

                    Spacer()
                }
                .padding(6)
            }
            .frame(width: 170)

            Divider()

            // Right: editor
            if let index = selectedIndex {
                TasbihEditor(tasbih: $viewModel.tasbihs[index])
            } else {
                VStack {
                    Spacer()
                    Text("Select or create a tasbih")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectedIndex: Int? {
        guard let id = selectedTasbihID else { return nil }
        return viewModel.tasbihs.firstIndex(where: { $0.id == id })
    }

    private func addTasbih() {
        let newTasbih = Tasbih(
            name: "New Tasbih",
            steps: [DhikrStep(name: "SubhanAllah", target: 33)]
        )
        viewModel.tasbihs.append(newTasbih)
        selectedTasbihID = newTasbih.id
    }

    private func removeSelected() {
        guard let index = selectedIndex else { return }
        viewModel.tasbihs.remove(at: index)
        selectedTasbihID = viewModel.tasbihs.first?.id
    }
}

// MARK: - Tasbih Editor

private struct TasbihEditor: View {

    @Binding var tasbih: Tasbih

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Name field
            TextField("Tasbih Name", text: $tasbih.name)
                .textFieldStyle(.roundedBorder)
                .font(.headline)

            Text("Steps")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Steps list
            List {
                ForEach($tasbih.steps) { $step in
                    HStack(spacing: 8) {
                        TextField("Dhikr", text: $step.name)
                            .textFieldStyle(.roundedBorder)

                        TextField(
                            "Count",
                            value: $step.target,
                            format: .number
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)

                        Button(role: .destructive) {
                            tasbih.steps.removeAll { $0.id == step.id }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onMove { from, to in
                    tasbih.steps.move(fromOffsets: from, toOffset: to)
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))

            HStack {
                Button {
                    tasbih.steps.append(DhikrStep(name: "", target: 33))
                } label: {
                    Label("Add Step", systemImage: "plus")
                }
                .buttonStyle(.borderless)

                Spacer()

                Text("\(tasbih.steps.count) step\(tasbih.steps.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
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
