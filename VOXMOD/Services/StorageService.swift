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
    private let journalEntriesKey = "com.voxmod.journalEntries"

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
    
    struct JournalEntry: Codable, Identifiable {
        let id: UUID
        let date: Date        // Always stored at the start of the day for easy grouping
        let text: String
        let insight: String?
        let toneRawValue: String
        let riskScore: Double
        
        var tone: Tone {
            Tone(rawValue: toneRawValue) ?? .neutral
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
        defaults.removeObject(forKey: journalEntriesKey)
    }

    // MARK: - Journal API

    /// Save or overwrite a journal entry for its specific day.
    func saveJournalEntry(_ entry: JournalEntry) {
        var allEntries = getAllJournalEntries()
        // If an entry for the same day exists, replace it
        if let index = allEntries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }) {
            allEntries[index] = entry
        } else {
            allEntries.append(entry)
        }
        
        if let data = try? JSONEncoder().encode(allEntries) {
            defaults.set(data, forKey: journalEntriesKey)
        }
    }
    
    /// Get the journal entry for a specific date (ignores time).
    func getJournalEntry(for date: Date) -> JournalEntry? {
        // Fast-path lookup
        let all = getAllJournalEntries()
        return all.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
    }
    
    /// Get all historical journal entries sorted newest to oldest.
    func getAllJournalEntries() -> [JournalEntry] {
        guard let data = defaults.data(forKey: journalEntriesKey),
              let entries = try? JSONDecoder().decode([JournalEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
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
            journalEntriesKey,
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
