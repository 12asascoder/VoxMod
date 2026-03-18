// SettingsViewModel.swift
// VOXMOD

import SwiftUI

/// Manages user preferences and privacy settings.
@MainActor
final class SettingsViewModel: ObservableObject {

    private static let sharedDefaults = UserDefaults(suiteName: "group.com.spazorlabs.VOXMOD") ?? .standard

    @Published var analysisEnabled: Bool {
        didSet { Self.sharedDefaults.set(analysisEnabled, forKey: "analysisEnabled") }
    }

    @Published var hapticFeedback: Bool {
        didSet { Self.sharedDefaults.set(hapticFeedback, forKey: "hapticFeedback") }
    }

    @Published var notificationsEnabled: Bool {
        didSet { Self.sharedDefaults.set(notificationsEnabled, forKey: "notificationsOn") }
    }

    @Published var sensitivity: Double {
        didSet { Self.sharedDefaults.set(sensitivity, forKey: "analysisSensitivity") }
    }

    @Published var nvidiaAPIKey: String {
        didSet { Self.sharedDefaults.set(nvidiaAPIKey, forKey: "nvidiaAPIKey") }
    }

    init() {
        let defaults      = Self.sharedDefaults
        self.analysisEnabled     = defaults.object(forKey: "analysisEnabled") as? Bool ?? true
        self.hapticFeedback      = defaults.object(forKey: "hapticFeedback") as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: "notificationsOn") as? Bool ?? true
        self.sensitivity          = defaults.double(forKey: "analysisSensitivity") == 0
                                        ? 50
                                        : defaults.double(forKey: "analysisSensitivity")
        self.nvidiaAPIKey          = defaults.string(forKey: "nvidiaAPIKey") ?? ""
    }

    /// Privacy trust badges displayed to the user.
    let privacyBadges: [(icon: String, title: String, subtitle: String)] = [
        ("lock.shield.fill",   "On-Device Processing",  "All analysis runs locally. Zero cloud dependency."),
        ("eye.slash.fill",     "No Data Collection",    "We never read, store, or transmit your messages."),
        ("checkmark.seal.fill","Privacy Certified",     "Designed with Apple Privacy-by-Design principles.")
    ]

    func exportData() {
        let events = StorageService.shared.getAllEvents()
        guard let data = try? JSONEncoder().encode(events) else { return }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("voxmod_export.json")
        try? data.write(to: tempURL)

        HapticService.shared.success()

        // Present iOS Share Sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            // For iPad popover compliance
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            rootVC.present(activityVC, animated: true)
        }
    }

    /// Performs a full cold reset: clears all persisted data, cancels
    /// notifications, and triggers the app to return to the onboarding flow.
    func deleteAllData() {
        StorageService.shared.fullReset()
        HapticService.shared.warning()
    }
}
