// JournalViewModel.swift
// VOXMOD — Long-form Tone Reflection

import SwiftUI
import Combine

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var riskScore: Double = 0
    @Published var dominantTone: Tone = .neutral
    @Published var insightExplanation: String? = nil
    @Published var isAnalysing: Bool = false
    
    @Published var savedEntry: StorageService.JournalEntry?
    @Published var isSaving: Bool = false

    // Waveform amplitudes for visual feedback
    @Published var waveformAmplitudes: [CGFloat] = Array(repeating: 0.1, count: 8)

    private let analysisService = ToneAnalysisService.shared
    private var analysisTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load today's persistent entry if it exists
        if let todayEntry = StorageService.shared.getJournalEntry(for: Date()) {
            self.savedEntry = todayEntry
            self.text = todayEntry.text
            self.dominantTone = todayEntry.tone
            self.riskScore = todayEntry.riskScore
            self.insightExplanation = todayEntry.insight
        }

        // Debounce text input for live tone analysis
        $text
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.analyseText(text)
            }
            .store(in: &cancellables)

        // Animate waveform while typing
        $text
            .sink { [weak self] text in
                self?.updateWaveform(isTyping: !text.isEmpty)
            }
            .store(in: &cancellables)
    }

    private func analyseText(_ text: String) {
        analysisTask?.cancel()

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation(.easeOut(duration: 0.5)) {
                riskScore = 0
                dominantTone = .neutral
                insightExplanation = nil
            }
            return
        }

        isAnalysing = true

        analysisTask = Task {
            let result = await analysisService.analyse(text)

            guard !Task.isCancelled else { return }

            // Journal tone priority: Aggressive > Hostile > Assertive > Neutral > Calm
            // Calm is the LAST possible state — only shown when truly safe.
            let journalTone = applyJournalPriority(result.dominantTone, for: text)
            let journalRisk = max(result.riskScore, journalTone.minimumRisk)

            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                self.riskScore          = journalRisk
                self.dominantTone       = journalTone
                self.insightExplanation = result.insightExplanation
                self.isAnalysing        = false
            }
        }
    }
    
    // MARK: - Saving
    
    func saveDailyEntry() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isSaving = true
        HapticService.shared.tap()
        
        Task {
            // 1. Generate the personalized growth insight for tomorrow via AI
            let aiInsight = await NVIDIAService.shared.generateDailyInsight(text: trimmed)
            
            // 2. Create and persist the entry
            let entryToSave = StorageService.JournalEntry(
                id: savedEntry?.id ?? UUID(),
                date: savedEntry?.date ?? Date(),
                text: trimmed,
                insight: aiInsight,
                toneRawValue: dominantTone.rawValue,
                riskScore: riskScore
            )
            
            StorageService.shared.saveJournalEntry(entryToSave)
            
            // 3. Update UI state
            await MainActor.run {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.savedEntry = entryToSave
                    self.insightExplanation = aiInsight
                    self.isSaving = false
                }
                HapticService.shared.success()
            }
        }
    }

    // MARK: - Journal Tone Priority

    /// Enforces journal-specific tone ordering.
    /// When insults or negative keywords are present, Calm is forbidden and
    /// the tone is escalated to at least Assertive.
    private func applyJournalPriority(_ tone: Tone, for text: String) -> Tone {
        let toxicity   = ToxicityLayer.shared.toxicityScore(for: text)
        let hasProfane = ToxicityLayer.shared.hasProfanity(text)
        let hasSlang   = ToxicityLayer.shared.hasSlang(text)
        let accusatory = ToxicityLayer.shared.isAccusatory(text)

        // Heavy toxicity/profanity → always Aggressive or Hostile in journal
        if hasProfane || toxicity >= 60 {
            return toxicity >= 80 ? .hostile : .aggressive
        }

        // Slang or accusatory → Assertive minimum
        if hasSlang || accusatory || toxicity >= 25 {
            return (tone == .calm || tone == .neutral) ? .assertive : tone
        }

        // Calm only allowed when truly nothing negative detected
        if tone == .calm {
            let sentiment = ToxicityLayer.shared.sentimentPolarity(for: text)
            let urgency   = ToxicityLayer.shared.urgencyScore(for: text)
            if !ToxicityLayer.shared.calmIsAllowed(toxicity: toxicity,
                                                    sentiment: sentiment,
                                                    urgency: urgency,
                                                    text: text) {
                return .neutral
            }
        }

        return tone
    }

    // MARK: - Waveform

    private func updateWaveform(isTyping: Bool) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isTyping {
                waveformAmplitudes = (0..<8).map { _ in CGFloat.random(in: 0.2...0.9) }
            } else {
                waveformAmplitudes = Array(repeating: 0.1, count: 8)
            }
        }
    }
}
