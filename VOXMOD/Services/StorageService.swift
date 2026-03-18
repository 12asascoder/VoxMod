// StorageService.swift
// VOXMOD

import Foundation
import UserNotifications

/// Handles cross-target data persistence using App Groups.
/// Saves tone analysis events to build the Behaviour Insight Dashboard.
final class StorageService {

    static let shared = StorageService()

    // Shared App Group container accessible by both Main App and Keyboard Extension
    private let defaults = UserDefaults(suiteName: "group.com.spazorlabs.VOXMOD") ?? .standard
    private let suiteName = "group.com.spazorlabs.VOXMOD"

    private let eventsKey = "com.voxmod.events"

    private init() {}

    // MARK: - Models

    struct ToneEvent: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let riskScore: Double
        let dominantToneRaw: String
        let wasRegulated: Bool // True if user accepted a rephrase or paused

        var dominantTone: Tone {
            Tone(rawValue: dominantToneRaw) ?? .calm
        }
    }

    // MARK: - Public API

    /// Save a generic analysis event to history.
    func logEvent(riskScore: Double, tone: Tone, wasRegulated: Bool) {
        let event = ToneEvent(
            id: UUID(),
            timestamp: Date(),
            riskScore: riskScore,
            dominantToneRaw: tone.rawValue,
            wasRegulated: wasRegulated
        )

        var events = getAllEvents()
        events.append(event)
        save(events)
    }

    /// Fetch all events (sorted oldest to newest).
    func getAllEvents() -> [ToneEvent] {
        guard let data = defaults.data(forKey: eventsKey),
              let events = try? JSONDecoder().decode([ToneEvent].self, from: data) else {
            return []
        }
        return events.sorted { $0.timestamp < $1.timestamp }
    }

    /// Delete only the analytics events.
    func clearAll() {
        defaults.removeObject(forKey: eventsKey)
    }

    /// Full cold reset — wipes ALL persisted app data.
    ///
    /// Clears:
    /// - All UserDefaults keys (tone events, settings, onboarding flag, etc.)
    /// - Pending local notifications
    ///
    /// After calling this, the caller should navigate to the onboarding flow.
    func fullReset() {
        print("[VOXMOD] ⚠️  Full app reset initiated.")

        // 1. Purge entire App Group UserDefaults domain
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        UserDefaults.standard.removePersistentDomain(forName: suiteName)

        // 2. Remove individual keys as a belt-and-suspenders fallback
        let allKeys: [String] = [
            eventsKey,
            "analysisEnabled",
            "hapticFeedback",
            "notificationsOn",
            "analysisSensitivity",
            "hasCompletedOnboarding"
        ]
        for key in allKeys {
            defaults.removeObject(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }

        defaults.synchronize()
        UserDefaults.standard.synchronize()

        // 3. Cancel all pending local notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        print("[VOXMOD] ✅ Full reset complete. All data cleared.")
    }

    // MARK: - Private

    private func save(_ events: [ToneEvent]) {
        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: eventsKey)
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let voxmodFullReset = Notification.Name("VoxmodFullReset")
}
