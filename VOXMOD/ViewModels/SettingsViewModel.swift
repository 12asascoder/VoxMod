// SettingsViewModel.swift
// VOXMOD

import SwiftUI

/// Manages user preferences and privacy settings.
@MainActor
final class SettingsViewModel: ObservableObject {
    
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.spazorlabs.VOXMOD") ?? .standard
    
    @AppStorage("analysisEnabled", store: sharedDefaults)    var analysisEnabled: Bool = true
    @AppStorage("hapticFeedback", store: sharedDefaults)     var hapticFeedback: Bool = true
    @AppStorage("notificationsOn", store: sharedDefaults)    var notificationsEnabled: Bool = true
    @AppStorage("analysisSensitivity", store: sharedDefaults) var sensitivity: Double = 50
    @AppStorage("hasCompletedOnboarding", store: sharedDefaults) var hasCompletedOnboarding: Bool = true
    
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
