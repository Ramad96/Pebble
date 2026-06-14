//
//  CounterViewModel.swift
//  Pebble
//

import Foundation
import Observation
import AppKit

@MainActor
@Observable
final class CounterViewModel {

    private enum Keys {
        static let dhikrCount = "dhikrCount"
        static let hotkeyKeycode = "hotkeyKeycode"
        static let iconStyle = "iconStyle"
        static let tasbihs = "tasbihs"
    }

    static let defaultKeycode: Int = 105 // F13

    var count: Int {
        didSet { UserDefaults.standard.set(count, forKey: Keys.dhikrCount) }
    }

    var hotkeyKeycode: Int {
        didSet { UserDefaults.standard.set(hotkeyKeycode, forKey: Keys.hotkeyKeycode) }
    }

    /// Whether the menu bar icon is dark (black) or light (white).
    var useDarkIcon: Bool {
        didSet { UserDefaults.standard.set(useDarkIcon, forKey: Keys.iconStyle) }
    }

    var accessibilityGranted: Bool = false

    /// Briefly set to `true` to trigger a menu-bar flash animation.
    var didIncrement: Bool = false

    // MARK: - Tasbih

    /// All saved tasbih sequences.
    var tasbihs: [Tasbih] = [] {
        didSet { saveTasbihs() }
    }

    /// The currently active tasbih sequence, or nil for free counting.
    var activeTasbih: Tasbih?

    /// Index of the current step within the active tasbih.
    var currentStepIndex: Int = 0

    /// Count within the current step.
    var stepCount: Int = 0

    /// Whether the active tasbih has been completed.
    var tasbihCompleted: Bool = false

    /// Display name for the current step, if a tasbih is active.
    var currentStepName: String? {
        guard let tasbih = activeTasbih,
              currentStepIndex < tasbih.steps.count else { return nil }
        return tasbih.steps[currentStepIndex].name
    }

    /// Target count for the current step.
    var currentStepTarget: Int? {
        guard let tasbih = activeTasbih,
              currentStepIndex < tasbih.steps.count else { return nil }
        return tasbih.steps[currentStepIndex].target
    }

    /// Total number of steps in the active tasbih.
    var totalSteps: Int? {
        activeTasbih?.steps.count
    }

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.hotkeyKeycode) == nil {
            defaults.set(CounterViewModel.defaultKeycode, forKey: Keys.hotkeyKeycode)
        }
        self.count = defaults.integer(forKey: Keys.dhikrCount)
        self.hotkeyKeycode = defaults.integer(forKey: Keys.hotkeyKeycode)
        // Default to dark icon if no preference has been saved
        if defaults.object(forKey: Keys.iconStyle) == nil {
            defaults.set(true, forKey: Keys.iconStyle)
        }
        self.useDarkIcon = defaults.bool(forKey: Keys.iconStyle)
        self.tasbihs = Self.loadTasbihs()
    }

    func increment() {
        if let tasbih = activeTasbih, !tasbihCompleted {
            guard currentStepIndex < tasbih.steps.count else { return }
            stepCount += 1
            let target = tasbih.steps[currentStepIndex].target
            if stepCount >= target {
                // Advance to next step
                if currentStepIndex + 1 < tasbih.steps.count {
                    currentStepIndex += 1
                    stepCount = 0
                } else {
                    // Tasbih complete
                    tasbihCompleted = true
                }
            }
        } else {
            count += 1
        }
        flashMenuBar()
    }

    func reset() {
        if activeTasbih != nil {
            stopTasbih()
        } else {
            count = 0
        }
    }

    // MARK: - Tasbih Actions

    func startTasbih(_ tasbih: Tasbih) {
        activeTasbih = tasbih
        currentStepIndex = 0
        stepCount = 0
        tasbihCompleted = false
    }

    func stopTasbih() {
        activeTasbih = nil
        currentStepIndex = 0
        stepCount = 0
        tasbihCompleted = false
    }

    func restartTasbih() {
        guard let tasbih = activeTasbih else { return }
        startTasbih(tasbih)
    }

    func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        accessibilityGranted = trusted
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        accessibilityGranted = trusted
    }

    // MARK: - Helpers

    private func flashMenuBar() {
        didIncrement = true
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            didIncrement = false
        }
    }

    /// Returns a human-readable name for the current hotkey keycode.
    var hotkeyDisplayName: String {
        Self.keyName(for: hotkeyKeycode)
    }

    static func keyName(for keycode: Int) -> String {
        let knownKeys: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
            36: "Return", 37: "L", 38: "J", 39: "'", 40: "K", 41: ";",
            42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
            48: "Tab", 49: "Space", 50: "`", 51: "Delete", 53: "Escape",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
            103: "F11", 105: "F13", 106: "F16", 107: "F14", 109: "F10",
            111: "F12", 113: "F15", 118: "F4", 119: "F2", 120: "F1",
            121: "PageDown", 122: "Home", 123: "LeftArrow", 124: "RightArrow",
            125: "DownArrow", 126: "UpArrow",
        ]
        return knownKeys[keycode] ?? "Key \(keycode)"
    }

    // MARK: - Tasbih Persistence

    private func saveTasbihs() {
        guard let data = try? JSONEncoder().encode(tasbihs) else { return }
        UserDefaults.standard.set(data, forKey: Keys.tasbihs)
    }

    private static func loadTasbihs() -> [Tasbih] {
        guard let data = UserDefaults.standard.data(forKey: Keys.tasbihs),
              let decoded = try? JSONDecoder().decode([Tasbih].self, from: data) else {
            return []
        }
        return decoded
    }
}
