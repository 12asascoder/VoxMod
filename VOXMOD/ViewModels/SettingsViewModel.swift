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
    
    @Published var hasCompletedOnboarding: Bool {
        didSet { Self.sharedDefaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    
    init() {
        let defaults = Self.sharedDefaults
        self.analysisEnabled = defaults.object(forKey: "analysisEnabled") as? Bool ?? true
        self.hapticFeedback = defaults.object(forKey: "hapticFeedback") as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: "notificationsOn") as? Bool ?? true
        self.sensitivity = defaults.double(forKey: "analysisSensitivity") == 0 ? 50 : defaults.double(forKey: "analysisSensitivity")
        self.hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
    }
    
    /// Privacy trust badges displayed to the user.
    let privacyBadges: [(icon: String, title: String, subtitle: String)] = [
        ("lock.shield.fill", "On-Device Processing", "All analysis runs locally. Zero cloud dependency."),
        ("eye.slash.fill", "No Data Collection", "We never read, store, or transmit your messages."),
        ("checkmark.seal.fill", "Privacy Certified", "Designed with Apple Privacy-by-Design principles.")
    ]
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
    
    func exportData() {
        // In production: generate a JSON export of local analytics
        HapticService.shared.success()
    }
    
    func deleteAllData() {
        // In production: wipe CoreData/SwiftData store
        HapticService.shared.warning()
    }
}
