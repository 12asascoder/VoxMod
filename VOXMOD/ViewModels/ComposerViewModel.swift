// ComposerViewModel.swift
// VOXMOD

import SwiftUI
import Combine

/// Drives the Smart Message Composer with real-time tone analysis.
@MainActor
final class ComposerViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var messageText: String = ""
    @Published var riskScore: Double = 0
    @Published var dominantTone: Tone = .calm
    @Published var suggestedRephrase: String? = nil
    @Published var insightExplanation: String? = nil
    @Published var showIntervention: Bool = false
    @Published var isAnalysing: Bool = false
    @Published var showSendSuccess: Bool = false
    @Published var sentMessages: [Message] = []
    
    // Waveform animation amplitudes (0.0 – 1.0)
    @Published var waveformAmplitudes: [CGFloat] = Array(repeating: 0.1, count: 12)
    
    // MARK: - Private
    
    private let analysisService = ToneAnalysisService.shared
    private var analysisTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Debounce text input for tone analysis
        $messageText
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.analyseText(text)
            }
            .store(in: &cancellables)
        
        // Animate waveform when text changes
        $messageText
            .sink { [weak self] text in
                self?.updateWaveform(isTyping: !text.isEmpty)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if riskScore >= 50 && !showIntervention {
            // Trigger intervention
            HapticService.shared.warning()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showIntervention = true
            }
            return
        }
        
        // Log the event explicitly
        if riskScore > 10 {
            StorageService.shared.logEvent(riskScore: riskScore, tone: dominantTone, wasRegulated: false)
        }
        
        // Safe to send
        let message = Message(
            text: messageText,
            toneAnalysis: ToneAnalysis(
                riskScore: riskScore,
                dominantTone: dominantTone,
                suggestedRephrase: nil,
                insightExplanation: insightExplanation,
                sentimentBreakdown: .balanced
            )
        )
        
        sentMessages.append(message)
        HapticService.shared.success()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showSendSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.showSendSuccess = false
            }
        }
        
        resetComposer()
    }
    
    func acceptRephrase() {
        guard let rephrase = suggestedRephrase else { return }
        HapticService.shared.success()
        
        // Log the successful intervention
        StorageService.shared.logEvent(riskScore: riskScore, tone: dominantTone, wasRegulated: true)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            messageText = rephrase
            showIntervention = false
        }
    }
    
    func dismissIntervention() {
        HapticService.shared.tap()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showIntervention = false
        }
    }
    
    func forceSend() {
        showIntervention = false
        
        // Log the ignored intervention
        StorageService.shared.logEvent(riskScore: riskScore, tone: dominantTone, wasRegulated: false)
        
        let message = Message(text: messageText)
        sentMessages.append(message)
        resetComposer()
    }
    
    // MARK: - Private
    
    private func analyseText(_ text: String) {
        analysisTask?.cancel()
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation(.easeOut(duration: 0.3)) {
                riskScore = 0
                dominantTone = .calm
                suggestedRephrase = nil
            }
            return
        }
        
        isAnalysing = true
        
        analysisTask = Task {
            let result = await analysisService.analyse(text)

            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                self.riskScore          = result.riskScore
                self.dominantTone       = result.dominantTone
                self.suggestedRephrase  = result.suggestedRephrase
                self.insightExplanation = result.insightExplanation
                self.isAnalysing        = false
            }

            // Haptic feedback on risk change
            if result.riskScore >= 70 {
                HapticService.shared.alert()
            } else if result.riskScore >= 40 {
                HapticService.shared.pulse()
            }
        }
    }
    
    private func updateWaveform(isTyping: Bool) {
        if isTyping {
            waveformAmplitudes = (0..<12).map { _ in
                CGFloat.random(in: 0.2...0.9)
            }
        } else {
            waveformAmplitudes = Array(repeating: 0.1, count: 12)
        }
    }
    
    private func resetComposer() {
        messageText = ""
        riskScore = 0
        dominantTone = .calm
        suggestedRephrase = nil
        insightExplanation = nil
    }


}
